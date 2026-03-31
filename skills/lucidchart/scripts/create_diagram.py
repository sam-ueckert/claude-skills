#!/usr/bin/env python3
"""
Small helper to create a Lucidchart document using an API key.

Usage:
  python3 scripts/create_diagram.py --title "My Diagram"
  python3 scripts/create_diagram.py --title "From Template" --template-id TEMPLATE_ID

Environment:
  LUCID_API_KEY  - required
  LUCID_API_BASE - optional (default: https://api.lucid.co)

Note: Adjust headers/auth scheme if your enterprise uses a different format.
"""
import os
import sys
import argparse
import json
import requests


def create_document(title: str, api_key: str, base: str, template_id: str | None = None, folder_id: str | None = None):
    url = f"{base.rstrip('/')}/documents"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Lucid-Api-Version": "1",
        "Content-Type": "application/json",
    }
    payload = {"title": title}
    if template_id:
        payload["templateId"] = template_id
    if folder_id:
        payload["folderId"] = folder_id

    resp = requests.post(url, headers=headers, data=json.dumps(payload), timeout=30)
    resp.raise_for_status()
    return resp.json()


def main(argv):
    p = argparse.ArgumentParser(description="Create a Lucidchart document via API key")
    p.add_argument("--title", required=True, help="Document title")
    p.add_argument("--template-id", help="Template UUID to copy")
    p.add_argument("--folder-id", help="Folder ID to place the document in")
    p.add_argument("--api-base", default=None, help="API base URL override")
    args = p.parse_args(argv)

    api_key = os.getenv("LUCID_API_KEY")
    if not api_key:
        print("Missing environment variable LUCID_API_KEY", file=sys.stderr)
        sys.exit(2)

    base = args.api_base or os.getenv("LUCID_API_BASE") or "https://api.lucid.co"

    try:
        result = create_document(args.title, api_key, base, template_id=args.template_id, folder_id=args.folder_id)
    except requests.HTTPError as e:
        print("API request failed:", e, file=sys.stderr)
        try:
            print(e.response.text, file=sys.stderr)
        except Exception:
            pass
        sys.exit(1)

    # Try to present a usable edit URL if possible
    doc_id = result.get("id") or result.get("documentId")
    if doc_id:
        edit_url = f"https://lucid.app/documents/{doc_id}/edit"
    else:
        edit_url = None

    print(json.dumps({"created": result, "edit_url": edit_url}, indent=2))


if __name__ == "__main__":
    main(sys.argv[1:])
