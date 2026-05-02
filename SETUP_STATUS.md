# Setup Status

A living checklist of the local development environment for this project.

## Available Now

- [x] Cursor IDE installed and running
- [x] Opus (strategist) available via Cursor
- [x] Sonnet (implementer) available via Cursor
- [x] Basic Windows shell (PowerShell)
- [x] **Git for Windows installed** — verified `git version 2.54.0.windows.1`
      on 2026-05-02. Identity configured (`Lee Jungle / leejungle23@gmail.com`).
- [x] **GitHub repository cloned** at
      `C:\Users\Admin\Projects\fivem-first-script\`
      (origin: `https://github.com/Leejungle/fivem-first-script.git`).
      Push round-trip verified working on 2026-05-02 (commit `e6d4da5`).
- [x] **Standalone Lua 5.4 interpreter (desktop)** — verified `Lua 5.4.6`
      on 2026-05-02 at `C:\Users\Admin\AppData\Local\Programs\Lua\bin\lua.exe`
      via `winget install --id=DEVCOM.Lua --source winget`.
- [x] **Standalone Lua 5.4 interpreter (laptop)** — verified `Lua 5.4.6`
      on 2026-05-02 at `C:\Users\ACER\AppData\Local\Programs\Lua\bin\lua.exe`
      via `winget install --id=DEVCOM.Lua --source winget`
      `--accept-source-agreements --accept-package-agreements`.
- [x] **Laptop machine cloned** — second active machine cloned to
      `g:\FiveM\fivem-first-script\` on 2026-05-02. Both machines stay
      in sync via GitHub `main`.
- [x] **Baseline test suite green** — `lua tests/run.lua` reports
      `126 passed, 0 failed` (exit code 0) as of 2026-05-02 after the
      reporter commit (`084c09c`). Was `106 passed, 0 failed` before
      reporter shipped.

## Later — Needed for v1 Integration Test and Selling

- [ ] FXServer + txAdmin home setup — required to run fxpreflight as a live
      resource and verify the `onResourceStart` trigger and file output.
- [ ] Tebex creator account — required to list fxpreflight for sale with
      escrow protection.
- [ ] Discord webhook test endpoint — optional; needed to verify the
      `PerformHttpRequest` webhook feature in `config.lua`.

## How to Install Lua 5.4 on Windows (kept for future reference / new machines)

**Option 1 — winget (recommended):**

```
winget install --id=DEVCOM.Lua --source winget
```

> The explicit `--source winget` flag is required if the default invocation
> fails with `0x8a15005e` from the `msstore` source (a TLS certificate
> error in the Microsoft Store source that does NOT affect the `winget`
> community source).

**Option 2 — manual download:**

Download a pre-built Windows binary from https://luabinaries.sourceforge.net/
(choose the latest 5.4.x release, e.g. `lua-5.4.x_Win64_bin.zip`, extract,
and place `lua.exe` somewhere on your PATH).

**Verify the install:**

```
lua -v
```

Expected: the first output line begins with `Lua 5.4`.

**PATH note:** If `lua` is not found after running the winget command, close
and reopen PowerShell so PATH refreshes. If still not found, add the Lua
install directory to your system PATH manually (Control Panel > System >
Advanced system settings > Environment Variables > PATH).

---
Last updated: 2026-05-02 (laptop session, post-reporter)
