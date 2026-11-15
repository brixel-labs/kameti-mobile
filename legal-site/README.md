# Kameti Legal & Support Site

Standalone static site for Kameti's legal, support and invite pages. Plain HTML/CSS, no build
step, no dependencies, the same setup as the Deenflow legal site. It is its own Vercel project,
separate from the app and from the company site (`fhbtechservices.com`).

Production domain: `kameti.fhbtechservices.com`.

Vercel project `kameti-site`: Root Directory `legal-site`, preset Other, production branch
`develop`. Every push to `develop` that touches this folder redeploys it.

## Pages

- `/` — landing page linking to the pages below
- `/privacy` — Privacy Policy
- `/terms` — Terms of Service
- `/support` — help and contact (kameti@fhbtechservices.com)
- `/delete-account` — how account deletion works (Google Play requires this URL)
- `/join/<token>` — where invite links land in a browser. Every `/join/*` path serves the same
  static page (see `vercel.json`); it never reads the token, loads nothing, shows no kameti
  details, and is `noindex` with `no-referrer`
- `/v/<token>` — a guest's private view-only page (a member who doesn't use the app). Every `/v/*` path
  serves the same static page (see `vercel.json`); it reads the token from the URL and calls the
  Supabase RPC `get_guest_view` with the public publishable key. It shows only that member's own
  figures and the payout schedule, and is `noindex` with `no-referrer`. The owner copies the link
  from the member sheet; turning it off deletes the token. On localhost it talks to the local
  Supabase and also accepts `/v/index.html?t=<token>`
- `/.well-known/apple-app-site-association` — opens `/join/*` links in the iOS app
  (`77XZANJHWG.com.brixel.kameti`), served as `application/json`
- `/.well-known/assetlinks.json` — opens `/join/*` links in the Android app (lists the app's signing fingerprints; add the release one from Play Console before launch)
- `/robots.txt` — keeps crawlers out of `/join/`

## Local preview

```bash
npx serve legal-site
```
(`serve` doesn't apply `vercel.json`, so `/join/<token>` 404s locally; `/join` works.)

## Maintaining this site

Update the "Last updated" date in `privacy/index.html` and `terms/index.html` whenever their
content changes, and keep them in line with what the app really does (see `docs/REQUIREMENTS.md`).
Never put member data or internal documents here: everything on this site is public. (`/v` ships no data; it fetches the guest's own figures at view time with their token.)
