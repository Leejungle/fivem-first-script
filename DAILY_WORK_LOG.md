# Daily Work Log

A chronological journal of meaningful actions taken on this project. Newest
entry on top. Each entry should let a future agent (or a returning human)
understand what changed in one session and where things stand right now,
without having to re-read the entire repository or rely on chat history.

---

## 2026-05-02 — End-of-session: GitHub canonical, Lua baseline green, reporter TDD plan ready

### Context shift (start of session)
- Project was previously worked on from a different machine and chat session.
- Today the project was moved to a new Windows 10 (build 19045) box.
- Earlier today we briefly worked off a Google Drive ZIP snapshot extracted to
  `C:\Users\Admin\Downloads\FiveM_first_script\FiveM_first_script\`. That
  folder is now a **read-only reference** and must not be edited.
- The cloned GitHub repository at `C:\Users\Admin\Projects\fivem-first-script\`
  is the **single canonical working folder** going forward.
- Tomorrow's session will continue from a different physical machine. Recovery
  protocol: clone the GitHub repo on the new machine and read
  `PROJECT_CONTEXT.md` first.

### Environment setup completed and verified
- Installed Git for Windows via winget. Verified: `git version 2.54.0.windows.1`.
- Cloned the GitHub repository:
  - Source: `https://github.com/Leejungle/fivem-first-script`
  - Destination: `C:\Users\Admin\Projects\fivem-first-script`
- Configured Git identity (global, applied once on this machine):
  - `user.name`  = `Lee Jungle`
  - `user.email` = `leejungle23@gmail.com`
- Switched the Cursor workspace to the cloned repo folder.
- Installed Lua 5.4 via winget (`winget install --id=DEVCOM.Lua --source winget`
  succeeded after the default invocation failed because of an unrelated
  `msstore` source TLS certificate error). Verified: `Lua 5.4.6` from
  `C:\Users\Admin\AppData\Local\Programs\Lua\bin\lua.exe`.

### Repository sanity check (end of session)
- `git status` → `On branch main / Your branch is up to date with 'origin/main'`
  / `nothing to commit, working tree clean` (this state held before the
  end-of-session documentation commit which Opus is preparing).
- `git remote -v` → `origin https://github.com/Leejungle/fivem-first-script.git`
  (fetch + push).
- `git branch --show-current` → `main`.
- `git log --oneline -5` (state before the end-of-session doc commit):
  - `e6d4da5` — docs: add daily work log; record new-machine setup
  - `b5a5c04` — merge: integrate remote initial commit; keep local README
  - `0b6c923` — chore: initial snapshot of fxpreflight project
  - `c99adf5` — Initial commit

### ZIP snapshot vs cloned repo — file-level comparison
- 33 files in each folder, 0 files differ in content (SHA256 hash compared).
- Only structural difference: ZIP folder contains an empty `src/` directory
  left over from the superseded ADR 0001 plan. The GitHub repo correctly
  omits it (Git does not track empty directories).
- Conclusion: no files needed to be copied from the ZIP. The clone is the
  faithful, complete source of truth.

### Source code status
- **No source code was written or modified today.**
- Two parsers (`shared/parser_servercfg.lua`, `shared/parser_fxmanifest.lua`),
  the rule registry (`shared/rules.lua` — 10/15 evaluators implemented), and
  the six existing test files under `tests/` are unchanged from commit
  `e6d4da5` upstream of this end-of-session doc commit.

### Baseline verification
- Ran `lua tests/run.lua` from the project root.
- Result: **106 passed, 0 failed** (exit code 0).
- This is the "regression net" against which all future code changes will be
  measured. Any future change must keep this 106-test baseline green.

### Day's documentation deliverable
- Created and pushed `DAILY_WORK_LOG.md` mid-session (commit `e6d4da5`) as
  a docs-only round-trip to verify GitHub auth on this machine. Push
  succeeded without browser auth popup (Git Credential Manager handled it
  silently after Git for Windows install).
- The end-of-session documentation commit (this entry update plus
  `PROJECT_CONTEXT.md`, `SETUP_STATUS.md`, `NEXT_STEPS.txt` updates) is
  being prepared and pushed by Opus as the final action of today's session.

### Reporter (`shared/reporter.lua`) — Pending, NOT implemented
- Status: **Pending**.
- A complete TDD plan for `shared/reporter.lua` was drafted by Opus and
  human-approved during the session.
- A scoped Sonnet implementation prompt (v2, with 5 safety tightenings —
  byte-exact format spec, no-ellipsis assertions, exact test count
  contract, explicit console-spacing table, mandatory git-status/diff
  reporting at stop) was drafted by Opus and human-approved.
- The Sonnet agent was NOT actually launched today — the human moved to
  end-of-session wrap-up before the launch step.
- Tomorrow's first action: launch the approved Sonnet prompt to implement
  reporter, then Opus reviews and commits.

### Status snapshot at end of session (verified, not assumed)
- Git: `main` clean, in sync with `origin/main` at `e6d4da5` (before the
  end-of-session doc commit currently being prepared).
- Lua 5.4.6 installed and on PATH (verified by `where.exe lua` and `lua -v`).
- Baseline test suite green: 106/106 passed.
- `shared/reporter.lua`: missing (planned, not implemented).
- `tests/test_reporter.lua`: missing (planned, not implemented).
- `server/main.lua`: missing (intentionally deferred to Phase 2).
- Root `fxmanifest.lua`: missing (intentionally deferred to Phase 2).
- `config.lua`: missing (intentionally deferred to Phase 2).
- R006, R010, R012, R014, R015 evaluators: present as stubs returning `nil`,
  intentionally deferred to Phase 2.x.
- FXServer + txAdmin: not installed (intentionally deferred).
- Tebex creator account: not set up (intentionally deferred).
- Discord webhook: not configured (intentionally deferred to Phase 2).

### Next session — recommended first actions (cross-machine handoff)
1. On the new machine: install Git, clone `https://github.com/Leejungle/fivem-first-script`
   to a clean `Projects\` folder, configure Git identity if not already
   done.
2. Install Lua 5.4 via `winget install --id=DEVCOM.Lua --source winget`.
   Verify `lua -v` prints `Lua 5.4.x`.
3. From the cloned repo root: `lua tests/run.lua`. Confirm 106 passed.
4. Read `PROJECT_CONTEXT.md` (created at end of today's session) for the
   full handoff briefing.
5. Read this `DAILY_WORK_LOG.md` for today's history.
6. Resume work by launching the Sonnet implementation prompt for
   `shared/reporter.lua` (the prompt content is recorded in
   `PROJECT_CONTEXT.md` §11 for reference, or can be re-derived from
   PRODUCT_SPEC.md + shared/rules.lua).

### Reminders for future sessions
- Never edit anything inside `C:\Users\Admin\Downloads\FiveM_first_script\`
  on the old machine. The ZIP snapshot is read-only history.
- Never recreate the legacy `src/` folder. Node + TypeScript direction is
  superseded by ADR 0002.
- All offline development happens in pure Lua under `shared/` and is
  validated by `lua tests/run.lua`. FXServer-specific code
  (`server/main.lua` and the resource's own `fxmanifest.lua`) is deferred
  until a local FXServer runtime is available.
- GitHub is the single source of truth. ZIP backups are NOT needed for
  daily workflow; `git push` is the daily backup mechanism.
