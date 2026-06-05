---
name: sku-setup
description: Configure .env for local development against the docker mariadb. Sets APP_ENV=local, DB_HOST=127.0.0.1, DB_PORT=3307, DB_USERNAME=root, DB_PASSWORD=root, and DB_DATABASE to the database name passed as an argument.
argument-hint: <database-name>
disable-model-invocation: true
---

# sku-setup

Updates `.env` in the project root to point Laravel at the docker mariadb container with the database name the user supplied.

The argument is `$ARGUMENTS` — treat the whole string as the database name. If it is empty, ask the user which database to use and stop.

## Steps

### 1. Read `.env`
Read the current `.env` file at the project root.

### 2. Apply these exact key=value updates
Use the `Edit` tool. For each key below, replace the existing line in `.env`:

- `APP_ENV=local`
- `DB_CONNECTION=mysql`
- `DB_HOST=127.0.0.1`
- `DB_PORT=3307`
- `DB_DATABASE=$ARGUMENTS`
- `DB_USERNAME=root`
- `DB_PASSWORD=root`

Also mirror the database/host/port/credentials into the `LARAVEL_LOAD_*` keys if they exist:

- `LARAVEL_LOAD_HOST=127.0.0.1`
- `LARAVEL_LOAD_DATABASE=$ARGUMENTS`
- `LARAVEL_LOAD_USER=root`
- `LARAVEL_LOAD_PASSWORD=root`

Rules:
- Only update keys that already exist — do NOT append new keys
- If a key is missing, mention it in the summary but do not invent it
- Preserve all other lines in `.env` untouched

### 3. Verify
After editing, grep the updated values back and show them in the summary:

```bash
grep -nE "^(APP_ENV|DB_|LARAVEL_LOAD_)" .env
```

### 4. Summary
Show:
- The database name now configured
- The grep output above so the user can confirm
- A one-line reminder: "Run `php artisan migrate` if `$ARGUMENTS` is a fresh database."

Do NOT run migrations, do NOT create the database, do NOT restart anything — just edit `.env`.
