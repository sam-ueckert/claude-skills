#!/usr/bin/env python3
"""
secret-vault: AES-256-GCM encrypted local credential storage.

Usage:
    vault.py init [--keychain | --env | --kms <provider> --key-id <id> | --passphrase]
    vault.py set <key> <value> [--tags TAG,TAG,...]
    vault.py get <key> [--export]
    vault.py list [--tags TAG,TAG,...]
    vault.py rotate <key> <new_value>
    vault.py delete <key>
    vault.py export [--format {env,github-actions,gitlab-ci}]
    vault.py --help
"""

import argparse
import base64
import hashlib
import json
import os
import platform
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

VAULT_DIR = Path.home() / ".claude" / "vault"
VAULT_FILE = VAULT_DIR / "vault.enc"
META_FILE = VAULT_DIR / ".vault-meta"
AUDIT_LOG = VAULT_DIR / "audit.log"
SERVICE_NAME = "claude-secret-vault"


def ensure_vault_dir():
    VAULT_DIR.mkdir(parents=True, exist_ok=True)


def audit(action: str, key: str = ""):
    ensure_vault_dir()
    ts = datetime.now(timezone.utc).isoformat()
    entry = f"{ts} | {action} | {key}\n"
    with open(AUDIT_LOG, "a") as f:
        f.write(entry)


# ---------------------------------------------------------------------------
# Encryption helpers (AES-256-GCM via cryptography library)
# ---------------------------------------------------------------------------

def _get_cipher():
    try:
        from cryptography.hazmat.primitives.ciphers.aead import AESGCM
        return AESGCM
    except ImportError:
        print("ERROR: 'cryptography' package required. Install with:")
        print("  pip install cryptography")
        sys.exit(1)


def encrypt(plaintext: bytes, key: bytes) -> bytes:
    """Encrypt with AES-256-GCM. Returns nonce (12 bytes) + ciphertext."""
    AESGCM = _get_cipher()
    nonce = os.urandom(12)
    ct = AESGCM(key).encrypt(nonce, plaintext, None)
    return nonce + ct


def decrypt(data: bytes, key: bytes) -> bytes:
    """Decrypt AES-256-GCM. Expects nonce (12 bytes) + ciphertext."""
    AESGCM = _get_cipher()
    nonce, ct = data[:12], data[12:]
    return AESGCM(key).decrypt(nonce, ct, None)


# ---------------------------------------------------------------------------
# Key resolution
# ---------------------------------------------------------------------------

def _read_meta() -> dict:
    if META_FILE.exists():
        return json.loads(META_FILE.read_text())
    return {}


def _write_meta(meta: dict):
    ensure_vault_dir()
    META_FILE.write_text(json.dumps(meta, indent=2))


def _key_from_keychain() -> bytes | None:
    system = platform.system()
    try:
        if system == "Darwin":
            result = subprocess.run(
                ["security", "find-generic-password", "-s", SERVICE_NAME, "-w"],
                capture_output=True, text=True
            )
            if result.returncode == 0:
                return bytes.fromhex(result.stdout.strip())
        elif system == "Linux":
            result = subprocess.run(
                ["secret-tool", "lookup", "service", SERVICE_NAME],
                capture_output=True, text=True
            )
            if result.returncode == 0:
                return bytes.fromhex(result.stdout.strip())
    except FileNotFoundError:
        pass
    return None


def _store_keychain(key_hex: str):
    system = platform.system()
    if system == "Darwin":
        subprocess.run([
            "security", "add-generic-password",
            "-s", SERVICE_NAME, "-a", "claude", "-w", key_hex, "-U"
        ], check=True)
    elif system == "Linux":
        proc = subprocess.Popen(
            ["secret-tool", "store", "--label", SERVICE_NAME, "service", SERVICE_NAME],
            stdin=subprocess.PIPE
        )
        proc.communicate(input=key_hex.encode())
    else:
        print(f"Keychain not supported on {system}. Use --env or --passphrase.")
        sys.exit(1)


def _key_from_env() -> bytes | None:
    val = os.environ.get("CLAUDE_VAULT_KEY")
    if val:
        return bytes.fromhex(val)
    return None


def _key_from_passphrase(passphrase: str | None = None) -> bytes:
    meta = _read_meta()
    salt = bytes.fromhex(meta.get("salt", ""))
    if not salt:
        salt = os.urandom(16)
        meta["salt"] = salt.hex()
        _write_meta(meta)
    if passphrase is None:
        import getpass
        passphrase = getpass.getpass("Vault passphrase: ")
    # Use PBKDF2 as fallback (Argon2 preferred but requires argon2-cffi)
    try:
        from argon2.low_level import hash_secret_raw, Type
        key = hash_secret_raw(
            secret=passphrase.encode(),
            salt=salt,
            time_cost=3, memory_cost=65536, parallelism=4,
            hash_len=32, type=Type.ID
        )
    except ImportError:
        key = hashlib.pbkdf2_hmac("sha256", passphrase.encode(), salt, 600_000)
    return key


def resolve_key() -> bytes:
    """Resolve vault key in priority order."""
    meta = _read_meta()
    tier = meta.get("key_tier", "passphrase")

    if tier == "keychain":
        key = _key_from_keychain()
        if key:
            return key
        print("ERROR: Key not found in OS keychain.")
        sys.exit(1)

    if tier == "env":
        key = _key_from_env()
        if key:
            return key
        print("ERROR: CLAUDE_VAULT_KEY environment variable not set.")
        sys.exit(1)

    if tier == "kms":
        print("ERROR: KMS support requires cloud SDK integration (not yet implemented).")
        sys.exit(1)

    # Default: passphrase
    return _key_from_passphrase()


# ---------------------------------------------------------------------------
# Vault I/O
# ---------------------------------------------------------------------------

def load_vault(key: bytes) -> dict:
    if not VAULT_FILE.exists():
        return {"version": 1, "secrets": {}}
    raw = VAULT_FILE.read_bytes()
    plaintext = decrypt(raw, key)
    return json.loads(plaintext)


def save_vault(vault: dict, key: bytes):
    ensure_vault_dir()
    plaintext = json.dumps(vault, indent=2).encode()
    VAULT_FILE.write_bytes(encrypt(plaintext, key))


# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

def cmd_init(args):
    ensure_vault_dir()
    meta = _read_meta()
    meta["created"] = datetime.now(timezone.utc).isoformat()
    meta["version"] = 1

    if args.keychain:
        key_hex = os.urandom(32).hex()
        _store_keychain(key_hex)
        meta["key_tier"] = "keychain"
        _write_meta(meta)
        key = bytes.fromhex(key_hex)
    elif args.env:
        meta["key_tier"] = "env"
        _write_meta(meta)
        key = _key_from_env()
        if not key:
            new_key = os.urandom(32).hex()
            print(f"Set this in your environment:\n  export CLAUDE_VAULT_KEY={new_key}")
            meta["key_tier"] = "env"
            _write_meta(meta)
            return
    elif args.kms:
        meta["key_tier"] = "kms"
        meta["kms_provider"] = args.kms
        meta["kms_key_id"] = args.key_id
        _write_meta(meta)
        print(f"KMS configured for {args.kms} with key {args.key_id}.")
        print("Envelope encryption not yet implemented — use --keychain or --passphrase for now.")
        return
    else:
        meta["key_tier"] = "passphrase"
        _write_meta(meta)
        key = _key_from_passphrase()

    vault = {"version": 1, "secrets": {}}
    save_vault(vault, key)
    audit("init")
    print(f"Vault initialized at {VAULT_DIR} (key tier: {meta['key_tier']})")


def cmd_set(args):
    key = resolve_key()
    vault = load_vault(key)
    now = datetime.now(timezone.utc).isoformat()
    tags = args.tags.split(",") if args.tags else []
    vault["secrets"][args.key] = {
        "value": args.value,
        "tags": tags,
        "created": now,
        "rotated": None,
    }
    save_vault(vault, key)
    audit("set", args.key)
    print(f"Stored: {args.key}")


def cmd_get(args):
    key = resolve_key()
    vault = load_vault(key)
    secret = vault["secrets"].get(args.key)
    if not secret:
        print(f"Not found: {args.key}", file=sys.stderr)
        sys.exit(1)
    audit("get", args.key)
    if args.export:
        env_name = args.key.replace(".", "_").upper()
        print(f"export {env_name}={secret['value']}")
    else:
        print(secret["value"])


def cmd_list(args):
    key = resolve_key()
    vault = load_vault(key)
    filter_tags = set(args.tags.split(",")) if args.tags else set()
    for name, entry in sorted(vault["secrets"].items()):
        entry_tags = set(entry.get("tags", []))
        if filter_tags and not filter_tags.issubset(entry_tags):
            continue
        tags_str = f"  [{', '.join(entry.get('tags', []))}]" if entry.get("tags") else ""
        rotated = f"  (rotated: {entry['rotated']})" if entry.get("rotated") else ""
        print(f"  {name}{tags_str}{rotated}")
    audit("list")


def cmd_rotate(args):
    key = resolve_key()
    vault = load_vault(key)
    if args.key not in vault["secrets"]:
        print(f"Not found: {args.key}", file=sys.stderr)
        sys.exit(1)
    vault["secrets"][args.key]["value"] = args.new_value
    vault["secrets"][args.key]["rotated"] = datetime.now(timezone.utc).isoformat()
    save_vault(vault, key)
    audit("rotate", args.key)
    print(f"Rotated: {args.key}")


def cmd_delete(args):
    key = resolve_key()
    vault = load_vault(key)
    if args.key not in vault["secrets"]:
        print(f"Not found: {args.key}", file=sys.stderr)
        sys.exit(1)
    del vault["secrets"][args.key]
    save_vault(vault, key)
    audit("delete", args.key)
    print(f"Deleted: {args.key}")


def cmd_import(args):
    """Import secrets from a file. Supports KEY=VALUE (.env) and JSON formats.
    The file is securely deleted after import."""
    filepath = Path(args.file)
    if not filepath.exists():
        print(f"File not found: {filepath}", file=sys.stderr)
        sys.exit(1)

    key = resolve_key()
    vault = load_vault(key)
    now = datetime.now(timezone.utc).isoformat()
    tags = args.tags.split(",") if args.tags else []
    count = 0

    content = filepath.read_text().strip()

    # Detect JSON format
    if content.startswith("{"):
        try:
            data = json.loads(content)
        except json.JSONDecodeError as e:
            print(f"Invalid JSON: {e}", file=sys.stderr)
            sys.exit(1)
        for k, v in data.items():
            vault["secrets"][k] = {
                "value": str(v),
                "tags": tags,
                "created": now,
                "rotated": None,
            }
            count += 1
    else:
        # KEY=VALUE format (one per line, # comments, blank lines skipped)
        for line in content.splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            # Strip optional 'export ' prefix
            if line.startswith("export "):
                line = line[7:]
            if "=" not in line:
                continue
            k, v = line.split("=", 1)
            k = k.strip()
            # Remove surrounding quotes from value
            v = v.strip().strip("'\"")
            vault["secrets"][k] = {
                "value": v,
                "tags": tags,
                "created": now,
                "rotated": None,
            }
            count += 1

    save_vault(vault, key)
    audit("import", f"{count} keys from {filepath.name}")

    # Securely delete the file
    if not args.keep:
        try:
            # Overwrite with random data before unlinking
            size = filepath.stat().st_size
            filepath.write_bytes(os.urandom(max(size, 64)))
            filepath.unlink()
            print(f"Imported {count} secret(s). File securely deleted.")
        except OSError:
            filepath.unlink(missing_ok=True)
            print(f"Imported {count} secret(s). File deleted.")
    else:
        print(f"Imported {count} secret(s). File kept (--keep).")


def cmd_export(args):
    key = resolve_key()
    vault = load_vault(key)
    fmt = args.format or "env"
    for name, entry in sorted(vault["secrets"].items()):
        env_name = name.replace(".", "_").upper()
        val = entry["value"]
        if fmt == "env":
            print(f"export {env_name}={val}")
        elif fmt == "github-actions":
            print(f"echo \"{env_name}={val}\" >> $GITHUB_ENV")
        elif fmt == "gitlab-ci":
            print(f"export {env_name}=\"{val}\"")
    audit("export", fmt)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Claude Secret Vault")
    sub = parser.add_subparsers(dest="command")

    p_init = sub.add_parser("init", help="Initialize a new vault")
    p_init.add_argument("--keychain", action="store_true", help="Use OS keychain")
    p_init.add_argument("--env", action="store_true", help="Use CLAUDE_VAULT_KEY env var")
    p_init.add_argument("--kms", choices=["aws", "azure", "gcp"], help="Cloud KMS provider")
    p_init.add_argument("--key-id", help="KMS key ID or alias")
    p_init.add_argument("--passphrase", action="store_true", help="Use passphrase (default)")

    p_set = sub.add_parser("set", help="Store a secret")
    p_set.add_argument("key")
    p_set.add_argument("value")
    p_set.add_argument("--tags", help="Comma-separated tags")

    p_get = sub.add_parser("get", help="Retrieve a secret")
    p_get.add_argument("key")
    p_get.add_argument("--export", action="store_true", help="Output as export statement")

    p_list = sub.add_parser("list", help="List stored keys")
    p_list.add_argument("--tags", help="Filter by tags")

    p_rot = sub.add_parser("rotate", help="Rotate a secret")
    p_rot.add_argument("key")
    p_rot.add_argument("new_value")

    p_del = sub.add_parser("delete", help="Delete a secret")
    p_del.add_argument("key")

    p_imp = sub.add_parser("import", help="Import secrets from a file (deleted after import)")
    p_imp.add_argument("file", help="Path to .env or JSON file")
    p_imp.add_argument("--tags", help="Comma-separated tags to apply to all imported secrets")
    p_imp.add_argument("--keep", action="store_true", help="Keep the file after import (default: securely delete)")

    p_exp = sub.add_parser("export", help="Export secrets for CI/CD")
    p_exp.add_argument("--format", choices=["env", "github-actions", "gitlab-ci"], default="env")

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        sys.exit(1)

    {"init": cmd_init, "set": cmd_set, "get": cmd_get, "list": cmd_list,
     "rotate": cmd_rotate, "delete": cmd_delete, "import": cmd_import,
     "export": cmd_export}[args.command](args)


if __name__ == "__main__":
    main()
