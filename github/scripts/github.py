#!/usr/bin/env python3
"""
github.py — GitHub API client for Claude skills.

Usage:
    github.py create-repo --name <name> [--private] [--description "..."]
    github.py push --repo <owner/repo> --dir <path> [--branch main]
    github.py add-secret --repo <owner/repo> --name <NAME> --value <VALUE>
    github.py list-repos [--limit 20]
    github.py --help

Authentication:
    Reads from secret-vault (github.pat) or GITHUB_TOKEN env var.
"""

import argparse
import base64
import json
import os
import subprocess
import sys
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.error import HTTPError

API = "https://api.github.com"
VAULT_SCRIPT = Path(__file__).parent.parent.parent / "secret-vault" / "scripts" / "vault.py"


def get_token() -> str:
    # Try secret-vault first
    if VAULT_SCRIPT.exists():
        try:
            result = subprocess.run(
                [sys.executable, str(VAULT_SCRIPT), "get", "github.pat"],
                capture_output=True, text=True
            )
            if result.returncode == 0 and result.stdout.strip():
                return result.stdout.strip()
        except Exception:
            pass
    # Fall back to env var
    token = os.environ.get("GITHUB_TOKEN", "")
    if not token:
        print("ERROR: No GitHub token found. Store one with:")
        print("  python3 secret-vault/scripts/vault.py set github.pat ghp_...")
        print("Or set GITHUB_TOKEN environment variable.")
        sys.exit(1)
    return token


def api(method: str, path: str, data: dict = None, token: str = None) -> dict:
    url = f"{API}{path}" if path.startswith("/") else path
    body = json.dumps(data).encode() if data else None
    req = Request(url, data=body, method=method)
    req.add_header("Authorization", f"Bearer {token or get_token()}")
    req.add_header("Accept", "application/vnd.github+json")
    req.add_header("X-GitHub-Api-Version", "2022-11-28")
    if body:
        req.add_header("Content-Type", "application/json")
    try:
        with urlopen(req) as resp:
            if resp.status == 204:
                return {}
            return json.loads(resp.read())
    except HTTPError as e:
        err = json.loads(e.read()) if e.fp else {}
        print(f"GitHub API error {e.code}: {err.get('message', str(e))}", file=sys.stderr)
        sys.exit(1)


def cmd_create_repo(args):
    token = get_token()
    data = {
        "name": args.name,
        "private": args.private,
        "auto_init": True,
    }
    if args.description:
        data["description"] = args.description
    result = api("POST", "/user/repos", data, token)
    print(f"Created: {result['html_url']}")
    if args.private:
        print("  Visibility: private")


def cmd_push(args):
    token = get_token()
    repo = args.repo
    local_dir = Path(args.dir).resolve()
    branch = args.branch or "main"

    if not local_dir.is_dir():
        print(f"ERROR: {local_dir} is not a directory", file=sys.stderr)
        sys.exit(1)

    os.chdir(local_dir)

    # Init git if needed
    if not (local_dir / ".git").exists():
        subprocess.run(["git", "init"], check=True)
        subprocess.run(["git", "checkout", "-b", branch], check=True)

    # Set remote
    remote_url = f"https://x-access-token:{token}@github.com/{repo}.git"
    remotes = subprocess.run(["git", "remote"], capture_output=True, text=True).stdout
    if "origin" in remotes:
        subprocess.run(["git", "remote", "set-url", "origin", remote_url], check=True)
    else:
        subprocess.run(["git", "remote", "add", "origin", remote_url], check=True)

    # Add, commit, push
    subprocess.run(["git", "add", "-A"], check=True)
    status = subprocess.run(["git", "status", "--porcelain"], capture_output=True, text=True)
    if status.stdout.strip():
        subprocess.run(["git", "commit", "-m", "push via claude github skill"], check=True)

    result = subprocess.run(
        ["git", "push", "-u", "origin", branch, "--force"],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"Push failed: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"Pushed to https://github.com/{repo} ({branch})")


def cmd_add_secret(args):
    token = get_token()
    repo = args.repo

    # Get repo public key for encryption
    key_info = api("GET", f"/repos/{repo}/actions/secrets/public-key", token=token)
    pub_key = key_info["key"]
    key_id = key_info["key_id"]

    # Encrypt with libsodium sealed box
    try:
        from nacl.public import SealedBox, PublicKey
        pk = PublicKey(base64.b64decode(pub_key))
        sealed = SealedBox(pk).encrypt(args.value.encode())
        encrypted = base64.b64encode(sealed).decode()
    except ImportError:
        print("ERROR: 'PyNaCl' package required for secret encryption.")
        print("  pip install pynacl")
        sys.exit(1)

    api("PUT", f"/repos/{repo}/actions/secrets/{args.name}", {
        "encrypted_value": encrypted,
        "key_id": key_id,
    }, token)
    print(f"Secret '{args.name}' set on {repo}")


def cmd_list_repos(args):
    token = get_token()
    limit = args.limit or 20
    repos = api("GET", f"/user/repos?per_page={limit}&sort=updated", token=token)
    for r in repos:
        vis = "private" if r["private"] else "public"
        print(f"  {r['full_name']}  ({vis})  {r.get('description', '') or ''}")


def main():
    parser = argparse.ArgumentParser(description="GitHub API client for Claude skills")
    sub = parser.add_subparsers(dest="command")

    p_create = sub.add_parser("create-repo")
    p_create.add_argument("--name", required=True)
    p_create.add_argument("--private", action="store_true")
    p_create.add_argument("--description", default="")

    p_push = sub.add_parser("push")
    p_push.add_argument("--repo", required=True, help="owner/repo")
    p_push.add_argument("--dir", required=True, help="Local directory to push")
    p_push.add_argument("--branch", default="main")

    p_secret = sub.add_parser("add-secret")
    p_secret.add_argument("--repo", required=True)
    p_secret.add_argument("--name", required=True)
    p_secret.add_argument("--value", required=True)

    p_list = sub.add_parser("list-repos")
    p_list.add_argument("--limit", type=int, default=20)

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        sys.exit(1)

    {"create-repo": cmd_create_repo, "push": cmd_push,
     "add-secret": cmd_add_secret, "list-repos": cmd_list_repos}[args.command](args)


if __name__ == "__main__":
    main()
