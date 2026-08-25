# KuraSpend

A quiet personal spend tracker as a Rails 8 PWA. One SQLite file, no Redis.

Subscriptions, daily spend, payment-day reminders, and a monthly leftover after salary. Several people can have accounts on the same server. No bank sync. No live exchange rates.

## Local

```bash
bin/setup
bin/dev
```

Open http://127.0.0.1:3000

A `config/master.key` is created by `rails new` and is gitignored. Keep that file. If you cloned this repo and have no key:

```bash
rm -f config/credentials.yml.enc
EDITOR=true bin/rails credentials:edit
```

That writes a new `config/master.key`. Do not commit it.

## VPS (Docker Compose)

On the server, with Docker installed:

```bash
git clone https://github.com/aquaspy/KuraSpend.git
cd KuraSpend
cp .env.example .env
```

Edit `.env`. At minimum set:

```bash
SECRET_KEY_BASE=$(openssl rand -hex 64)   # paste the output into .env
KURA_HOST=spend.example.com
SIGNUP_ENABLED=true                       # first account, then false
FORCE_SSL=false                           # true once Caddy/nginx terminates HTTPS
BIND=127.0.0.1:3004                       # 3004 if Notes/Chat/Home/Calendar already took 3000–3003
```

Then:

```bash
docker compose up -d --build
```

Create the first account in the browser (http://127.0.0.1:3004), **or** from the shell:

```bash
docker compose exec web bin/rails kura:create EMAIL=you@x.com PASSWORD='at-least-8'
```

Lock signup:

```bash
# in .env
SIGNUP_ENABLED=false
docker compose up -d
```

`docker compose restart` does **not** reload `.env`. Use `up -d`.

### Secret

Pick **one**. You do not need both.

**Compose (recommended on a VPS):**

```bash
openssl rand -hex 64
```

Put the output in `.env` as `SECRET_KEY_BASE`. No `master.key` required.

**Rails credentials** (if you already have a key, or want `rails credentials:edit`):

```bash
rm -f config/credentials.yml.enc
EDITOR=true bin/rails credentials:edit
cat config/master.key
```

Put that value in `.env` as `RAILS_MASTER_KEY`. A random hex will not decrypt the `credentials.yml.enc` that ships in git — generate a new pair as above, or use `SECRET_KEY_BASE` instead.

Losing the key does not lose spend data. It only invalidates session cookies. Generate a new one and users sign in again.

### Users on the server

```bash
docker compose exec web bin/rails kura:users
docker compose exec web bin/rails kura:create EMAIL=you@x.com PASSWORD='at-least-8'
docker compose exec web bin/rails kura:password EMAIL=you@x.com PASSWORD='new-secret'
```

`kura:password` is the admin reset. There is no email recovery.

### Proxy (Caddy or nginx)

Nothing is bundled. The app listens on `127.0.0.1:3004` (or whatever you set in `BIND`) and does not bind 80/443. Point your own Caddy or nginx at that address, set `FORCE_SSL=true` in `.env`, then `docker compose up -d`.

Caddy:

```
spend.example.com {
  reverse_proxy 127.0.0.1:3004
}
```

nginx:

```
location / {
  proxy_pass http://127.0.0.1:3004;
  proxy_http_version 1.1;
  proxy_set_header Host $host;
  proxy_set_header X-Forwarded-Proto $scheme;
}
```

If `BIND` is another port, proxy to that port instead.

### Backup

Spend data lives in the `kura_spend_data` volume (`storage/production.sqlite3`). Back that up.

```bash
docker compose exec web tar -C /rails/storage -cf - . > kuraspend-backup.tar
```

Offline, the PWA can reopen months you already opened while online. Adding or editing waits until you are back. Sign out wipes the cache so a second person on the same browser cannot read the previous user’s spend offline.

Shared browsers: Sign out **and** wait for the cache wipe.

Export downloads a JSON file of subscriptions, payment days, and expenses. Import accepts that same JSON. It does not replace existing rows; it adds them. It does not overwrite salary or rates.

Money is stored as integer cents. Totals use the home currency you pick (BRL, USD, or EUR) and the exchange rates you type. There is no live quote. A missing rate leaves that row out of leftover instead of pretending 1:1.

Past months: daily expenses are exact (they have a date). Subscriptions use the **current** standing amounts — if a price changed, an old month viewed today uses the new price.

Payment days are reminders of a day of the month (water, electricity, card). They do not change leftover. Log the amount as an expense when you pay.

## Keys

| Env | What |
| --- | --- |
| `SECRET_KEY_BASE` | Session cookies (Compose). `openssl rand -hex 64` |
| `SIGNUP_ENABLED` | Public signup form. Turn off after the first account |
| `FORCE_SSL` | `true` when Caddy/nginx terminates HTTPS |
| `KURA_HOST` | Public hostname |
| `BIND` | Default `127.0.0.1:3004` |
