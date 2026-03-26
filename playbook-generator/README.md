# Playbook Generator

Generate operational playbooks, runbooks, and SOPs that conform to organizational standards.

## Quick Start

Just ask Claude to create a playbook:

> "Create a playbook for rotating AWS credentials across all environments"

The generator uses the baseline standard by default. To add org-specific requirements:

```bash
cp schemas/org-standard-template.yaml ~/.claude/playbook-standards/my-company.yaml
# Edit the file with your org's requirements
```

## Standards Layering

1. **Baseline** (`schemas/baseline-standard.yaml`) — always applied
2. **Org overrides** (`~/.claude/playbook-standards/*.yaml`) — merged on top
3. **Inline overrides** — one-off exceptions documented in the output

## Examples

See `examples/` for real playbook outputs.
