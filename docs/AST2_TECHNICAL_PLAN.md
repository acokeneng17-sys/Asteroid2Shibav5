# AST2 Mining — Technical Architecture (v2)

## Confirmed product decisions
- Telegram Mini App for Asteroid2Shiba (AST2).
- Space/futuristic visual theme.
- TON Mainnet wallet holding is checked live; snapshots are retained for audit/history.
- Reward reserve ceiling: 500,000,000 AST2. This is a budget ceiling, not a user balance or an instruction to distribute immediately.
- Withdrawals require admin review and an on-chain transfer performed by an authorized operator.
- Admin panel is inside the Mini App and is visible only to Telegram IDs present in `admin_users`.
- New level/reward schedule is configurable in the database. Exact thresholds and rewards remain unset until approved.

## Repository and deployment
- Repository: `acokeneng17-sys/Asteroid2Shibav5`.
- Development branch: `ast2-v2-foundation`.
- Preserve the existing root `index.html`; it is a large existing app and must not be replaced during foundation work.
- `preview/index.html` is a visual-only mockup, not connected to Telegram, TON, or the database.
- `database/schema.sql` is the initial MySQL schema.
- Backend target: PHP 8+ API on Hostinger hPanel with MySQL. Confirm the actual hosting PHP version and document root before deployment.
- Frontend is served over HTTPS and opened by the Telegram bot as a Mini App.

## Proposed request flow
1. Telegram opens the Mini App and supplies `Telegram.WebApp.initData`.
2. Frontend sends the raw initData to the backend over HTTPS.
3. Backend validates Telegram Web App initData signature and freshness using the correct bot token stored only in hosting environment/config outside the public repository.
4. Backend resolves the Telegram user and admin role from MySQL.
5. Backend obtains AST2 Jetton balance from a TON Mainnet data provider, validates the configured Jetton master, and records a timestamped holding snapshot.
6. Backend calculates the highest enabled level whose holding threshold is met, then applies the configured reward rules.
7. Daily actions use server-side date/time and unique database constraints to prevent duplicate claims.
8. Withdrawal requests are queued; admin reviews them. Transfers are signed only by a separately secured operator wallet/process. Never put a seed phrase or private key in GitHub or frontend code.

## AST2 token reference
- Network: TON Mainnet.
- Jetton master: `EQCO-aQDxDMY80yRMlSGlQN_ecJFV0sdA8U7RWTXbA0vufNx`.
- Before production, verify the master address, token decimals, and provider response against a trusted TON explorer/provider. Do not assume token decimals.

## Core API routes (planned)
- `GET /api/health` — service health, no secrets.
- `POST /api/auth/telegram` — validate initData and issue app session.
- `GET /api/me` — profile, wallet, holding, level and points.
- `POST /api/wallet/verify` — verify wallet ownership and AST2 holding.
- `POST /api/mining/claim` — claim eligible mining reward once per period.
- `POST /api/checkin/claim` — daily check-in.
- `POST /api/spin/play` — daily spin with server-side outcome.
- `GET /api/tasks`, `POST /api/tasks/{id}/complete` — social tasks.
- `GET /api/referrals` — referral summary.
- `POST /api/withdrawals`, `GET /api/withdrawals` — user withdrawal requests/history.
- `GET/POST /api/admin/*` — admin-only settings, tasks, users, allocations and withdrawal review.

## Security requirements
- Never trust Telegram user ID, wallet balance, reward amount, spin result, referral owner, or admin status supplied by the browser.
- Validate Telegram initData on the server using the correct bot token. Store token in Hostinger environment variables or a private config file outside the public web root.
- Use prepared SQL statements, HTTPS, CSRF/session protections as appropriate, rate limits, and server-side validation.
- Keep API provider keys and any transaction-signing material out of GitHub.
- Do not store seed phrases or private keys in the database.
- Use database transactions and unique constraints for all reward claims.
- Record admin actions and withdrawal transaction hashes.
- A 500 million AST2 ceiling must be enforced with atomic accounting; no reward can exceed the remaining reserve.

## Open decisions before production
1. Approve the full 500-level holding thresholds and reward schedule.
2. Confirm AST2 Jetton decimals and select the TON data provider/API key.
3. Set the Telegram bot username/token in Hostinger privately; do not paste the token into GitHub or chat.
4. Supply the Telegram numeric ID(s) authorized as admin.
5. Set minimum withdrawal, fee policy, claim timing, and social-task verification rules.
6. Confirm Hostinger supports the required PHP version, HTTPS, cron (if needed), and outbound HTTPS requests.

## Build phases
1. Foundation: schema, safe repository structure, static UI preview.
2. Backend: Telegram authentication, database connection, health/profile endpoints.
3. TON: wallet ownership and live Jetton balance verification plus snapshots.
4. Rewards: configurable levels, mining, check-in, spin, tasks, referrals and allocation accounting.
5. Admin and withdrawals: review workflow, audit log and transaction tracking.
6. Testing, deployment and Telegram bot configuration.
