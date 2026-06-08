#!/usr/bin/env python3
# SOURCE OF TRUTH: https://github.com/sam-ueckert/vault-mcp
# Edit here, then run sync.sh to propagate to ai-skills-catalog and claude-skills.
"""
Vault core — encryption, key resolution, and vault I/O.
"""

import base64
import hashlib
import json
import os
import platform
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

VAULT_DIR = Path.home() / ".agent/vault"
VAULT_FILE = VAULT_DIR / "vault.enc"
META_FILE = VAULT_DIR / ".vault-meta"
AUDIT_LOG = VAULT_DIR / "audit.log"
SERVICE_NAME = "agent-secret-vault"


def ensure_vault_dir():
    VAULT_DIR.mkdir(parents=True, exist_ok=True)


def audit(action: str, key: str = ""):
    ensure_vault_dir()
    ts = datetime.now(timezone.utc).isoformat()
    with open(AUDIT_LOG, "a") as f:
        f.write(f"{ts} | {action} | {key}\n")


# ---------------------------------------------------------------------------
# Encryption — AES-256-GCM
# ---------------------------------------------------------------------------

def _get_aesgcm():
    try:
        from cryptography.hazmat.primitives.ciphers.aead import AESGCM
        return AESGCM
    except ImportError:
        raise RuntimeError("'cryptography' package required: pip install cryptography")


def encrypt(plaintext: bytes, key: bytes) -> bytes:
    AESGCM = _get_aesgcm()
    nonce = os.urandom(12)
    ct = AESGCM(key).encrypt(nonce, plaintext, None)
    return nonce + ct


def decrypt(data: bytes, key: bytes) -> bytes:
    AESGCM = _get_aesgcm()
    nonce, ct = data[:12], data[12:]
    return AESGCM(key).decrypt(nonce, ct, None)


# ---------------------------------------------------------------------------
# Metadata
# ---------------------------------------------------------------------------

def _read_meta() -> dict:
    if META_FILE.exists():
        return json.loads(META_FILE.read_text())
    return {}


def _write_meta(meta: dict):
    ensure_vault_dir()
    META_FILE.write_text(json.dumps(meta, indent=2))


# ---------------------------------------------------------------------------
# Key backends
# ---------------------------------------------------------------------------

def _key_from_keychain() -> bytes | None:
    try:
        if platform.system() == "Darwin":
            result = subprocess.run(
                ["security", "find-generic-password", "-s", SERVICE_NAME, "-w"],
                capture_output=True, text=True
            )
            if result.returncode == 0:
                return bytes.fromhex(result.stdout.strip())
        elif platform.system() == "Linux":
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
    if platform.system() == "Darwin":
        subprocess.run([
            "security", "add-generic-password",
            "-s", SERVICE_NAME, "-a", "agent", "-w", key_hex, "-U"
        ], check=True)
    elif platform.system() == "Linux":
        proc = subprocess.Popen(
            ["secret-tool", "store", "--label", SERVICE_NAME, "service", SERVICE_NAME],
            stdin=subprocess.PIPE
        )
        proc.communicate(input=key_hex.encode())
    else:
        raise RuntimeError(f"Keychain not supported on {platform.system()}")


def _key_from_env() -> bytes | None:
    val = os.environ.get("VAULT_KEY")
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
    try:
        from argon2.low_level import hash_secret_raw, Type
        return hash_secret_raw(
            secret=passphrase.encode(), salt=salt,
            time_cost=3, memory_cost=65536, parallelism=4,
            hash_len=32, type=Type.ID
        )
    except ImportError:
        return hashlib.pbkdf2_hmac("sha256", passphrase.encode(), salt, 600_000)


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
