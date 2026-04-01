# GitLab PAT Setup

## GitLab.com

1. Go to https://gitlab.com/-/user_settings/personal_access_tokens
2. Click **Add new token**
3. Name: `agent-automation`, Expiration: 90 days
4. Scopes: `api`, `write_repository`
5. Click **Create personal access token**
6. ⚠️ **Copy the token NOW — it will not be shown again**
7. Store: `python3 secret-vault/scripts/vault.py set gitlab.token glpat-...`

## Self-Hosted GitLab

Same steps, but at `https://your-instance.com/-/user_settings/personal_access_tokens`

Then also store the host:
```bash
python3 secret-vault/scripts/vault.py set gitlab.host https://your-instance.com
```
