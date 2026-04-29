# Competitor Notes — fxpreflight Research

## Research Date

2026-04-29

---

## txAdmin

**What it is:** The de-facto FiveM server management panel, now bundled with
FXServer. Open source, actively maintained by the FiveM team.

**What it already validates:**
- Confirms FXServer can read and parse `server.cfg` at startup.
- Reports resources that fail to load in the web dashboard.
- Checks for outdated FXServer artifacts and prompts for updates.
- Surfaces runtime errors and resource crash events in a live feed.

**What it does NOT do:**
- Does not perform pre-start static analysis of `fxmanifest.lua` files before
  the server boots.
- Does not flag deprecated `__resource.lua` files before startup.
- Does not cross-reference `ensure` / `start` directives against the filesystem
  to check that the resource folder exists before the server attempts to load it.
- Does not validate `sv_licenseKey` format offline.
- Does not warn about ACE groups with no principals assigned.

**Conclusion:** txAdmin is a runtime tool with some passive config reading. It
is complementary to fxpreflight, not a replacement.

---

## PerformanceSentry

**What it is:** A paid FiveM resource that monitors server performance at
runtime — tick rates, resource memory usage, script execution time.

**Space it owns:** "Is my server healthy while it is running?" It is squarely
in the runtime diagnostics category.

**What it does NOT do:** Does not inspect config files. Does not run before
the server starts. Has no concept of rules applied to `server.cfg` or
`fxmanifest.lua` content.

**Conclusion:** Different problem space entirely. No overlap with fxpreflight.

---

## DF_Logs

**What it is:** A logging and event-capture resource for FiveM servers.
Currently in preview / early access as of research date.

**Space it owns:** Runtime event logging — player actions, resource events,
server-side triggers. Intended for server administrators who need an audit trail
of in-game events.

**Overlap with fxpreflight:** None. DF_Logs operates after the server is
running; fxpreflight operates before it starts.

---

## Agency Reports V2

**What it is:** An in-game report management system — players submit reports,
staff review and act on them inside the game.

**Space it owns:** Community moderation and player-facing admin workflows.

**Overlap with fxpreflight:** None. Adjacent to server administration only in
the loosest sense.

---

## The Empty Space We Are Entering

No tool in the FiveM ecosystem currently does all of the following together:
reads `server.cfg` and `fxmanifest.lua` files statically (without a running
server), applies a documented rule set, and emits a structured severity-grouped
report. The offline, file-level, pre-start validation niche is unoccupied.
fxpreflight enters that space with no direct competitor.
