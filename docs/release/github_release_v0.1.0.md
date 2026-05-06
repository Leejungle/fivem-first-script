## fxpreflight v0.1.0 — first public release

Boot-time linter for FiveM `server.cfg` and `fxmanifest.lua`.
15 deterministic rules. Zero external dependencies. MIT licensed.

This is the first public release: install it as a FiveM resource,
boot your server, and read a human-readable diagnosis of the most
common configuration mistakes that silently break servers.

---

### Highlights

- **`server.cfg` ingestion** via a boot-time snapshot file
  (`server.cfg.runtime`) created by `start.bat`. Required because
  FiveM's server-side `io.open` is sandboxed and cannot reach files
  outside the resource folder.
- **`fxmanifest.lua` scanning** across every loaded resource using
  FiveM natives (`GetNumResources`, `GetResourceByFindIndex`,
  `LoadResourceFile`). Both modern `fxmanifest.lua` and legacy
  `__resource.lua` are handled.
- **26 first-party Cfx default resources** (chat, mapmanager, fivem,
  monitor, webpack, sessionmanager*, ...) are skipped automatically
  so the report focuses on the resources you actually installed.
- **15 rules** — 12 active in v0.1, 3 stubs reserved for v0.2:
  - **CRITICAL**: R001 (missing `endpoint_add_tcp/udp`), R002
    (malformed `sv_licenseKey`), R003 (`server.cfg` < 200 bytes),
    R008 (`fx_version` missing).
  - **WARNING**: R004 (default `sv_hostname`), R005 (`sv_maxclients`
    out of `[1, 2048]`), R007 (`steam_webApiKey` empty / `"none"`),
    R009 (legacy `fx_version` such as `adamant` / `bodacious`),
    R011 (no `games {}` block).
  - **INFO**: R013 (`lua54 'no'`).
  - **stubs (v0.2)**: R006, R014, R015.
- **Per-run output** written via `SaveResourceFile` to two sibling
  files alongside the resource:
  - `fxpreflight_report.md` — markdown findings, paste-ready.
  - `fxpreflight_run.log`   — verbatim console output, for debugging.
- **`fxpreflight` console command** (admin-only, restricted) reruns
  the preflight without restarting the resource. Faster than
  `restart fxpreflight` because the script environment is not torn
  down and rebuilt.
- **134-test suite** runnable under standalone Lua 5.4 with no
  external dependencies (`lua tests/run.lua`).

### Required setup outside the resource

Add this line to your `start.bat` BEFORE the `FXServer.exe` line:

```bat
copy /Y server.cfg resources\fxpreflight\server.cfg.runtime > nul
```

A `start.sh` equivalent for Linux is one line and is targeted for v0.1.1.

### Quick install

The full install steps (5 minutes) are in the
[README](https://github.com/Leejungle/fivem-first-script/blob/main/README.md#quick-install-5-minutes).
Short version:

1. Download the source zip from this release page (or `git clone`).
2. Extract into `<server-data>/resources/` and rename the folder to
   `fxpreflight`.
3. Add the `start.bat` snapshot copy line above.
4. Add `ensure fxpreflight` near the bottom of `server.cfg`.
5. Boot. Look for `[script:fxpreflight]` lines in the FXServer console.

### Try the demo cfg

`examples/server.cfg.demo` ships an intentionally broken cfg that
trips 5 rules across CRITICAL + WARNING. The verbatim console output
and matching markdown report are committed alongside it -- read
[examples/](https://github.com/Leejungle/fivem-first-script/tree/main/examples)
without installing anything.

### Known limitations

- `server.cfg.runtime` is a snapshot taken once per FXServer boot;
  rerunning `fxpreflight` re-reads the same snapshot. Restart
  FXServer to refresh it.
- Resources started AFTER fxpreflight will be missed until you run
  `fxpreflight` again. Place `ensure fxpreflight` last in
  `server.cfg`.
- The Cfx default whitelist is hard-coded; v0.2 will expose it via
  `config.lua`.
- Detection only — fxpreflight does not auto-fix any finding.
- Windows-first; Linux works with a one-line bash equivalent of the
  start.bat snapshot copy step (see Known limitations in the README).

### Source / License / Issues

- Source: https://github.com/Leejungle/fivem-first-script
- License: [MIT](https://github.com/Leejungle/fivem-first-script/blob/main/LICENSE)
- Issues / feature requests: https://github.com/Leejungle/fivem-first-script/issues
- Full changelog: https://github.com/Leejungle/fivem-first-script/blob/main/CHANGELOG.md

### Credits

Built by [@Lee_Jungle](https://github.com/Leejungle) as a learning
project and portfolio piece. fxpreflight is not affiliated with
Cfx.re; "FiveM" is a trademark of Cfx.re.
