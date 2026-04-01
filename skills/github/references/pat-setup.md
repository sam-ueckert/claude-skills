# GitHub PAT Setup

If no token is configured, walk the user through:

1. Go to https://github.com/settings/tokens?type=beta (Fine-grained tokens)
2. Click **Generate new token**
3. Set token name: `agent-automation`
4. Set expiration: 90 days (recommend rotation via playbook-generator)
5. Under **Repository access**: select "All repositories" or specific repos
6. Under **Permissions → Repository permissions**:
   - Contents: Read & Write
   - Administration: Read & Write
   - Secrets: Read & Write
   - Workflows: Read & Write
   - Metadata: Read-only (auto-granted)
7. Click **Generate token**
8. ⚠️ **Copy the token NOW — it will not be shown again**
9. Store it: `python3 secret-vault/scripts/vault.py set github.pat ghp_...`
