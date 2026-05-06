# Changelog

All notable changes to fxpreflight are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-05-06

First public release. Boot-time linter for FiveM `server.cfg` and `fxmanifest.lua` files.

### Added

- **server.cfg ingestion** via a boot-time snapshot file (`server.cfg.runtime`)
  created by `start.bat`. Required because FiveM's server-side `io.open` is
  sandboxed and cannot reach files outside the resource folder.
- **fxmanifest scanning** across every loaded resource using FiveM natives
  (`GetNumResources`, `GetResourceByFindIndex`, `LoadResourceFile`). Both
  modern `fxmanifest.lua` and legacy `__resource.lua` are supported.
- **Cfx default whitelist** -- 26 first-party resources shipped by Cfx
  (chat, mapmanager, fivem, monitor, webpack, sessionmanager*, ...) are
  skipped automatically so the report focuses on user-installed code.
- **15 rules** (12 active, 3 stubs):
  - **CRITICAL**: R001 (missing `endpoint_add_tcp/udp`), R002 (malformed
    `sv_licenseKey`), R003 (server.cfg < 200 bytes), R008 (missing
    `fx_version` in fxmanifest).
  - **WARNING**: R004 (default `sv_hostname`), R005 (`sv_maxclients` out
    of [1, 2048]), R007 (`steam_webApiKey` empty / `"none"` -- handles
    both direct form and `set steam_webApiKey ""`), R009 (legacy
    `fx_version` such as `adamant`/`bodacious`), R011 (missing `games {}`
    block).
  - **INFO**: R013 (`lua54 'no'` opting out of Lua 5.4).
  - **stubs (planned for v0.2)**: R006 (`onesync` inside cfg with
    txAdmin), R014 (`ensure` pointing to a missing folder), R015
    (orphan `add_ace` without matching `add_principal`).
- **`set / setr / sets` directive unwrapping** in `parser_servercfg`. The
  parser now recognises that `set steam_webApiKey ""` defines the
  `steam_webApiKey` convar (not a directive literally named `set`), so
  R007 fires correctly on real-world cfgs that use the default
  `set`-form syntax.
- **Reporter** -- pure functions: `summarize`, `format_console`,
  `format_markdown`. Findings are sorted CRITICAL > WARNING > INFO,
  then by `rule_id` within a severity, deterministically.
- **Per-run persistence** via `SaveResourceFile`:
  - `fxpreflight_report.md` -- markdown findings, paste-ready for
    Discord/forum,
  - `fxpreflight_run.log` -- verbatim console output of the run,
    useful for debugging.
  Both files are gitignored.
- **`/fxpreflight` console command** (restricted, admin-only) reruns the
  preflight without restarting the resource. Faster than
  `restart fxpreflight` because the script environment is not torn
  down and rebuilt.
- **134-test suite** in `tests/`, runnable under standalone Lua 5.4
  with no external dependencies.

### Required setup outside the resource

Add this line to your `start.bat` BEFORE the `FXServer.exe` line so the
cfg snapshot exists when fxpreflight boots:

```bat
copy /Y server.cfg resources\fxpreflight\server.cfg.runtime > nul
```

(A `start.sh` equivalent for Linux is trivial -- `cp server.cfg
resources/fxpreflight/server.cfg.runtime` -- but is not yet shipped.
Linux support is targeted for v0.1.1.)

### Known limitations

- The `server.cfg.runtime` snapshot is taken once per FXServer boot.
  Editing `server.cfg` and running `/fxpreflight` re-reads the SAME
  snapshot. Restart FXServer to refresh.
- Resources started AFTER fxpreflight will not appear in the scan
  unless the operator runs `/fxpreflight` afterwards. Place
  `ensure fxpreflight` near the bottom of `server.cfg`.
- The Cfx default whitelist is hard-coded for v0.1; v0.2 will allow
  override via `config.lua`.
- Detection only -- fxpreflight does not auto-fix any finding.

[Unreleased]: https://github.com/Leejungle/fivem-first-script/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Leejungle/fivem-first-script/releases/tag/v0.1.0
