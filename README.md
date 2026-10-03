# TEAM UNSTOPPABLE

Original mobile-first DJ collective website. Official domain target: **1teamunstoppable.com**. No DNS or production publication is performed by this repository.

## Run the preview

Requires Node.js 24 or later. No third-party dependencies.

```sh
npm start
```

Open http://127.0.0.1:4173. The site includes responsive navigation, an original turntable illustration, team profiles, events, music, videos/gallery tabs, merch, a persistent High Life Radio player, a booking form, moderated chat and a private control center at `/admin`.

The roster and all content collections start empty intentionally. No fictional members, dates, recordings, images, inventory or checkout are represented as real. Publish approved records from the control center to populate the corresponding section. Media cards link to approved external media. Merchandise links to an approved hosted checkout; no payment details are collected here.

## High Life Radio

`public/station.json` reuses the exact stream and now-playing endpoints from `drammawayne-cloud/highlife-radio` (station configuration SHA `4579c973f1cae76d746231f4f3af75015171cbf2`). The player adapts that project's click-to-play, volume, buffering/error and stale metadata behavior. One audio element stays mounted during navigation and chat. Source: https://github.com/drammawayne-cloud/highlife-radio

Stream availability and metadata depend on the radio service. An online metadata flag is not proof of audible playback. Browsers require a user gesture before playing audio.

## Private architecture

- SQLite data and server-side sessions live outside the public directory in `DATA_DIR` (default `data/`, ignored by Git).
- Management API rejects unauthenticated requests. A strong password is configured only on the server; scrypt and timing-safe comparison verify it.
- Sessions expire after eight hours, use HttpOnly/SameSite=Strict cookies, and Secure cookies in production. Sign-out invalidates the session.
- POST requests require an exact matching Origin and JSON content type. Request size and per-address rates are limited; login has a tighter limit.
- Bookings remain private and cannot be published. Chat is moderated before public display. HTML is rendered with textContent, never untrusted HTML.
- Production refuses to start without a password of at least 16 characters and HTTPS PUBLIC_ORIGIN.
- Admin page source is public, as with any login page; its data and actions require authorization. This first version has one team credential. Use separate staff identities, MFA and a managed identity provider before granting access to multiple staff.
- Back up the persistent SQLite database; do not host this as a static GitHub Pages site if using bookings/admin/chat. The app does not send email notifications; staff review the inbox.

## Deploy after reviewing the preview

Use a Node 24 web service (Render or equivalent): start `npm start`, set `HOST=0.0.0.0`, `NODE_ENV=production`, a unique strong `ADMIN_PASSWORD`, and `PUBLIC_ORIGIN` to the actual HTTPS preview origin. Attach a persistent disk and set `DATA_DIR` inside it. Set health check `/`. For a preview hostname use that exact origin; later set `PUBLIC_ORIGIN=https://1teamunstoppable.com` after the custom domain and TLS are working. Configure DNS using the provider's verified instructions. No domain purchase, DNS modification or live deployment has been done.

This app deliberately ships no default credential. For a local private-management test, set a temporary ADMIN_PASSWORD and PUBLIC_ORIGIN=http://127.0.0.1:4173 in the launch environment. Do not use that temporary password in production.

## Checks

```sh
npm run check
npm test
```

The integration suite runs with an isolated temporary database and tests authentication, cross-origin rejection, private booking isolation, moderation, publishing and logout. Content and branding are original; the Heavy Hitter DJs reference informed talent-first navigation and the collective/radio/event structure only. No proprietary assets or copy are used.

## Cloudflare deployment

The full site also runs on Cloudflare Workers using `cloudflare/worker.js`, the existing public assets, and D1 persistent storage. `wrangler.jsonc` identifies the account and database; it contains no secrets. The Node preview remains available independently.

Worker URL: https://team-unstoppable.dwaynev347.workers.dev
Official domain: https://1teamunstoppable.com

Commands for future updates (authenticated Wrangler required):

```sh
npx wrangler@4.147.0 d1 migrations apply DB --remote
npx wrangler@4.147.0 deploy
```

Set `ADMIN_PASSWORD` as a Cloudflare Worker secret with at least 16 characters through the Cloudflare dashboard. Until that owner setup is completed, sign-in returns an unavailable response and management remains closed. Never store the password in Git. Worker sessions store only a SHA-256 digest of the random session token in D1. Online password comparison uses fixed-length digests and durable rate limits; the password itself is stored only as a Worker secret. Bookings remain private and chat remains moderated. D1 rate limiting is persistent across Worker instances. A daily scheduled task cleans expired sessions and rate-limit rows.

Cloudflare tests use a real isolated SQLite database behind a D1-compatible adapter to verify API privacy, moderation, authentication, logout, security headers, and persistent rate limits. `npm test` covers both runtimes.

Management sign-in also checks the configured `ADMIN_EMAIL` when present. Set it privately through Cloudflare secrets; it is not displayed on the public website. The password remains required and is never inferred from the email address.
