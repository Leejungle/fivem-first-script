# fxpreflight

> Boot-time linter for FiveM `server.cfg` and `fxmanifest.lua`.
> 15 deterministic rules. Zero external dependencies. MIT licensed.

[![tests](https://img.shields.io/badge/tests-134%20passing-brightgreen)](#running-the-tests)
[![license](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![FiveM](https://img.shields.io/badge/FiveM-cerulean+-yellow)](https://fivem.net)
[![lua](https://img.shields.io/badge/lua-5.4-blueviolet)](https://www.lua.org/)

fxpreflight is a small server-side tool I made while setting up FiveM
servers. It runs once at server boot, looks at `server.cfg` and every
loaded resource's `fxmanifest.lua`, and prints a short report in the
console listing the boring mistakes I see most often.

It does not auto-fix anything. It just tells you what looks wrong, and
you fix it.

---

## Table of contents

- [What it does](#what-it-does)
- [Demo](#demo)
- [Quick install (5 minutes)](#quick-install-5-minutes)
- [What it checks](#what-it-checks)
- [Rerun without restarting](#rerun-without-restarting)
- [How it works under the hood](#how-it-works-under-the-hood)
- [Known limitations](#known-limitations)
- [Roadmap](#roadmap)
- [Development](#development)
- [License](#license)

---

## What it does

fxpreflight checks a small list of `server.cfg` and `fxmanifest.lua`
mistakes when the server starts. The full rule list is in
[What it checks](#what-it-checks) below. A few examples:

* `endpoint_add_tcp` or `endpoint_add_udp` missing or commented out
* `sv_licenseKey` is the wrong length or has invalid characters
* `sv_hostname` still set to the FXServer default
* `steam_webApiKey` empty or set to `"none"`
* a resource still using `__resource.lua` instead of `fxmanifest.lua`

These are not interesting bugs. They just eat hours when you do not
know to check them. fxpreflight runs the checklist for you in the
first ~80 ms of boot.

---

## Demo

> A 60-second demo video / GIF will be added with v0.1.1.

Sample console output on a server with one outstanding issue (a
single empty `set steam_webApiKey ""`):

```
[fxpreflight] v0.1.0 preflight starting -- modules loaded: 4, rules registered: 15
[fxpreflight] preflight on server.cfg.runtime (boot-time snapshot) -- 1216 bytes parsed
[fxpreflight] scanned 0 resources, 0 with manifest (25 Cfx defaults skipped)
[fxpreflight] === Preflight report ===
[fxpreflight] [WARNING ] R007  server.cfg:27   steam_webApiKey is a placeholder value ('')
[fxpreflight] === Summary: 0 CRITICAL, 1 WARNING, 0 INFO ===
[fxpreflight] report written -> fxpreflight_report.md (161 bytes)
```

Sample `fxpreflight_report.md` (paste-ready for Discord / Cfx Forum):

```markdown
# fxpreflight Report

**Summary:** 0 CRITICAL, 1 WARNING, 0 INFO

## WARNING (1)

- **R007** — `server.cfg:27` — steam_webApiKey is a placeholder value ('')
```

A 5-finding demo cfg with both **CRITICAL** and **WARNING** is in
[`examples/`](examples/). You can read the broken cfg, the console
output, and the matching markdown report there without installing
anything. The folder also documents how to point fxpreflight at the
demo cfg in two console commands without touching your real
`server.cfg`.

---

## Quick install (5 minutes)

### Prerequisites

- A working FXServer. Windows is the primary supported host. Linux
  works with a one-line tweak, see [Known limitations](#known-limitations).
- Tested on FXServer artifact 7290+ on Windows.

### Steps

1. **Download** the latest `fxpreflight-v0.1.0.zip` from
   [GitHub Releases](https://github.com/Leejungle/fivem-first-script/releases).

2. **Extract** the archive into your server's `resources/` folder so the
   final path is exactly:

   ```
   <server-data>/resources/fxpreflight/
   ```

   The folder name MUST be `fxpreflight`. The resource hard-codes the
   snapshot path against that name. If your archive expands to a
   different folder name, rename it to `fxpreflight`.

3. **Add the snapshot copy line** to `start.bat` (or your start script)
   BEFORE the `FXServer.exe` invocation:

   ```bat
   copy /Y server.cfg resources\fxpreflight\server.cfg.runtime > nul
   ```

   *Why:* FiveM sandboxes `io.open` server-side, so a resource cannot
   read files outside its own folder. The snapshot mechanism gives
   fxpreflight a copy of the live `server.cfg` it CAN read via
   `LoadResourceFile`. The snapshot is overwritten every boot, so a
   normal edit-and-restart workflow always sees fresh content.

4. **Add `ensure fxpreflight`** to `server.cfg`. Recommended placement:
   near the bottom, so all your other resources are loaded before
   fxpreflight scans them:

   ```cfg
   # ... your other ensure lines ...
   ensure fxpreflight
   ```

5. **Boot the server**. Look for `[script:fxpreflight]` lines in the
   FXServer console. Two files will be written into
   `resources/fxpreflight/`:

   - `fxpreflight_report.md`: the markdown report (paste-ready)
   - `fxpreflight_run.log`: the verbatim console output of the run

   Both files are overwritten on every run.

---

## What it checks

12 active rules and 3 stubs reserved for v0.2. Every rule has a stable
ID (R001..R015) so a finding can be discussed unambiguously across
issues, forum posts, and Discord.

| ID    | Severity | What it catches |
|-------|----------|-----------------|
| R001  | CRITICAL | `endpoint_add_tcp` and/or `endpoint_add_udp` are missing from `server.cfg` |
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

R007 covers both `set steam_webApiKey ""` and direct `steam_webApiKey ""`:
the parser unwraps `set / setr / sets` so any rule looking up a convar
finds it regardless of which syntax the user wrote.

---

## Rerun without restarting

Type `fxpreflight` in the FXServer console (no arguments) to rerun the
preflight without recreating the resource's script environment:

```
> fxpreflight
[fxpreflight] v0.1.0 preflight starting -- modules loaded: 4, rules registered: 15
[fxpreflight] preflight on server.cfg.runtime (boot-time snapshot) -- 1216 bytes parsed
...
```

The command is restricted (admin-only), so a regular player cannot
trigger it from chat. Faster than `restart fxpreflight` because the
script environment is not torn down and rebuilt.

---

## How it works under the hood

```
[server.cfg]                          [resources/*/fxmanifest.lua]
     |                                            |
     v                                            v
parser_servercfg.parse_string()      parser_fxmanifest.parse_string()
     |                                            |
     v                                            v
   parsed cfg                              parsed manifests
     |                                            |
     v                                            v
servercfg rules (R001..R007)         fxmanifest rules (R008..R013)
     |                                            |
     +----------------> findings <----------------+
                            |
                            v
                  reporter.summarize()
                            |
              +-------------+-------------+
              v                           v
   reporter.format_console      reporter.format_markdown
              |                           |
              v                           v
     FXServer console            fxpreflight_report.md
              |                           |
              v                           |
     fxpreflight_run.log <----------------+
       (also captures all
        console lines via
        the LOG_BUFFER)
```

- Pure Lua 5.4. No Node.js, no npm, no external runtime.
- Parsers, rules, and reporter live in `shared/` and are unit-tested
  with a 134-test suite that runs under standalone Lua 5.4 (no
  FXServer needed).
- The FiveM-side glue (resource enumeration, file I/O, console output)
  is in `server/main.lua`. It loads the shared modules via
  `LoadResourceFile + load + pcall` rather than `require`, so the dev
  workflow can keep pure-Lua tests while still running inside the
  FiveM sandbox.

---

## Known limitations

- **Snapshot, not live**: `server.cfg.runtime` is the file fxpreflight
  reads. Editing the real `server.cfg` and rerunning `fxpreflight`
  re-reads the SAME snapshot. Restart FXServer to refresh the
  snapshot.
- **Late-loaded resources are missed**: a resource started after
  fxpreflight will not appear until you rerun `fxpreflight`. Place
  `ensure fxpreflight` last in `server.cfg`.
- **Cfx default whitelist is hard-coded**: 26 first-party Cfx resources
  are silently skipped. v0.2 will let you override the list via
  `config.lua`.
- **Detection only**: fxpreflight does not auto-fix any finding. It
  prints messages, you fix the file.
- **Windows-first**: the snapshot copy line in `start.bat` is Windows
  syntax. The Linux equivalent is one line of bash:
  ```bash
  cp server.cfg resources/fxpreflight/server.cfg.runtime
  ```
  but a `start.sh` is not yet shipped in v0.1. Linux support is
  targeted for v0.1.1.

---

## Roadmap

| Version | Theme | Highlights |
|---------|-------|-----------|
| v0.1 (now) | First public release | 12 active rules, fxmanifest scan, Cfx defaults skip, markdown report, `/fxpreflight` rerun command |
| v0.1.1 | CI + CONTRIBUTING + Linux start.sh | GitHub Actions test runner badge, contribution guide, bash equivalent of the snapshot copy step |
| v0.2 | Implement R006 / R014 / R015, `config.lua` | The 3 v0.1 stubs, plus user-facing config for whitelist and severity overrides |
| v0.3 | TBD | Discord webhook output, optional HTML report, driven by user feedback |

---

## Development

### Running the tests

```bash
lua tests/run.lua
```

Expected output ends with `134 passed, 0 failed`. The runner is
self-contained (`tests/run.lua` is ~90 lines). No `busted`, no
luarocks, no external assertion library.

### Repo layout

```
.
├── fxmanifest.lua              # FiveM resource manifest
├── server/main.lua             # Resource entry point (FiveM-side)
├── shared/                     # Pure Lua, no FiveM deps, unit tested
│   ├── parser_servercfg.lua
│   ├── parser_fxmanifest.lua
│   ├── rules.lua
│   └── reporter.lua
├── tests/                      # 134-test suite, no external deps
├── fixtures/                   # Sample server.cfg + fxmanifest.lua
├── docs/                       # ADRs and research notes
├── CHANGELOG.md                # Versioned change log
└── LICENSE                     # MIT
```

### Contributing

`CONTRIBUTING.md` is targeted for v0.1.1. Until then, please open a
GitHub Issue describing the bug or feature request. If your issue is
about a specific rule firing or not firing, please attach a minimal
reproducible cfg or `fxmanifest.lua` snippet.

### Repository name

The GitHub repository is currently named `fivem-first-script` for
historical reasons (this is the author's first FiveM Lua project).
The resource itself is named `fxpreflight` everywhere it matters
(`fxmanifest.lua`, console prefix, file output paths). The repo may be
renamed to `fxpreflight` in a future release; GitHub will preserve the
old URL via redirect.

---

## License

[MIT](LICENSE) © 2026 Lee_Jungle

fxpreflight is not affiliated with Cfx.re. "FiveM" is a trademark of
Cfx.re. The FiveM and FXServer logos are not used or distributed by
this project.
