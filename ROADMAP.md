# Roadmap

## v1 — Lua FiveM Resource Preflight Validator [ACTIVE]

A pure-Lua FiveM resource. When FXServer starts, fxpreflight reads `server.cfg`
and every `fxmanifest.lua` under `resources/`, applies a set of static rules
(R001–R015), prints severity-prefixed findings to the FXServer console, and
writes a `fxpreflight_report.md` next to `server.cfg`. An optional Discord
webhook delivers the report off-server. The rule engine lives in `shared/` and
is unit-tested using a standalone Lua 5.4 interpreter against fixture files, so
no FXServer runtime is needed during development. The resource is distributed
via Tebex escrow: buyers drop the folder into `resources/[tools]/fxpreflight/`,
add `ensure fxpreflight` to `server.cfg`, and restart. This is the phase
currently in development.

## v1.5 — NUI Report Viewer [FUTURE]

Add a web-panel UI (NUI) inside fxpreflight that lets server owners browse
findings interactively without opening the Markdown file. The report data
produced by v1 is reused; only the presentation layer changes. Requires a
stable local FXServer runtime for integration testing and is postponed until
that is available.

## v2 — ACE Permission Debugger [FUTURE]

Extend fxpreflight with a dedicated ACE analysis module. Surface inheritance
chains, detect circular grants, flag unreachable permissions, and cross-
reference `add_ace` / `add_principal` directives against the resources that
actually call `IsPlayerAceAllowed`. The new module is added to the same
resource rather than shipped separately, keeping the buyer experience simple.

## v3 — Live Watch Mode / Runtime Hitch Detection [FUTURE]

Add a persistent watch loop that monitors `server.cfg` and `fxmanifest.lua`
files for changes while FXServer is running and re-runs affected rules
automatically. Explore lightweight runtime hitch detection — flagging resources
whose tick execution time consistently exceeds a threshold — complementing the
static analysis already provided. Requires a stable local FXServer for
meaningful end-to-end testing.

## v4 — Cloud SaaS for Multi-Server Owners [FUTURE]

A hosted web service where multi-server operators can register server folders
(or upload config snapshots), run preflight checks on demand or on a schedule,
and receive diff-based reports when configurations drift. Includes a dashboard,
notification hooks (Discord, webhook), and a rule editor for custom rules.
Monetization model to be decided closer to this phase.
