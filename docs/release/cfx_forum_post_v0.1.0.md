Body of the public release announcement posted to
forum.cfx.re/c/development/releases for fxpreflight v0.1.0. Kept in the
repo as a release artifact so the post can be reproduced or referenced
later.

---

## fxpreflight

fxpreflight is a small server-side tool I made while setting up FiveM
servers. It runs once at server boot, looks at `server.cfg` and every
loaded resource's `fxmanifest.lua`, and prints a short report in the
console listing the boring mistakes I see most often.

It does not auto-fix anything. It just tells you what looks wrong, and
you fix it. It is also not a replacement for txAdmin, monitor, or
reading actual logs. It catches a small set of common config mistakes
earlier so the silent boot failures stop being silent.

It is free, MIT-licensed, pure Lua 5.4, and has no external
dependencies.

### Examples of things it catches

A few of the 12 active rules:

* `endpoint_add_tcp` or `endpoint_add_udp` missing or commented out
* `sv_licenseKey` is the wrong length or has invalid characters
* `sv_hostname` is still the FXServer default
* `steam_webApiKey` is empty or set to `"none"`
* a resource still ships a deprecated `__resource.lua` instead of
  `fxmanifest.lua`
* a resource is on a very old `fx_version` like `'adamant'`

The full rule list is below in this post.

## Demo

![fxpreflight console output, R007 firing on an empty steam_webApiKey](https://raw.githubusercontent.com/Leejungle/fivem-first-script/main/docs/release/images/v0.1.0-console.png)

Console output on a server with one outstanding issue (a single empty
`set steam_webApiKey ""`):

```
[fxpreflight] v0.1.0 preflight starting -- modules loaded: 4, rules registered: 15
[fxpreflight] preflight on server.cfg.runtime (boot-time snapshot) -- 1216 bytes parsed
[fxpreflight] scanned 0 resources, 0 with manifest (25 Cfx defaults skipped)
[fxpreflight] === Preflight report ===
[fxpreflight] [WARNING ] R007  server.cfg:27   steam_webApiKey is a placeholder value ('')
[fxpreflight] === Summary: 0 CRITICAL, 1 WARNING, 0 INFO ===
[fxpreflight] report written -> fxpreflight_report.md (161 bytes)
```

The matching `fxpreflight_report.md` (paste-ready for Discord / forum):

```markdown
# fxpreflight Report

**Summary:** 0 CRITICAL, 1 WARNING, 0 INFO

## WARNING (1)

- **R007** — `server.cfg:27` — steam_webApiKey is a placeholder value ('')
```

A 5-finding demo cfg with both CRITICAL and WARNING is in
[examples/](https://github.com/Leejungle/fivem-first-script/tree/main/examples).
You can read the broken cfg, the console output, and the matching
markdown report there without installing anything.

A 60-second video / GIF will land with v0.1.1.

## Install (5 minutes)

1. Download `Source code (zip)` from the [GitHub release
   page](https://github.com/Leejungle/fivem-first-script/releases/tag/v0.1.0).

2. Extract into `<server-data>/resources/` and rename the folder to
   `fxpreflight` (the resource hard-codes that folder name into the
   snapshot path):

   ```
   <server-data>/resources/fxpreflight/
   ```

3. Add this line to `start.bat` BEFORE the `FXServer.exe` line:

   ```bat
   copy /Y server.cfg resources\fxpreflight\server.cfg.runtime > nul
   ```

   *Why:* FiveM sandboxes `io.open` server-side, so a resource cannot
   read files outside its own folder. The snapshot mechanism gives
   fxpreflight a copy of the live `server.cfg` it CAN read via
   `LoadResourceFile`. The snapshot is overwritten on every boot, so a
   normal edit-and-restart workflow always sees fresh content.

4. Add `ensure fxpreflight` near the bottom of `server.cfg` (so all
   your other resources are scanned):

   ```cfg
   # ... your other ensure lines ...
   ensure fxpreflight
   ```

5. Boot the server. Two files are written into
   `resources/fxpreflight/`:

   - `fxpreflight_report.md`: markdown findings, paste-ready.
   - `fxpreflight_run.log`: verbatim console output of the run.

   Both are overwritten on every preflight run.

### Rerun without restarting

Type `fxpreflight` in the FXServer console (no arguments) to rerun the
preflight. It is restricted to admins and is meaningfully faster than
`restart fxpreflight` because the script environment is not torn down
and rebuilt.

## Rules implemented in v0.1

12 active rules with stable IDs (R001..R013). 3 stubs (R006, R014,
R015) are reserved for v0.2.

| ID    | Severity | What it catches |
|-------|----------|-----------------|
| R001  | CRITICAL | `endpoint_add_tcp` and/or `endpoint_add_udp` are missing |
| R002  | CRITICAL | `sv_licenseKey` is malformed (wrong length or disallowed characters) |
| R003  | CRITICAL | `server.cfg` is suspiciously small (< 200 bytes) |
| R004  | WARNING  | `sv_hostname` is missing or still a known default |
| R005  | WARNING  | `sv_maxclients` is missing or out of `[1, 2048]` |
| R006  | _stub_   | `onesync` set inside `server.cfg` while txAdmin is in use (v0.2) |
| R007  | WARNING  | `steam_webApiKey` is empty or `"none"` |
| R008  | CRITICAL | `fxmanifest.lua` is missing `fx_version` (deprecated `__resource.lua`) |
| R009  | WARNING  | `fx_version` is older than `'cerulean'` |
| R011  | WARNING  | `fxmanifest.lua` has no `games {}` declaration |
| R013  | INFO     | `lua54 'no'`, explicitly opting out of Lua 5.4 |
| R014  | _stub_   | `ensure <res>` points at a folder that does not exist (v0.2) |
| R015  | _stub_   | `add_ace <group>` without a matching `add_principal` (v0.2) |

R007 covers both `set steam_webApiKey ""` (the syntax FXServer's
default cfg template uses) and the direct `steam_webApiKey ""` form.
The parser unwraps `set / setr / sets` so any rule looking up a
convar finds it regardless of which syntax the user wrote.

## Performance

It runs once at server boot, then sits idle. Numbers below are from
my testing on Windows.

- **Boot-time scan**: ~30–80 ms total to read the cfg snapshot, enumerate
  every loaded resource, parse each `fxmanifest.lua`, evaluate 12 rules,
  format the report, and write both output files. Approximate; varies
  with cfg size and resource count. Measured on a Windows FXServer
  (build ~12100), 1.2 KB `server.cfg`, ~25 loaded resources (default Cfx
  setup).
- **Idle (post-boot)**: 0.00 ms tick. The resource registers a single
  `onResourceStart` handler and one console command (`fxpreflight`) for
  on-demand reruns, then sits idle. It does not poll, does not hold
  timers, does not run any per-frame code.
- **Memory**: <100 KB Lua heap (4 shared modules + 15 rule descriptors +
  small log buffer). Negligible against any FXServer footprint.
- **Network**: zero. fxpreflight does not make HTTP requests, does not
  open sockets, and does not contact any external service.
- **Filesystem**: reads only `server.cfg.runtime` (the snapshot copied
  by `start.bat`) and the `fxmanifest.lua` (or legacy `__resource.lua`)
  of every loaded resource, read-only and sequential. Writes only two
  files inside its own resource folder: `fxpreflight_report.md` and
  `fxpreflight_run.log`.

You can verify the numbers with `resmon` (FXServer's built-in resource
monitor): fxpreflight will appear at the top of the table during the
first ~80 ms of the boot sequence, then drop to 0.00 ms forever after.

## Known limitations

- **Snapshot, not live**: `server.cfg.runtime` is the file fxpreflight
  reads. Editing the real `server.cfg` and rerunning `fxpreflight`
  re-reads the SAME snapshot. Restart FXServer to refresh.
- **Late-loaded resources are missed**: a resource started after
  fxpreflight will not appear until you rerun `fxpreflight`. Place
  `ensure fxpreflight` last in `server.cfg`.
- **Cfx default whitelist is hard-coded**: 26 first-party Cfx resources
  are silently skipped. v0.2 will let you override the list via
  `config.lua`.
- **Detection only**: fxpreflight does not auto-fix any finding.
- **Windows-first**: the snapshot copy line in `start.bat` is Windows
  syntax. The Linux equivalent is one line of bash:
  ```bash
  cp server.cfg resources/fxpreflight/server.cfg.runtime
  ```
  but a `start.sh` template is not yet shipped in v0.1. Linux support
  is targeted for v0.1.1.

## Roadmap

| Version | Theme | Highlights |
|---------|-------|-----------|
| **v0.1 (now)** | First public release | 12 active rules, fxmanifest scan, Cfx defaults skip, markdown report, `/fxpreflight` rerun command |
| v0.1.1 | CI + CONTRIBUTING + Linux start.sh | GitHub Actions test runner badge, contribution guide, bash equivalent of the snapshot copy step, demo video |
| v0.2 | Implement R006 / R014 / R015 + `config.lua` | The 3 v0.1 stubs plus user-facing config for whitelist and severity overrides |
| v0.3 | TBD | Discord webhook output, optional HTML report, driven by user feedback |

## At a glance

|                              |                                              |
|------------------------------|----------------------------------------------|
| Code is accessible           | Yes (MIT-licensed, public on GitHub)         |
| Subscription-based           | No                                           |
| Lines (approximately)        | ~1,500 Lua across `server/` + `shared/`      |
| Requirements & dependencies  | None (zero external deps; pure Lua 5.4)      |
| Support                      | Yes (via GitHub issues)                      |

## Source / License

- **Source**: https://github.com/Leejungle/fivem-first-script
- **License**: [MIT](https://github.com/Leejungle/fivem-first-script/blob/main/LICENSE)
- **Issues / feature requests**: https://github.com/Leejungle/fivem-first-script/issues

This is the first FiveM resource I am sharing publicly. I am still
learning the ecosystem, so if a rule fires on something it should not,
or if I got something wrong about how FXServer behaves, please open a
GitHub issue with a small reproducible cfg or fxmanifest snippet.

fxpreflight is not affiliated with Cfx.re. "FiveM" is a trademark of
Cfx.re.
