# RSS

A lightweight, minimal RSS reader built for self-hosting.

## Features

- Reads RSS and Atom feeds.
- Feeds refresh themselves in the background, each on its own schedule.
- OPML import and export.
- Hide posts you're done with; optionally prune old ones automatically.
- One container, SQLite inside — nothing else to run.

## Self-hosting

```bash
git clone https://github.com/sammcclenaghan/rss && cd rss
cp .env.example .env    # set RAILS_MASTER_KEY
docker compose up -d --build
```

The reader is at `localhost:3000`. The background-jobs dashboard at `/jobs` stays locked unless you set the basic-auth variables in `.env`.
