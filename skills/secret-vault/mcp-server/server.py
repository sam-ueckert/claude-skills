#!/usr/bin/env python3
"""
vault-mcp: MCP server for secure local secret storage.

Security contract:
  - Secret VALUES are captured via native OS dialogs — they are never
    passed as tool parameters and never appear in the LLM context.
  - The master vault key is resolved once per server lifetime and cached
    in process memory. It is never returned to the LLM.
  - Tool results return only key names, metadata, and status strings.
"""

import os
import platform
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

sys.path.insert(0, str(Path(__file__).parent))

from mcp.server.fastmcp import FastMCP
from vault_core import (
    VAULT_DIR, VAULT_FILE,
    ensure_vault_dir, audit,
    _read_meta, _write_meta,
    _key_from_keychain, _store_keychain,
    _key_from_env, _key_from_passphrase,
    load_vault, save_vault,
)

mcp = FastMCP("secret-vault")

# In-process key cache — lives only in this server process, never sent to LLM
_cached_key: Optional[bytes] = None


# ---------------------------------------------------------------------------
# Native prompt — captures input locally, bypasses LLM routing entirely
# ---------------------------------------------------------------------------

def _native_prompt(message: str, title: str = "Agent Secret Vault") -> str:
    """Collect sensitive input via native OS dialog.

    On macOS: opens a system dialog with a masked password field.
    On Linux/other: falls back to terminal getpass.
    The captured value stays within this process — it is never forwarded
    to any LLM endpoint.
    """
    if platform.system() == "Darwin":
        safe_msg = message.replace("\\", "\\\\").replace('"', '\\"')
        safe_title = title.replace("\\", "\\\\").replace('"', '\\"')
        script = (
            f'display dialog "{safe_msg}" '
            f'default answer "" '
            f'with hidden answer '
            f'buttons {{"Cancel", "OK"}} '
            f'default button "OK" '
            f'with title "{safe_title}"'
        )
        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True, text=True, timeout=120
        )
        if result.returncode != 0:
            raise RuntimeError("Prompt was cancelled or display is unavailable.")
        # Output: "button returned:OK, text returned:<value>"
        for part in result.stdout.strip().split(", "):
            if part.startswith("text returned:"):
                return part[len("text returned:"):]
        raise RuntimeError("Could not parse dialog output.")
    else:
        import getpass
        return getpass.getpass(f"{message}: ")


# ---------------------------------------------------------------------------
# Key resolution — resolved once, cached for server lifetime
# ---------------------------------------------------------------------------

def _get_key() -> bytes:
    """Return the vault encryption key, auto-initializing on first run.

    Resolution order: keychain → VAULT_KEY env var → passphrase (native prompt).
    Result is cached in _cached_key for the lifetime of this server process.
    """
    global _cached_key
    if _cached_key is not None:
        return _cached_key

    meta = _read_meta()
    tier = meta.get("key_tier")

    if not tier:
        return _auto_init()

    if tier == "keychain":
        key = _key_from_keychain()
        if not key:
            raise RuntimeError(
                "Vault key not found in OS keychain. "
                "Run vault_init to re-initialize."
            )
        _cached_key = key
        return key

    if tier == "env":
        key = _key_from_env()
        if not key:
            raise RuntimeError("VAULT_KEY environment variable is not set.")
        _cached_key = key
        return key

    # passphrase tier
    passphrase = _native_prompt(
        "Enter your vault passphrase:",
        "Agent Secret Vault — Unlock"
    )
    key = _key_from_passphrase(passphrase)
    _cached_key = key
    return key


def _auto_init() -> bytes:
    """First-run: initialize vault using keychain on macOS, passphrase elsewhere."""
    ensure_vault_dir()
    meta = _read_meta()
    meta["created"] = datetime.now(timezone.utc).isoformat()
    meta["version"] = 1

    if platform.system() == "Darwin":
        key_hex = os.urandom(32).hex()
        _store_keychain(key_hex)
        meta["key_tier"] = "keychain"
        _write_meta(meta)
        key = bytes.fromhex(key_hex)
    else:
        passphrase = _native_prompt(
            "Create a passphrase to protect your vault:",
            "Agent Secret Vault — First-time Setup"
        )
        meta["key_tier"] = "passphrase"
        _write_meta(meta)
        key = _key_from_passphrase(passphrase)

    save_vault({"version": 1, "secrets": {}}, key)
    audit("auto-init")

    global _cached_key
    _cached_key = key
    return key


# ---------------------------------------------------------------------------
# Tools
# ---------------------------------------------------------------------------

@mcp.tool()
def vault_status() -> str:
    """Check vault status: initialization state, key tier, and secret count."""
    meta = _read_meta()
    if not meta:
        return "Vault not initialized. Call vault_init to set up."

    tier = meta.get("key_tier", "unknown")
    created = meta.get("created", "unknown")[:10]

    try:
        key = _get_key()
        vault = load_vault(key)
        count = len(vault.get("secrets", {}))
        return (
            f"Vault ready  |  key tier: {tier}  |  "
            f"created: {created}  |  secrets stored: {count}"
        )
    except Exception as e:
        return f"Vault initialized (tier: {tier}, created: {created}) — locked: {e}"


@mcp.tool()
def vault_init(key_tier: str = "keychain", force: bool = False) -> str:
    """Initialize or re-initialize the secret vault.

    WARNING: Re-initializing an existing vault generates a new key and
    writes an empty vault, permanently destroying all stored secrets.
    Pass force=True to confirm destruction of existing data.

    Args:
        key_tier: Master key protection method.
                  'keychain' — random key stored in OS keychain (recommended).
                  'passphrase' — passphrase-derived key, collected via native prompt.
                  'env' — key read from VAULT_KEY environment variable.
        force:    Must be True to overwrite a vault that already contains secrets.
    """
    global _cached_key

    if key_tier not in ("keychain", "passphrase", "env"):
        return "Error: key_tier must be 'keychain', 'passphrase', or 'env'."

    # Guard: refuse to wipe an existing vault with secrets unless force=True
    if VAULT_FILE.exists() and not force:
        try:
            existing_key = _get_key()
            existing_vault = load_vault(existing_key)
            count = len(existing_vault.get("secrets", {}))
            if count > 0:
                return (
                    f"Error: vault already contains {count} secret(s). "
                    "Re-initializing will permanently destroy them. "
                    "Call vault_init with force=True to confirm, or use "
                    "vault_rekey to rotate the master key while preserving secrets."
                )
        except Exception:
            pass  # Can't read existing vault — allow init to proceed

    ensure_vault_dir()
    meta = _read_meta()
    meta["created"] = datetime.now(timezone.utc).isoformat()
    meta["version"] = 1
    meta["key_tier"] = key_tier

    if key_tier == "keychain":
        if platform.system() not in ("Darwin", "Linux"):
            return f"Error: keychain not supported on {platform.system()}."
        key_hex = os.urandom(32).hex()
        try:
            _store_keychain(key_hex)
        except Exception as e:
            return f"Error storing key in keychain: {e}"
        _write_meta(meta)
        key = bytes.fromhex(key_hex)

    elif key_tier == "passphrase":
        _write_meta(meta)
        try:
            passphrase = _native_prompt(
                "Create a passphrase for your vault:",
                "Agent Secret Vault — Setup"
            )
        except RuntimeError as e:
            return f"Cancelled: {e}"
        key = _key_from_passphrase(passphrase)

    else:  # env
        key = _key_from_env()
        if not key:
            _write_meta(meta)
            return (
                "Vault configured for env tier. "
                "Set VAULT_KEY=<64 hex chars> in your environment, then retry."
            )
        _write_meta(meta)

    save_vault({"version": 1, "secrets": {}}, key)
    _cached_key = key
    audit("init", key_tier)
    return f"Vault initialized. Key tier: {key_tier}"


@mcp.tool()
def vault_rekey(new_key_tier: str = "keychain") -> str:
    """Rotate the vault master key while preserving all stored secrets.

    Decrypts the vault with the current key, generates or derives a new key
    (collected via native OS dialog for passphrase tier), re-encrypts all
    secrets under the new key, and updates the key tier in metadata.

    The new key is never exposed to the LLM — keychain keys are random and
    stored in the OS keychain; passphrase keys are derived inside this process
    from input captured via native dialog.

    Args:
        new_key_tier: Key tier for the new key.
                      'keychain' — new random key stored in OS keychain.
                      'passphrase' — new passphrase-derived key via native prompt.
                      'env' — new key read from VAULT_KEY environment variable.
    """
    global _cached_key

    if new_key_tier not in ("keychain", "passphrase", "env"):
        return "Error: new_key_tier must be 'keychain', 'passphrase', or 'env'."

    # Decrypt vault with current key
    try:
        current_key = _get_key()
        vault = load_vault(current_key)
    except RuntimeError as e:
        return f"Error unlocking vault with current key: {e}"

    secret_count = len(vault.get("secrets", {}))

    # Generate / collect new key
    meta = _read_meta()
    meta["key_tier"] = new_key_tier

    if new_key_tier == "keychain":
        if platform.system() not in ("Darwin", "Linux"):
            return f"Error: keychain not supported on {platform.system()}."
        key_hex = os.urandom(32).hex()
        try:
            _store_keychain(key_hex)
        except Exception as e:
            return f"Error storing new key in keychain: {e}"
        new_key = bytes.fromhex(key_hex)

    elif new_key_tier == "passphrase":
        # Remove stale salt so _key_from_passphrase generates a fresh one
        meta.pop("salt", None)
        _write_meta(meta)
        try:
            passphrase = _native_prompt(
                "Enter new vault passphrase:",
                "Agent Secret Vault — Rekey"
            )
        except RuntimeError as e:
            return f"Cancelled: {e}"
        new_key = _key_from_passphrase(passphrase)

    else:  # env
        new_key = _key_from_env()
        if not new_key:
            return "Error: VAULT_KEY environment variable is not set."

    # Re-encrypt and save
    _write_meta(meta)
    save_vault(vault, new_key)
    _cached_key = new_key
    audit("rekey", new_key_tier)
    return (
        f"Vault rekeyed. New key tier: {new_key_tier}. "
        f"{secret_count} secret(s) preserved."
    )


@mcp.tool()
def vault_list(tags: str = "") -> str:
    """List stored secret names and metadata. Values are never returned.

    Args:
        tags: Comma-separated tags to filter by, e.g. 'env:prod,service:aws'.
    """
    try:
        key = _get_key()
        vault = load_vault(key)
    except RuntimeError as e:
        return f"Error: {e}"

    secrets = vault.get("secrets", {})
    if not secrets:
        return "Vault is empty."

    filter_tags = {t.strip() for t in tags.split(",") if t.strip()} if tags else set()
    lines = []
    for name, entry in sorted(secrets.items()):
        entry_tags = set(entry.get("tags", []))
        if filter_tags and not filter_tags.issubset(entry_tags):
            continue
        tag_str = f"  [{', '.join(sorted(entry_tags))}]" if entry_tags else ""
        rotated = f"  rotated: {entry['rotated'][:10]}" if entry.get("rotated") else ""
        created = entry.get("created", "")[:10]
        lines.append(f"  {name}{tag_str}  created: {created}{rotated}")

    audit("list")
    if not lines:
        return "No secrets match the given tags."
    header = "Stored secrets (names and metadata only — values are not accessible here):"
    return header + "\n" + "\n".join(lines)


@mcp.tool()
def vault_set(name: str, tags: str = "") -> str:
    """Store a new secret or overwrite an existing one.

    The secret value is collected via a native OS dialog. It is NOT passed
    as a parameter and does NOT enter the LLM context at any point.

    Args:
        name: Secret key name, e.g. 'github.token' or 'aws.access_key_id'.
        tags: Optional comma-separated tags, e.g. 'env:prod,service:github'.
    """
    try:
        value = _native_prompt(
            f"Enter value for secret  \"{name}\":",
            "Agent Secret Vault — Store Secret"
        )
    except RuntimeError as e:
        return f"Cancelled: {e}"

    if not value.strip():
        return "Cancelled: empty value not accepted."

    try:
        key = _get_key()
        vault = load_vault(key)
    except RuntimeError as e:
        return f"Error unlocking vault: {e}"

    now = datetime.now(timezone.utc).isoformat()
    tag_list = [t.strip() for t in tags.split(",") if t.strip()] if tags else []
    vault["secrets"][name] = {
        "value": value,
        "tags": tag_list,
        "created": now,
        "rotated": None,
    }
    save_vault(vault, key)
    audit("set", name)
    return f"Secret '{name}' stored."


@mcp.tool()
def vault_rotate(name: str) -> str:
    """Rotate (replace) an existing secret's value.

    The new value is collected via a native OS dialog — it never enters
    the LLM context.

    Args:
        name: Key name of the secret to rotate.
    """
    try:
        key = _get_key()
        vault = load_vault(key)
    except RuntimeError as e:
        return f"Error: {e}"

    if name not in vault.get("secrets", {}):
        return f"Error: '{name}' not found. Use vault_set to create it."

    try:
        new_value = _native_prompt(
            f"Enter new value for secret  \"{name}\":",
            "Agent Secret Vault — Rotate Secret"
        )
    except RuntimeError as e:
        return f"Cancelled: {e}"

    if not new_value.strip():
        return "Cancelled: empty value not accepted."

    vault["secrets"][name]["value"] = new_value
    vault["secrets"][name]["rotated"] = datetime.now(timezone.utc).isoformat()
    save_vault(vault, key)
    audit("rotate", name)
    return f"Secret '{name}' rotated."


@mcp.tool()
def vault_delete(name: str) -> str:
    """Delete a secret from the vault.

    Args:
        name: Key name of the secret to delete.
    """
    try:
        key = _get_key()
        vault = load_vault(key)
    except RuntimeError as e:
        return f"Error: {e}"

    if name not in vault.get("secrets", {}):
        return f"Error: '{name}' not found."

    del vault["secrets"][name]
    save_vault(vault, key)
    audit("delete", name)
    return f"Secret '{name}' deleted."


@mcp.tool()
def vault_exists(name: str) -> str:
    """Check whether a secret key exists in the vault.

    Args:
        name: Key name to check.
    """
    try:
        key = _get_key()
        vault = load_vault(key)
    except RuntimeError as e:
        return f"Error: {e}"

    found = name in vault.get("secrets", {})
    audit("exists", name)
    return f"'{name}' {'exists' if found else 'not found'}."


@mcp.tool()
def vault_get_metadata(name: str) -> str:
    """Get metadata for a secret: tags, created date, last rotated.
    The secret value is never returned.

    Args:
        name: Key name to inspect.
    """
    try:
        key = _get_key()
        vault = load_vault(key)
    except RuntimeError as e:
        return f"Error: {e}"

    entry = vault.get("secrets", {}).get(name)
    if not entry:
        return f"Error: '{name}' not found."

    audit("metadata", name)
    tags = ", ".join(entry.get("tags", [])) or "(none)"
    created = entry.get("created", "unknown")
    rotated = entry.get("rotated") or "never"
    return (
        f"Secret:  {name}\n"
        f"Tags:    {tags}\n"
        f"Created: {created}\n"
        f"Rotated: {rotated}"
    )


@mcp.tool()
def vault_update_tags(name: str, tags: str) -> str:
    """Update the tags on a secret without touching its value.

    Args:
        name: Key name of the secret.
        tags: New comma-separated tags (replaces all existing tags).
              Pass an empty string to clear tags.
    """
    try:
        key = _get_key()
        vault = load_vault(key)
    except RuntimeError as e:
        return f"Error: {e}"

    if name not in vault.get("secrets", {}):
        return f"Error: '{name}' not found."

    tag_list = [t.strip() for t in tags.split(",") if t.strip()] if tags else []
    vault["secrets"][name]["tags"] = tag_list
    save_vault(vault, key)
    audit("update_tags", name)
    return f"Tags updated for '{name}': {tag_list if tag_list else '(cleared)'}"


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    mcp.run()
