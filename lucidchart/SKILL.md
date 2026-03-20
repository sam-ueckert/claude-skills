---
name: lucidchart
description: "Manage Lucidchart documents via the REST API: create, search, export as PNG, share, and organize in folders. Use when asked to create a Lucidchart, export a Lucid diagram, share a Lucid document, or search Lucidchart for existing diagrams."
---

# Lucidchart Integration

Manage Lucidchart documents via the enterprise REST API.

## Setup

Set the environment variable `LUCID_API_KEY` with your Lucidchart API key (created at https://lucid.app/developer#/apikeys). The key needs these grants:
- `DocumentEdit` — create documents
- `DocumentReadonly` — export documents
- `DocumentAdmin` — search documents

## Scripts

All scripts are in this skill's `scripts/` directory. They require `curl` and `jq`.

### Create a document

```bash
bash scripts/lucidchart.sh create "Diagram Title" [folder_id]
```

Returns the document ID and edit URL.

### Create from template

```bash
bash scripts/lucidchart.sh create-from-template "Title" <template_uuid> [folder_id]
```

### Export as PNG

```bash
bash scripts/lucidchart.sh export <document_id> output.png
```

### Search documents

```bash
bash scripts/lucidchart.sh search "keyword"
```

Returns JSON array of matching documents with IDs and titles.

### Get document info

```bash
bash scripts/lucidchart.sh get <document_id>
```

Returns document metadata as JSON.

### List folders

```bash
bash scripts/lucidchart.sh folders
```

## Workflow

1. Create a document: `bash scripts/lucidchart.sh create "My Diagram"`
2. Open the edit URL in browser to design the diagram (or use a template)
3. Export as PNG: `bash scripts/lucidchart.sh export <id> diagram.png`
4. Embed in target document:
   - Markdown: `![description](path/to/diagram.png)`
   - Obsidian: `![[diagram.png]]`

## Notes

- The API creates blank documents or copies templates — there is no programmatic way to add shapes/content via REST API. Users design in the Lucidchart editor.
- Share links require OAuth 2.0 (not API keys). Use the Lucidchart UI to share.
- Export rate limit: 75 requests per 5 seconds.
- Base URL: `https://api.lucid.co`
- All requests require header `Lucid-Api-Version: 1`.
