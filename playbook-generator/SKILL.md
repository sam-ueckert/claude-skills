---
name: playbook-generator
description: >
  Generate operational playbooks, runbooks, and standard operating procedures (SOPs)
  that conform to organizational or baseline standards. Use this skill whenever the
  user asks to create a playbook, runbook, SOP, operational procedure, incident
  response plan, deployment guide, or any step-by-step operational document. Also
  triggers when the user wants to define, update, or validate conformance standards
  for playbooks. Works for any domain: cloud operations, security incident response,
  deployment, onboarding, maintenance windows, disaster recovery, etc.
---

# Playbook Generator

Generates standards-conformant operational playbooks with layered standards: a
baseline schema ships with the skill, org overrides customize per-client, and inline
overrides handle one-off exceptions.

## Standards Layering

Standards are resolved in order (later layers override earlier):

### 1. Baseline Standard (ships with this skill)
Read `schemas/baseline-standard.yaml` — defines required sections, step structure,
metadata fields, and formatting rules that every playbook must have.

Key requirements from the baseline:
- Every playbook has: title, purpose, scope, prerequisites, steps, rollback, and
  verification sections
- Each step has: number, action (imperative verb), expected outcome, and responsible role
- Metadata includes: author, version, last-reviewed date, approval status
- Rollback section is mandatory — no playbook ships without a way to undo

### 2. Org Overrides (client-specific)
Check `~/.claude/playbook-standards/` for YAML files. If present, merge them on top
of the baseline. These typically add:
- Jira/ServiceNow ticket field requirements
- Approval workflow steps (e.g., change advisory board sign-off)
- Naming conventions (e.g., `PB-{TEAM}-{SEQ}`)
- Required sections beyond the baseline (e.g., security impact assessment)
- Template headers/footers with company branding

To install org standards: copy the client's YAML into `~/.claude/playbook-standards/`.
Use `schemas/org-standard-template.yaml` as a starting point.

### 3. Inline Overrides
The user can specify one-off exceptions in their prompt. These are documented in the
playbook as "Deviations from Standard" with justification.

## Playbook Generation Workflow

1. **Identify the domain** — what system/process is this playbook for?
2. **Load standards** — baseline + any org overrides
3. **Gather inputs** — ask the user for:
   - Target system/service
   - Trigger condition (when does someone reach for this playbook?)
   - Key decision points
   - Known failure modes
4. **Generate the playbook** following the merged standard
5. **Validate conformance** — check all required sections and fields are present
6. **Output** — as Markdown by default, or as a `.docx` if the user asks

## Output Format

Default output is a Markdown file with this structure:

```markdown
# PB-{TEAM}-{SEQ}: {Title}

| Field | Value |
|-------|-------|
| Author | {name} |
| Version | 1.0 |
| Last Reviewed | {date} |
| Approval | Draft / Approved |
| Jira Ticket | {if org standard requires it} |

## Purpose
{Why this playbook exists}

## Scope
{What systems/services this covers}

## Prerequisites
- {List of things that must be true before starting}

## Procedure

### Step 1: {Action}
- **Action**: {Imperative verb description}
- **Role**: {Who performs this}
- **Expected Outcome**: {What success looks like}
- **If Failed**: {What to do if this step fails}

### Step 2: ...

## Rollback Procedure
{Steps to undo everything}

## Verification
{How to confirm the playbook achieved its goal}

## Deviations from Standard
{Any inline overrides, with justification — or "None"}
```

## Defining New Standards

To create a new org standard:

1. Copy `schemas/org-standard-template.yaml` to `~/.claude/playbook-standards/{client-name}.yaml`
2. Edit the YAML to add client-specific requirements
3. The generator will auto-detect and merge it on next run

## Schemas

- `schemas/baseline-standard.yaml` — the default conformance standard
- `schemas/org-standard-template.yaml` — template for creating org overrides

## Examples

- `examples/azure-foundry-deployment.md` — a real playbook for deploying to Azure AI Foundry
- `examples/credential-rotation.md` — credential rotation playbook using secret-vault metadata
