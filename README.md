# KuraSpend

**Know what is left after the month — without linking your bank.**

KuraSpend is a quiet personal spend tracker PWA. Subscriptions, daily expenses, payment-day reminders, and a monthly leftover after salary. Several people can have accounts on the same server. One SQLite file. No Redis. No bank sync. No live exchange rates pretending to be truth.

---

## Philosophy

Money apps usually want two things: deep access to your accounts, and a graph that makes you feel managed. KuraSpend wants neither.

- **You type what matters.** Salary, rates, subscriptions, what you spent today. The numbers are yours because you entered them — not because a scraper guessed.
- **Leftover is the point.** After standing subscriptions and daily spend, how much air is left this month? That question should not require OAuth with five banks.
- **Currencies without cosplay.** Money is stored as integer cents. Totals use the home currency you pick (BRL, USD, or EUR) and the exchange rates **you** type. A missing rate leaves that row out of leftover instead of pretending 1:1.
- **Reminders are not expenses.** Payment days (water, electricity, card) mark a day of the month. They do not change leftover until you log the amount when you actually pay.
- **Past months stay honest.** Daily expenses are exact (they have a date). Subscriptions use the **current** standing amounts — if a price changed, an old month viewed today uses the new price. No fake historical rewrite.
- **Same Kura calm.** Auth, idle lock, PWA, Compose on localhost. Finance data as a file you can back up.

Sister apps: [KuraNotes](https://github.com/aquaspy/KuraNotes), [KuraChat](https://github.com/aquaspy/KuraChat), [KuraHome](https://github.com/aquaspy/KuraHome), [KuraCalendar](https://github.com/aquaspy/KuraCalendar). Separate volume on purpose — spend data should not sit next to chat transcripts in one SQLite file.

---

## What you get

- Multi-user accounts on one instance
- Subscriptions, daily expenses, payment-day reminders
- Monthly leftover after salary (home currency + your rates)
- JSON export / import (import adds; it does not overwrite salary or rates)
- Offline: reopen months you already opened; edits wait until you are back
- Sign-out wipes the offline cache

---

## Self-host (Docker Compose)

```bash
git clone https://github.com/aquaspy/KuraSpend.git
cd KuraSpend
cp .env.example .env
```

Edit `.env`. At minimum:

```bash
SECRET_KEY_BASE=          # paste: openssl rand -hex 64
KURA_HOST=spend.example.com
SIGNUP_ENABLED=true       # first account, then false
FORCE_SSL=false           # true once HTTPS terminates in front
BIND=127.0.0.1:3004       # 3004 if Notes/Chat/Home/Calendar already took 3000–3003
```

Then:

```bash
docker compose up -d --build
```

Create the first account in the browser (`http://127.0.0.1:3004`), or:

```bash
docker compose exec web bin/rails kura:create EMAIL=you@example.com PASSWORD='at-least-8'
```

Lock signup:

```bash
# in .env
SIGNUP_ENABLED=false
docker compose up -d
```

> **Important:** `docker compose restart` does **not** reload `.env`. Use `docker compose up -d`.

### Secrets

Pick **one**. You do not need both.

| Approach | When | How |
| --- | --- | --- |
| **`SECRET_KEY_BASE`** (recommended) | Compose / VPS | `openssl rand -hex 64` → `.env` |
| **`RAILS_MASTER_KEY`** | Rails credentials | Regenerate with `EDITOR=true bin/rails credentials:edit`, put `config/master.key` in `.env` |

Losing the key does not lose spend data — only session cookies.

### Reverse proxy (Caddy or nginx)

Nothing is bundled. Point your proxy at `BIND`, set `FORCE_SSL=true`, then `docker compose up -d`.

**Caddy:**

```
spend.example.com {
  reverse_proxy 127.0.0.1:3004
}
```

**nginx:**

```
location / {
  proxy_pass http://127.0.0.1:3004;
  proxy_http_version 1.1;
  proxy_set_header Host $host;
  proxy_set_header X-Forwarded-Proto $scheme;
}
```

If `BIND` is another port, proxy to that port instead.

### Users on the server

No email recovery:

```bash
docker compose exec web bin/rails kura:users
docker compose exec web bin/rails kura:create EMAIL=you@example.com PASSWORD='at-least-8'
docker compose exec web bin/rails kura:password EMAIL=you@example.com PASSWORD='new-secret'
```

### Backup

Spend data lives in the `kura_spend_data` volume (`storage/production.sqlite3`).

```bash
docker compose exec web tar -C /rails/storage -cf - . > kuraspend-backup.tar
```

### Shared browsers

Sign out **and** wait for the cache wipe.

---

## Import / export

**Export** downloads JSON of subscriptions, payment days, and expenses.

**Import** accepts that same JSON. It **adds** rows; it does not replace existing ones, and it does **not** overwrite salary or rates.

---

## How money works (short)

| Idea | Behavior |
| --- | --- |
| Storage | Integer cents |
| Home currency | BRL, USD, or EUR — you pick |
| Exchange rates | You type them; no live quote |
| Missing rate | That row is left out of leftover (not assumed 1:1) |
| Payment days | Reminders only — log an expense when you pay |
| Past months | Expenses are dated; subscriptions use **current** amounts |

---

## Local development

```bash
bin/setup
bin/dev
```

Open http://127.0.0.1:3000

If you cloned without a `master.key`:

```bash
rm -f config/credentials.yml.enc
EDITOR=true bin/rails credentials:edit
```

Do not commit `config/master.key`.

---

## Environment

| Variable | What it does |
| --- | --- |
| `SECRET_KEY_BASE` | Session cookies (Compose). `openssl rand -hex 64` |
| `SIGNUP_ENABLED` | Public signup. Turn off after the first account |
| `FORCE_SSL` | `true` when Caddy/nginx terminates HTTPS |
| `KURA_HOST` | Public hostname |
| `BIND` | Default `127.0.0.1:3004` |

---

## Sister apps

| App | Role |
| --- | --- |
| [KuraNotes](https://github.com/aquaspy/KuraNotes) | Private notes |
| [KuraChat](https://github.com/aquaspy/KuraChat) | Private chat with Grok |
| [KuraHome](https://github.com/aquaspy/KuraHome) | Quiet start-page / homepage |
| [KuraCalendar](https://github.com/aquaspy/KuraCalendar) | Personal calendar & birthdays |
