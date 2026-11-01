# AST2 Backend (Hostinger PHP)

This directory will contain the PHP 8+ REST API for the Telegram Mini App.

## Deployment target
Upload this backend to a folder outside the public web root where possible, and expose only the API entry point through the configured web server. If the Hostinger plan requires files under `public_html`, keep secrets in a private file outside `public_html` and deny direct access to internal folders.

## Required private configuration
Configure these values in Hostinger (never commit real values):
- `DB_HOST`
- `DB_NAME`
- `DB_USER`
- `DB_PASS`
- `TELEGRAM_BOT_TOKEN`
- `TON_PROVIDER_URL` and provider API key, if required
- `AST2_JETTON_MASTER`

## Planned endpoints
See [technical architecture](../docs/AST2_TECHNICAL_PLAN.md).

## Security
- Validate Telegram Mini App initData server-side.
- Use PDO prepared statements.
- Require HTTPS.
- Never trust browser-submitted Telegram IDs, balances, reward values, spin outcomes or admin roles.
- Do not store private keys or seed phrases.
- Keep secrets outside the public repository.
