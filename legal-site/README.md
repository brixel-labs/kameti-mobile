# Kameti Legal & Support Site

Standalone static site for Kameti's legal, support and invite pages. Plain HTML/CSS, no build
step, no dependencies, the same setup as the Deenflow legal site. It is its own Vercel project,
separate from the app and from the company site (`fhbtechservices.com`).

Production domain: `kameti.fhbtechservices.com`.

## Pages

- `/` — landing page linking to the pages below
- `/privacy` — Privacy Policy
- `/terms` — Terms of Service
- `/support` — help and contact (kameti@fhbtechservices.com)
- `/delete-account` — how account deletion works (Google Play requires this URL)
- `/join/<token>` — where invite links land in a browser. Every `/join/*` path serves the same
  static page (see `vercel.json`); it never reads the token, loads nothing, shows no kameti
  details, and is `noindex` with `no-referrer`
- `/.well-known/apple-app-site-association` — opens `/join/*` links in the iOS app
  (`77XZANJHWG.com.brixel.kameti`), served as `application/json`
- `/robots.txt` — keeps crawlers out of `/join/`

## Local preview

```bash
npx serve legal-site
```
(`serve` doesn't apply `vercel.json`, so `/join/<token>` 404s locally; `/join` works.)

## Maintaining this site

Update the "Last updated" date in `privacy/index.html` and `terms/index.html` whenever their
content changes, and keep them in line with what the app really does (see `docs/REQUIREMENTS.md`).
Never put member data or internal documents here: everything on this site is public.
