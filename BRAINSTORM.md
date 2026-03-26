# Skills Brainstorm — Automation Engineer / Consultant

## Built Skills (in this repo)

| # | Skill | Status | Description |
|---|-------|--------|-------------|
| 1 | **secret-vault** | ✅ Built | AES-256-GCM encrypted API key storage with tiered key management |
| 2 | **playbook-generator** | ✅ Built | Standards-conformant playbook/runbook/SOP generation |
| 3 | **cloud-provisioning** | ✅ Built | AWS/Azure/GCP compute credential onboarding |
| 4 | **env-scaffolder** | ✅ Built | Project environment bootstrapping by type |
| 5 | **github** | ✅ Built | Repo creation, push, Actions secrets, CI/CD workflows |
| 6 | **gitlab** | ✅ Built | Project creation, push, CI variables, self-hosted support |

## Future Skill Ideas

### High Priority

- **terraform-runner** — Plan/apply Terraform from Claude with state locking awareness,
  drift detection, and cost estimation before apply
- **ansible-runner** — Execute Ansible playbooks with inventory management, vault
  integration, and dry-run-first workflow
- **incident-commander** — Structured incident response: declare, assign roles,
  track timeline, generate post-mortem from incident log
- **cost-analyzer** — Pull cloud billing data (AWS Cost Explorer, Azure Cost Mgmt,
  GCP Billing) and generate spend reports with anomaly detection

### Medium Priority

- **monitoring-setup** — Bootstrap Prometheus/Grafana, Datadog, or Azure Monitor
  with standard dashboards for compute workloads
- **dns-manager** — Manage DNS records across Cloudflare, Route53, Azure DNS
- **ssl-cert-manager** — Certificate lifecycle: generate CSRs, track expiry, auto-renew
  via Let's Encrypt or cloud CAs
- **backup-validator** — Verify backup integrity, test restore procedures, report on
  backup coverage gaps

### Nice to Have

- **compliance-checker** — Scan infrastructure against CIS benchmarks, SOC2 controls,
  or custom compliance frameworks
- **migration-planner** — Generate migration plans for moving workloads between clouds
  or from on-prem to cloud
- **capacity-planner** — Analyze resource utilization and recommend right-sizing
- **documentation-sync** — Keep README, wiki, and runbooks in sync with actual
  infrastructure state

## Design Principles

1. **Skills compose** — each skill should work standalone but integrate naturally with others
2. **Least privilege** — never request more access than needed
3. **Offline-first** — core functionality works without internet; cloud features are additive
4. **Standards-based** — use existing schemas (JSON Schema, OpenAPI, YAML) over custom formats
5. **Audit trail** — every destructive or sensitive action gets logged
