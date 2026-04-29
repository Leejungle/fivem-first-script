# fxpreflight

A FiveM server-side resource that validates your server configuration at startup and reports problems before they waste your time.

**Status:** Alpha — not yet shipped.

## What v1 does

- Parses `server.cfg` and reports configuration errors: missing endpoints, malformed license keys, default hostnames, and more.
- Walks every `fxmanifest.lua` under `resources/` and applies a set of static rules (R001–R015).
- Writes a `fxpreflight_report.md` next to your `server.cfg` and prints severity-prefixed findings to the FXServer console.

## What v1 does NOT do

- It does not validate framework-specific configuration (ESX, QBCore, QBOX, etc.).
- It does not auto-fix anything — it reports problems, it does not modify files.
- It does not include a web panel or in-game UI; all output is console and Markdown file only.

## How to install

1. Drop the `fxpreflight/` folder into `resources/[tools]/fxpreflight/`.
2. Add `ensure fxpreflight` to your `server.cfg`.
3. Restart FXServer. The validator runs once at startup and writes its report.

## Tech stack

Pure Lua 5.4. Distributed as a standard FiveM resource — no Node.js, no npm, no external runtime required.

## Follow along

- [ROADMAP.md](ROADMAP.md) — planned phases from v1 resource to cloud SaaS.
- [IDEA_1.md](IDEA_1.md) — the full product dossier for this idea.
