# Setup Status

A living checklist of the local development environment for this project.

## Available Now

- [x] Cursor IDE installed and running
- [x] Opus (strategist) available via Cursor
- [x] Sonnet (implementer) available via Cursor
- [x] Basic Windows shell (PowerShell)

## Later — Needed for v1 Integration Test and Selling

- [ ] FXServer + txAdmin home setup — required to run fxpreflight as a live
      resource and verify the `onResourceStart` trigger and file output.
- [ ] Tebex creator account — required to list fxpreflight for sale with
      escrow protection.
- [ ] Discord webhook test endpoint — optional; needed to verify the
      `PerformHttpRequest` webhook feature in `config.lua`.

## How to Install Lua 5.4 on Windows

- [ ] Standalone Lua 5.4 interpreter on Windows (`lua.exe`) — required for
      offline unit testing of `shared/` logic against fixture files. No
      FXServer needed for this step.

**Option 1 — winget (recommended):**

```
winget install --id=DEVCOM.Lua
```

**Option 2 — manual download:**

Download a pre-built Windows binary from https://luabinaries.sourceforge.net/
(choose the latest 5.4.x release, e.g. `lua-5.4.x_Win64_bin.zip`, extract,
and place `lua.exe` somewhere on your PATH).

**Verify the install:**

```
lua -v
```

Expected: the first output line begins with `Lua 5.4`.

**PATH note:** If `lua` is not found after running the winget command, add the
Lua install directory to your system PATH manually (Control Panel > System >
Advanced system settings > Environment Variables > PATH).

---
Last updated: 2026-04-29
