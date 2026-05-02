# Daily Work Log

A chronological journal of meaningful actions taken on this project. Newest
entry on top. Each entry should let a future agent (or a returning human)
understand what changed in one session and where things stand right now,
without having to re-read the entire repository or rely on chat history.

---

## 2026-05-02 — Migrated to new Windows machine; established GitHub as the canonical source of truth

### Context shift
- Project was previously worked on from a different machine and a different
  chat session. Today the project was moved to a new Windows 10
  (build 19045) box.
- Earlier today we worked off a Google Drive ZIP snapshot extracted to
  `C:\Users\Admin\Downloads\FiveM_first_script\FiveM_first_script\`. That
  folder is now a **read-only reference** and must not be edited going
  forward.
- The cloned GitHub repository at `C:\Users\Admin\Projects\fivem-first-script\`
  is the **single canonical working folder** from this point on.

### Environment setup completed today
- Installed Git for Windows via:
  `winget install --id Git.Git -e --source winget`
  Verified with `git --version` → `git version 2.54.0.windows.1`.
- Cloned the GitHub repository:
  - Source: `https://github.com/Leejungle/fivem-first-script`
  - Destination: `C:\Users\Admin\Projects\fivem-first-script`
- Configured Git identity (global, applied once on this machine):
  - `user.name`  = `Lee Jungle`
  - `user.email` = `leejungle23@gmail.com`
- Switched the Cursor workspace to the cloned repo folder. The old ZIP
  folder under `Downloads\` is no longer the working directory.

### Repository sanity check
- `git status` → `On branch main / Your branch is up to date with 'origin/main'
  / nothing to commit, working tree clean`.
- `git remote -v` → `origin https://github.com/Leejungle/fivem-first-script.git`
  for both fetch and push.
- `git branch --show-current` → `main`.
- `git log --oneline -5` → 3 commits, matching the GitHub repository exactly:
  - `b5a5c04` — merge: integrate remote initial commit; keep local README
  - `0b6c923` — chore: initial snapshot of fxpreflight project (Phase 1 + 2.1 + 2.2)
  - `c99adf5` — Initial commit

### ZIP snapshot vs cloned repo — file-level comparison
- Both folders contain 33 files.
- 0 files differ in content (compared via SHA256 hash).
- Only structural difference: the ZIP folder contains an empty `src/`
  directory left over from the superseded ADR 0001 (Node + TypeScript CLI
  plan). The GitHub repository correctly omits it because Git does not
  track empty directories.
- Conclusion: **no files needed to be copied from the ZIP to the clone.**
  The clone is a faithful and complete copy of the canonical project state.

### Source code status
- **No source code was written or modified today.**
- The two parsers (`shared/parser_servercfg.lua`,
  `shared/parser_fxmanifest.lua`), the rule registry
  (`shared/rules.lua` — 10/15 evaluators implemented), and the six test
  files under `tests/` are unchanged from commit `b5a5c04`.

### Tooling status
- Lua 5.4 interpreter is **not yet installed** on this machine.
  `where.exe lua` returns nothing; `lua -v` is unavailable.
- Because of the above, `lua tests/run.lua` has **not yet been run** on
  this machine. The baseline test suite is therefore not yet verified
  green on the new box.
- FXServer + txAdmin are intentionally not installed at this stage; they
  are not needed for current Phase 1 (offline rule-engine) work.
- Tebex creator account: intentionally deferred until Phase 2 packaging.

### Agent / workflow setup
- Established the Opus (architect, planner, reviewer, prompt writer) vs
  Sonnet (scoped implementer) division of labor for this project.
- **Sonnet has not been invoked today.** Sonnet remains blocked until all
  of the following are true:
  1. Lua 5.4 is installed and `lua -v` returns `Lua 5.4.x ...`.
  2. `lua tests/run.lua` exits with code 0 and every test reports `[PASS]`.
  3. Opus has written a TDD plan for `shared/reporter.lua`.
  4. The human has approved the Sonnet implementation prompt.

### Status snapshot at end of today's session
- Git working tree: clean.
- Local `main` is in sync with `origin/main` at commit `b5a5c04`.
- Implementation gaps relative to PRODUCT_SPEC v1:
  - `shared/reporter.lua` — missing
  - `server/main.lua` — missing
  - root `fxmanifest.lua` — missing
  - `config.lua` — missing
  - Evaluators for R006, R010, R012, R014, R015 — present as stubs
    that return `nil`; explicitly deferred to Phase 2.x.
- Memory files on disk: `README.md`, `IDEA_1.md`, `PRODUCT_SPEC.md`,
  `ROADMAP.md`, `NEXT_STEPS.txt`, `SETUP_STATUS.md`. `PROJECT_CONTEXT.md`
  does not yet exist (planned for after the reporter slice ships).

### Next steps (in order)
1. Human reviews this draft of `DAILY_WORK_LOG.md`.
2. Opus creates `DAILY_WORK_LOG.md` in the project root with the approved
   content.
3. Opus walks the human through `git status` and `git diff` to review the
   change end-to-end before any commit.
4. Stage, commit, and push the docs-only change to verify the GitHub
   round-trip works on this machine with the configured identity:
   - `git add DAILY_WORK_LOG.md`
   - `git commit -m "docs: add daily work log; record new-machine setup"`
   - `git pull --rebase` (defensive)
   - `git push origin main`
   Verify by reloading the GitHub web UI and confirming the new file
   appears.
5. Install Lua 5.4 on Windows: `winget install --id=DEVCOM.Lua`. Close
   and reopen the terminal so PATH refreshes.
6. Verify Lua: `lua -v` should print `Lua 5.4.x ...`.
7. Run the baseline test suite from the project root:
   `lua tests/run.lua`. Expect exit code 0 and all tests `[PASS]`.
8. If baseline is green: Opus prepares a TDD plan for
   `shared/reporter.lua` covering the finding-shape contract consumed
   from `shared/rules.lua`, the console output format (severity-prefixed
   lines), the Markdown output format (grouped by severity), and the
   exact test cases the reporter must pass.
9. Opus writes the scoped Sonnet implementation prompt for creating
   `shared/reporter.lua` and `tests/test_reporter.lua` (and a single,
   tightly-scoped edit to `tests/run.lua` to register the new test file).
10. Human approves the prompt. Sonnet implements only after explicit
    approval.
11. Opus reviews Sonnet's diff, commits, pushes, and updates
    `SETUP_STATUS.md` and `NEXT_STEPS.txt` to reflect the new state.

### Reminders for future sessions
- Never edit anything inside `C:\Users\Admin\Downloads\FiveM_first_script\`.
  That folder is the read-only ZIP snapshot.
- Never recreate the legacy `src/` folder. The Node + TypeScript direction
  is superseded by ADR 0002 and must not be revived.
- All offline development happens in pure Lua under `shared/` and is
  validated by `lua tests/run.lua`. FXServer-specific code
  (`server/main.lua` and the resource's own `fxmanifest.lua`) is deferred
  until a local FXServer runtime is available.
