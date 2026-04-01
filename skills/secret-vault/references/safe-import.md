# Adding Secrets Without Exposing Them to the AI Agent

Anything typed in the agent chat or passed as a command argument through the agent is sent to
the LLM provider's API. To add secrets safely, use the **file import** workflow — the agent only
sees the filename, never the file contents.

## Step-by-step

1. **Create a secrets file in your editor or terminal** (not through the agent):

   `.env` format:
   ```
   # secrets.env
   github.token=ghp_xxxxxxxxxxxx
   aws.access_key_id=AKIA...
   aws.secret_access_key=wJalr...
   ```

   Or JSON format:
   ```json
   {
     "github.token": "ghp_xxxxxxxxxxxx",
     "aws.access_key_id": "AKIA...",
     "aws.secret_access_key": "wJalr..."
   }
   ```

2. **Ask the agent to import the file:**

   > "import secrets from secrets.env into the vault"

   The agent runs:
   ```bash
   python3 scripts/vault.py import secrets.env
   ```

3. **The file is automatically shredded** — overwritten with random bytes, then deleted.
   Use `--keep` if you want to preserve it.

## What stays private

| Step | Who sees it | Sent to LLM? |
|------|------------|---------------|
| You write `secrets.env` | You only | No |
| Agent runs `vault.py import secrets.env` | Agent sees the filename | Filename only |
| `vault.py` reads and encrypts the file | Local Python process | No |
| File is overwritten + deleted | Nobody | No |
| Secrets stored in `vault.enc` | Encrypted on disk | No |
| `vault.py get <key>` at runtime | Local process / stdout | No (unless piped into chat) |

## Other safe alternatives

- **Run `vault.py set` yourself** in a separate terminal — not through the agent
- **Use `vault.py init --keychain`** and the OS keychain for the master key
- **Never ask the agent to read or cat a secrets file** — that sends the contents to the API
