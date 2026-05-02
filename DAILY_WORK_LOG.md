# Daily Work Log

A chronological journal of meaningful actions taken on this project. Newest
entry on top. Each entry should let a future agent (or a returning human)
understand what changed in one session and where things stand right now,
without having to re-read the entire repository or rely on chat history.

---

## 2026-05-02 (laptop session) — Reporter implemented; Phase 1 complete

### Context shift (start of session)
- Switched to laptop machine. New canonical working folder on this box:
  `g:\FiveM\fivem-first-script` (the desktop folder
  `C:\Users\Admin\Projects\fivem-first-script` from the earlier session
  remains a valid active folder — both stay in sync via GitHub `main`).
- New Cursor agent window: no chat history from the earlier session.
  Opus rebuilt context entirely from `PROJECT_CONTEXT.md`,
  `DAILY_WORK_LOG.md`, `MASTER_PROMPT.md`, `NEXT_STEPS.txt`,
  `SETUP_STATUS.md`, `PRODUCT_SPEC.md`, `ROADMAP.md`, `README.md`,
  `IDEA_1.md` plus a folder inspection of `shared/`, `tests/`,
  `fixtures/`, `server/`, `docs/`, `docs/decisions/`.
- Repo state on arrival: clean, on `main`, in sync with `origin/main`
  at commit `d9a27de` ("docs: add MASTER_PROMPT.md for cross-machine
  session bootstrapping").

### Environment setup on the laptop
- Git was already installed (the read-only `git status` invocation
  worked without intervention).
- Lua was NOT installed. `lua -v` and `where.exe lua` both confirmed
  absence; common install paths
  (`%LOCALAPPDATA%\Programs\Lua\bin\lua.exe`, `C:\Program Files\Lua\lua.exe`,
  `C:\Lua\lua.exe`) were all empty.
- Installed Lua 5.4 via:
  `winget install --id=DEVCOM.Lua --source winget --accept-source-agreements --accept-package-agreements`
  One-shot success (exit 0, ~17 seconds total). Resolved install path:
  `C:\Users\ACER\AppData\Local\Programs\Lua\bin\lua.exe`.
- After PATH refresh (machine + user), verified `Lua 5.4.6` via `lua -v`.

### Baseline verification on the laptop
- Ran `lua tests/run.lua` from the project root.
- Result: **106 passed, 0 failed** (exit code 0). Matches the desktop
  baseline exactly. Phase 1 environment gate satisfied.

### Reporter implementation via Sonnet
- Opus re-derived the v2 implementation prompt from
  `PROJECT_CONTEXT.md §8` + `PRODUCT_SPEC.md §Outputs` +
  `shared/rules.lua` (finding shape) + `tests/run.lua` (test API) +
  `tests/test_rules_warning_cfg.lua` (test style). Five safety
  tightenings carried over from the originally approved prompt:
  byte-exact format spec (with 12 / 8 / 9 space-counts annotated),
  no-ellipsis assertion rule, exact 20-test contract, explicit
  severity-padding table (`[CRITICAL]` / `[WARNING ]` / `[INFO    ]`),
  and mandatory `git status` + `git diff --stat` reporting at stop.
- The prompt was presented in full and human-approved verbatim.
- Sonnet (`claude-4.6-sonnet-medium-thinking`) was launched and ran
  to completion. Output was clean: only the three allowed files
  changed, no forbidden file touched, no git mutation attempted.

### Code review by Opus
- `shared/reporter.lua` (149 lines): 3 exported functions
  (`summarize`, `format_console`, `format_markdown`); pure (no I/O,
  no FiveM natives, no network, no `print`); shallow-copy before
  sort to protect caller's table; `by_severity` always initialised
  to `{ CRITICAL=0, WARNING=0, INFO=0 }`; sort key 4-tuple
  `(severity_rank, rule_id, file, line or 0)`; console line built
  with `string.format("%s %s  %-20s  %s", ...)` matching the
  spec byte-for-byte; markdown omits empty-severity sections and
  trims the final trailing blank line; em-dash `—` (U+2014)
  preserved verbatim throughout.
- `tests/test_reporter.lua` (269 lines): exactly 20 `t.it` cases
  in the prescribed 8 / 7 / 5 grouping; every byte-exact assertion
  uses literal expected strings with `assert_eq` (no `string.find`,
  no truncation); shared finding fixtures defined once at the top
  for DRY; the marquee 4-finding tests (B5 and C4) pass scrambled
  input order, so they exercise the sort logic at the same time.
- `tests/run.lua`: exactly one line added —
  `require('tests.test_reporter')` — inserted after
  `require('tests.test_rules_warning_fxmanifest')` and before
  `M.report_and_exit()`. Other lines untouched.

### Test result post-reporter
- `lua tests/run.lua` → **126 passed, 0 failed** (exit 0).
- Increase of exactly 20 from the 106 baseline, matching the
  prompt contract.

### Commits and push
- Commit `084c09c` — `feat(reporter): add shared/reporter.lua and
  20-test suite` — staged the 3 allowed files explicitly (no
  `git add .`), committed via the PowerShell wrapper workaround
  (`.git/COMMIT_RUN_1.ps1` calling `git commit -F .git/COMMIT_MSG_1.txt`)
  documented in `MASTER_PROMPT.md §9`. The wrapper successfully
  bypassed Cursor's `--trailer "Co-authored-by: ... <email>"`
  injection (PowerShell would otherwise interpret `<email>` as
  redirect input). Both temp files were deleted after the commit.
- Commit 2 (this docs commit) records the session events and marks
  Phase 1 as complete.
- Both commits pushed to `origin/main` after Commit 2 was created.

### Phase 1 status: COMPLETE
- Acceptance criteria from `MASTER_PROMPT.md §4`:
  - [x] `lua tests/run.lua` reports `>=126 pass, 0 failed` (got 126)
  - [x] Reporter format byte-exact with spec
  - [x] Code reviewed, committed, pushed to GitHub `main`

### Status snapshot at end of session (verified)
- Git: `main` clean, in sync with `origin/main` at the post-push HEAD.
- Lua 5.4.6 on PATH (laptop).
- Baseline test suite: 126 / 126 passed.
- `shared/reporter.lua`: present, verified.
- `tests/test_reporter.lua`: present, verified, 20 cases.
- `server/main.lua`: still missing (intentionally deferred to Phase 2).
- Root `fxmanifest.lua`: still missing (Phase 2).
- `config.lua`: still missing (Phase 2).
- R006, R010, R012, R014, R015 evaluators: still stubs returning
  `nil`. All five require either filesystem walking or a live
  FXServer convention check.
- FXServer + txAdmin: still not installed.
- Tebex creator account: still not set up.
- Discord webhook: still not configured.

### Next session — recommended first action
1. Re-read `PROJECT_CONTEXT.md` (updated this session) for the
   current snapshot.
2. Decide the Phase 2 entry point. Two viable paths documented in
   `PROJECT_CONTEXT.md §8`:
   - **Path A (FXServer-first):** install FXServer + txAdmin
     locally, then build `server/main.lua` and use it as the
     scaffolding to implement the remaining 5 stub evaluators in
     a real runtime context.
   - **Path B (offline-first):** add `shared/fs.lua` (pure Lua
     filesystem walker, testable offline against a fixture tree)
     and implement R010 / R012 / R014 in shared/ first; R006 and
     R015 stay deferred until FXServer is installed.
   - Path A produces a shippable resource sooner. Path B keeps
     the project entirely offline-testable for longer and adds
     three more passing evaluators without requiring new tooling.
     This is a product decision; Opus will not pick unilaterally.
3. Update `MASTER_PROMPT.md §4` and `NEXT_STEPS.txt` Active task
   to reflect whichever path is chosen.

### Reminders for future sessions (additions to existing list)
- Laptop machine working folder: `g:\FiveM\fivem-first-script`.
  Desktop machine working folder: `C:\Users\Admin\Projects\fivem-first-script`.
  Both are valid; GitHub `main` is the single source of truth.
- The PS1 commit-wrapper workaround is now confirmed to work on
  this laptop too. Use it any time `git commit -m "..."` is
  attempted from a Cursor agent shell on PowerShell.

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
