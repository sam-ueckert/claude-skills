#!/usr/bin/env python3
"""
gitlab.py — GitLab API client for Claude skills.
Supports both GitLab.com and self-hosted instances.

Usage:
    gitlab.py create-project --name <n> [--private] [--description "..."]
    gitlab.py push --project <namespace/project> --dir <path> [--branch main]
    gitlab.py add-variable --project <ns/proj> --key <KEY> --value <VAL> [--masked] [--protected]
    gitlab.py list-projects [--limit 20]
    gitlab.py --help
"""

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path
from urllib.parse import quote_plus
from urllib.request import Request, urlopen
from urllib.error import HTTPError

VAULT_SCRIPT = Path(__file__).parent.parent.parent / "secret-vault" / "scripts" / "vault.py"


def _vault_get(key: str) -> str:
    if VAULT_SCRIPT.exists():
        try:
            result = subprocess.run(
                [sys.executable, str(VAULT_SCRIPT), "get", key],
                capture_output=True, text=True
            )
            if result.returncode == 0 and result.stdout.strip():
                return result.stdout.strip()
        except Exception:
            pass
    return ""


def get_token() -> str:
    token = _vault_get("gitlab.token") or os.environ.get("GITLAB_TOKEN", "")
    if not token:
        print("ERROR: No GitLab token found. Store one with:")
        print("  python3 secret-vault/scripts/vault.py set gitlab.token glpat-...")
        print("Or set GITLAB_TOKEN environment variable.")
        sys.exit(1)
    return token


def get_host() -> str:
    return _vault_get("gitlab.host") or os.environ.get("GITLAB_HOST", "https://gitlab.com")


def api(method: str, path: str, data: dict = None) -> dict:
    host = get_host().rstrip("/")
    url = f"{host}/api/v4{path}"
    body = json.dumps(data).encode() if data else None
    req = Request(url, data=body, method=method)
    req.add_header("PRIVATE-TOKEN", get_token())
    if body:
        req.add_header("Content-Type", "application/json")
    try:
        with urlopen(req) as resp:
            if resp.status == 204:
                return {}
            return json.loads(resp.read())
    except HTTPError as e:
        err = {}
        try:
            err = json.loads(e.read())
        except Exception:
            pass
        msg = err.get("message", err.get("error", str(e)))
        print(f"GitLab API error {e.code}: {msg}", file=sys.stderr)
        sys.exit(1)


def cmd_create_project(args):
    data = {
        "name": args.name,
        "visibility": "private" if args.private else "public",
        "initialize_with_readme": True,
    }
    if args.description:
        data["description"] = args.description
    result = api("POST", "/projects", data)
    print(f"Created: {result['web_url']}")


def cmd_push(args):
    token = get_token()
    host = get_host().rstrip("/")
    project = args.project
    local_dir = Path(args.dir).resolve()
    branch = args.branch or "main"

    if not local_dir.is_dir():
        print(f"ERROR: {local_dir} is not a directory", file=sys.stderr)
        sys.exit(1)

    os.chdir(local_dir)

    # Parse host for remote URL
    host_clean = host.replace("https://", "").replace("http://", "")
    remote_url = f"https://oauth2:{token}@{host_clean}/{project}.git"

    if not (local_dir / ".git").exists():
        subprocess.run(["git", "init"], check=True)
        subprocess.run(["git", "checkout", "-b", branch], check=True)

    remotes = subprocess.run(["git", "remote"], capture_output=True, text=True).stdout
    if "origin" in remotes:
        subprocess.run(["git", "remote", "set-url", "origin", remote_url], check=True)
    else:
        subprocess.run(["git", "remote", "add", "origin", remote_url], check=True)

    subprocess.run(["git", "add", "-A"], check=True)
    status = subprocess.run(["git", "status", "--porcelain"], capture_output=True, text=True)
    if status.stdout.strip():
        subprocess.run(["git", "commit", "-m", "push via claude gitlab skill"], check=True)

    result = subprocess.run(
        ["git", "push", "-u", "origin", branch, "--force"],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"Push failed: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"Pushed to {host}/{project} ({branch})")


def cmd_add_variable(args):
    project_encoded = quote_plus(args.project)
    data = {
        "key": args.key,
        "value": args.value,
        "masked": args.masked,
        "protected": args.protected,
        "variable_type": "env_var",
    }
    api("POST", f"/projects/{project_encoded}/variables", data)
    flags = []
    if args.masked:
        flags.append("masked")
    if args.protected:
        flags.append("protected")
    flag_str = f" ({', '.join(flags)})" if flags else ""
    print(f"Variable '{args.key}' set on {args.project}{flag_str}")


def cmd_list_projects(args):
    limit = args.limit or 20
    projects = api("GET", f"/projects?membership=true&per_page={limit}&order_by=updated_at")
    for p in projects:
        vis = p.get("visibility", "?")
        desc = p.get("description", "") or ""
        print(f"  {p['path_with_namespace']}  ({vis})  {desc}")


def main():
    parser = argparse.ArgumentParser(description="GitLab API client for Claude skills")
    sub = parser.add_subparsers(dest="command")

    p_create = sub.add_parser("create-project")
    p_create.add_argument("--name", required=True)
    p_create.add_argument("--private", action="store_true")
    p_create.add_argument("--description", default="")

    p_push = sub.add_parser("push")
    p_push.add_argument("--project", required=True, help="namespace/project")
    p_push.add_argument("--dir", required=True)
    p_push.add_argument("--branch", default="main")

    p_var = sub.add_parser("add-variable")
    p_var.add_argument("--project", required=True)
    p_var.add_argument("--key", required=True)
    p_var.add_argument("--value", required=True)
    p_var.add_argument("--masked", action="store_true")
    p_var.add_argument("--protected", action="store_true")

    p_list = sub.add_parser("list-projects")
    p_list.add_argument("--limit", type=int, default=20)

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        sys.exit(1)

    {"create-project": cmd_create_project, "push": cmd_push,
     "add-variable": cmd_add_variable, "list-projects": cmd_list_projects}[args.command](args)


if __name__ == "__main__":
    main()
