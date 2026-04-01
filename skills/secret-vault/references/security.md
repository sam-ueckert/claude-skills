# Security Considerations

- The vault file (`vault.enc`) is safe to commit to version control (it's encrypted),
  but `.vault-meta` should be gitignored if it contains a passphrase salt you want private
- Never log or print secret values — the audit log records key names and operations only
- The `get` command outputs to stdout; pipe carefully
- Rotation does not propagate to cloud providers — use cloud-provisioning for that
