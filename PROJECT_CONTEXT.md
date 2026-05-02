# Project Context — fxpreflight

> **Purpose of this file:** the single source of truth for "where are we right
> now" in this project. Any agent — human or AI — should be able to read this
> file (plus `DAILY_WORK_LOG.md`, `PRODUCT_SPEC.md`, `NEXT_STEPS.txt`,
> `SETUP_STATUS.md`) and immediately know what to do next, without relying on
> any chat history. Update this file at the end of every session that changes
> what is "done" or "next".
>
> **Last updated:** 2026-05-02 (laptop session, post-reporter — Phase 1 complete).

---

## 1. Project Summary

`fxpreflight` is a pure-Lua FiveM **server-side resource** that performs
*static analysis* of a FiveM server's configuration at server startup. It
behaves like a linter / preflight checker for FiveM servers.

When FXServer boots, fxpreflight (eventually) will:
1. Locate and parse `server.cfg`.
2. Walk every resource folder under `resources/` and parse each
   `fxmanifest.lua`.
3. Apply a fixed v1 ruleset (R001–R015).
4. Print findings to the FXServer console with severity prefixes
   (`[CRITICAL]`, `[WARNING]`, `[INFO]`).
5. Write `fxpreflight_report.md` next to `server.cfg`.
6. Optionally POST a summary to a Discord webhook.

It is intended to be sold as a Tebex-escrow Lua resource. Buyers drop the
folder into `resources/[tools]/fxpreflight/` and add `ensure fxpreflight`
to `server.cfg`.

---

## 2. Canonical Repository

| Item | Value |
|---|---|
| GitHub repository | https://github.com/Leejungle/fivem-first-script |
| Default branch | `main` |
| Local working folders (active machines) | Desktop: `C:\Users\Admin\Projects\fivem-first-script\` • Laptop: `g:\FiveM\fivem-first-script\` |
| Old ZIP snapshot folder (read-only history) | `C:\Users\Admin\Downloads\FiveM_first_script\` |
| Source of truth | **GitHub `main`** |
| Daily backup mechanism | `git push origin main` |

Both active machines stay in sync via GitHub `main`. The ZIP folder must
NEVER be edited going forward. If another machine is added, clone fresh
from GitHub.

---

## 3. Product Vision

| Phase | Status | Description |
|---|---|---|
| v1 — Lua FiveM Resource Preflight Validator | **ACTIVE** | Parse `server.cfg` + `fxmanifest.lua`, apply R001–R015, print to console, write Markdown report, optional Discord webhook |
| v1.5 — NUI Report Viewer | Future | Web panel inside FiveM for browsing findings |
| v2 — ACE Permission Debugger | Future | Inheritance chains, circular grants, unreachable permissions |
| v3 — Live Watch Mode + Hitch Detection | Future | Persistent watcher; runtime tick monitoring |
| v4 — Cloud SaaS | Future | Multi-server hosted dashboard |

See `ROADMAP.md` for full descriptions.

---

## 4. Architecture Decisions

| ADR | Status | Decision |
|---|---|---|
| ADR 0001 — Language Choice (Node + TypeScript CLI) | **SUPERSEDED** | Originally chose Node/TS. Invalidated when market research showed FiveM products must be Lua resources on Tebex. |
| ADR 0002 — Pivot to Pure-Lua FiveM Resource | **ACCEPTED** | v1 is a pure-Lua FiveM resource. Logic in `shared/` is testable offline against fixtures. `server/main.lua` glues to FiveM API later. |

**Forbidden:** do not revive Node/TypeScript. Do not recreate `src/`.

---

## 5. Current Architecture

```
fxpreflight/
├── shared/                          (pure Lua, FXServer-independent, testable offline)
│   ├── parser_servercfg.lua         DONE — line/directive parser
│   ├── parser_fxmanifest.lua        DONE — sandboxed load() recorder
│   ├── rules.lua                    DONE registry; 10/15 evaluators implemented
│   └── reporter.lua                 DONE — pure 3-function API (149 lines)
├── server/                          (FiveM glue layer; deferred until local FXServer)
│   └── main.lua                     MISSING — Phase 2 deliverable
├── tests/
│   ├── run.lua                      DONE — mini test runner
│   ├── test_parser_servercfg.lua    DONE
│   ├── test_parser_fxmanifest.lua   DONE
│   ├── test_rules_critical_cfg.lua  DONE (R001/R002/R003)
│   ├── test_rules_critical_fxmanifest.lua  DONE (R008)
│   ├── test_rules_warning_cfg.lua   DONE (R004/R005/R007)
│   ├── test_rules_warning_fxmanifest.lua  DONE (R009/R011/R013)
│   └── test_reporter.lua            DONE — 20 byte-exact cases (269 lines)
├── fixtures/                        (workspace-root during dev; copied into resource at packaging time)
│   ├── server-cfg/                  DONE — 4 fixtures
│   └── fxmanifest/                  DONE — 2 fixtures
├── docs/
│   ├── fivem-basics.md              DONE — beginner cheatsheet
│   ├── decisions/                   DONE — ADR 0001 (superseded), 0002 (accepted)
│   └── research/                    DONE — market findings, competitor notes
├── fxmanifest.lua                   MISSING — Phase 2 (resource's own manifest)
├── config.lua                       MISSING — Phase 2 (Discord webhook URL holder)
├── README.md, IDEA_1.md, PRODUCT_SPEC.md, ROADMAP.md  DONE
├── NEXT_STEPS.txt, SETUP_STATUS.md, DAILY_WORK_LOG.md DONE
├── PROJECT_CONTEXT.md               (this file)
└── .gitignore                       DONE
```

**Three-ring mental model:**
- **Inner ring (`shared/`)** — pure Lua brain, no FiveM API, testable offline.
- **Middle ring (`server/main.lua`, future)** — FiveM glue: `onResourceStart`,
  file walking, dispatch to inner ring, write Markdown to disk, POST webhook.
- **Outer ring (FiveM/FXServer runtime)** — loads the resource, fires
  `onResourceStart`.

---

## 6. Current Completion Status

Verified as of 2026-05-02 (laptop session, post-reporter commit `084c09c`).

### Done & Verified
- All planning, market research, and ADR docs.
- 6 fixture files (4 cfg + 2 fxmanifest).
- `shared/parser_servercfg.lua`.
- `shared/parser_fxmanifest.lua`.
- `shared/rules.lua` registry with 10 working evaluators:
  R001, R002, R003, R004, R005, R007, R008, R009, R011, R013.
- `shared/reporter.lua` — pure 3-function API (`summarize`,
  `format_console`, `format_markdown`); byte-exact console + Markdown
  formats; sort by (severity, rule_id, file, line); no I/O, no FiveM
  natives, no network calls.
- `tests/run.lua` + 7 test files (parser_servercfg, parser_fxmanifest,
  rules_critical_cfg, rules_critical_fxmanifest, rules_warning_cfg,
  rules_warning_fxmanifest, reporter).
- `tests/test_reporter.lua` — 20 byte-exact cases (8 summarize +
  7 format_console + 5 format_markdown).
- **Baseline test suite: 126 passed, 0 failed** (verified with
  `lua tests/run.lua` on Lua 5.4.6 / Windows; +20 from reporter,
  was 106 before commit `084c09c`).
- Git installed (2.54.0 on desktop, also present on laptop) and
  configured (`Lee Jungle / leejungle23@gmail.com`).
- GitHub clone + push round-trip verified working from both machines.
- Lua 5.4.6 installed on both desktop and laptop.

### Pending (planned, not yet started)
- (none — Phase 1 v1 contract is COMPLETE; see §8 for the next
  product decision)

### Deferred (intentionally postponed; not a bug)
- R006, R010, R012, R014, R015 — stubs returning `nil`. Most need
  filesystem walking; pair best with `server/main.lua`.
- `server/main.lua` — needs FXServer runtime for integration test.
- Root `fxmanifest.lua` — Phase 2.
- `config.lua` — Phase 2.
- Discord webhook send — Phase 2.
- Tebex packaging — far Phase 2+.
- v1.5 NUI viewer / v2 ACE debugger / v3 watch mode / v4 cloud SaaS — see ROADMAP.

### Blocked
- `server/main.lua` integration test blocked by absence of local FXServer
  (intentional — see ADR 0002).

---

## 7. Opus vs Sonnet Workflow

This project uses a strict division of labor between AI roles.

### Opus (architect / planner / reviewer / prompt writer)
- Audits repo state before each major step.
- Decides next safest technical task.
- Writes scoped Sonnet implementation prompts.
- Reviews Sonnet output diff against spec.
- Reviews `git status` and `git diff` before any commit.
- Decides what documentation to update.
- Prevents scope creep.
- Teaches reasoning to the human learner.
- **Does NOT write feature code directly when a Sonnet task is appropriate**
  (delegates), unless the task is too small or too judgment-heavy to scope.

### Sonnet (scoped implementer)
- Codes only the explicitly-scoped task Opus assigns.
- Modifies only the files in the prompt's "allowed" list.
- Avoids unrelated refactors.
- Avoids architecture decisions.
- Runs tests after implementation; reports pass/fail.
- Stops when stop condition is met.
- **Does NOT touch forbidden files. Does NOT git commit/push.**

### Human learner (you)
- Confirms major steps before they happen.
- Runs commands when delegated.
- Pastes outputs back for review.
- Approves diffs before commit.
- Approves Sonnet prompts before launch.
- Learns the reasoning, not just the result.

### Allowed Cursor-recognized model slugs (only these)
- `claude-4.6-sonnet-medium-thinking` (default for Sonnet tasks)
- `claude-opus-4-7-thinking-xhigh`
- `composer-2-fast`
- `gpt-5.3-codex`
- `gpt-5.5-medium`

If user requests a model not in the list, do not silently substitute; ask.

---

## 8. Immediate Next Step

**Verified state after 2026-05-02 laptop session:** baseline 126 / 126;
reporter shipped (commit `084c09c`); Phase 1 v1 contract complete.

### Phase 2 entry-point decision (no active code task)

The five remaining stub evaluators (R006, R010, R012, R014, R015) all
require either filesystem walking or a live FXServer convention check.
Neither can be implemented purely in `shared/` without first either
installing FXServer locally OR writing a small filesystem-walker
utility. There is no obvious "safe next coding task" until this product
choice is made.

Two candidate paths:

**Path A — FXServer-first.** Install FXServer + txAdmin locally,
then build `server/main.lua` as the scaffolding that walks the
resources tree, locates `server.cfg`, dispatches to the parsers and
rules, and feeds findings to `reporter`. Implement R006 (txAdmin
convention), R010 (`__resource.lua` detection), R012 (script-path
existence), R014 (resource-folder existence), and R015 (`add_ace`
without `add_principal`) inside that loop. Produces a shippable
resource sooner.

**Path B — offline-first.** Add a small `shared/fs.lua` filesystem
walker (pure Lua, testable offline against a fixture tree). Implement
the three offline-friendly evaluators in shared:
  - R010 (detect `__resource.lua` files)
  - R012 (verify `client_script` / `server_script` paths exist)
  - R014 (verify `ensure <resource>` folders exist)
R006 and R015 stay deferred until FXServer is installed. Keeps the
project entirely offline-testable for longer and grows the test suite
without new tooling.

The choice is a product decision (ship-speed vs. test-surface) and is
deferred to the next session. Opus will not pick unilaterally.

### Bookkeeping after the next decision

- Update `MASTER_PROMPT.md §4` to lock the chosen Phase 2 task order.
- Update `NEXT_STEPS.txt` Active task to the first concrete sub-task
  of the chosen path.

---

## 9. Forbidden Actions

These rules are absolute. Violating them creates problems that are
expensive to undo.

### Filesystem / repo
- Do NOT edit anything inside `C:\Users\Admin\Downloads\FiveM_first_script\`
  on the original machine. That ZIP is read-only history.
- Do NOT run `git init` anywhere — the canonical repo is the GitHub clone.
- Do NOT recreate the `src/` folder. ADR 0002 buried it.
- Do NOT use `git add .` blindly. Always explicit paths.
- Do NOT use `git push --force` against `main`.
- Do NOT use `git commit --amend` after pushing.
- Do NOT skip pre-commit hooks with `--no-verify`.

### Architecture
- Do NOT revive Node.js or TypeScript code paths.
- Do NOT add a CLI wrapper, installer script, or npm package.
- Do NOT add framework-specific (ESX/QBCore/QBOX) checks; v1 is
  framework-agnostic.

### Phase boundary
- Do NOT create `server/main.lua` until a local FXServer is available
  to integration-test it.
- Do NOT create root `fxmanifest.lua` until Phase 2.
- Do NOT create `config.lua` until Phase 2.
- Do NOT add Discord webhook code until Phase 2 (`PerformHttpRequest`
  belongs in `server/main.lua`, not `shared/`).
- Do NOT call FiveM natives anywhere in `shared/`.

### Workflow
- Do NOT let Sonnet make architectural decisions.
- Do NOT let Sonnet edit `docs/decisions/` or `PRODUCT_SPEC.md`.
- Do NOT let Sonnet `git commit` or `git push`. Opus reviews then commits.
- Do NOT skip the baseline `lua tests/run.lua` after any code change.

---

## 10. Future Agent Startup Protocol

**Every future session must run this protocol before doing any work.**

### Step 1 — Read these files in order
1. `PROJECT_CONTEXT.md` (this file) — current state and rules.
2. `DAILY_WORK_LOG.md` — what happened most recently.
3. `PRODUCT_SPEC.md` — the v1 contract (rules R001–R015, output format).
4. `NEXT_STEPS.txt` — the concrete to-do list.
5. `SETUP_STATUS.md` — environment checklist.

### Step 2 — Run these read-only commands and paste output to Opus

```powershell
pwd
git status
git remote -v
git branch --show-current
git log --oneline -5
lua -v
lua tests/run.lua
```

### Step 3 — Report
- Current working folder.
- Branch and sync status with `origin/main`.
- Lua version on PATH.
- Baseline test result (count and exit code).
- Any unexpected files or dirty working tree.
- The next safest step based on the verified state.

### Step 4 — If on a brand-new machine
Setup checklist:
1. Install Git for Windows: `winget install --id Git.Git -e --source winget`.
2. Configure identity:
   `git config --global user.name "Lee Jungle"`
   `git config --global user.email "leejungle23@gmail.com"`
3. Clone: `git clone https://github.com/Leejungle/fivem-first-script.git`
   into a clean parent folder (e.g. `C:\Users\<you>\Projects\`).
4. Install Lua 5.4: `winget install --id=DEVCOM.Lua --source winget`.
   (If that fails with `0x8a15005e` from msstore source, the `--source winget`
   flag is what makes it succeed by skipping the broken msstore source.)
5. Open a fresh PowerShell. Verify `git --version` and `lua -v`.
6. `cd` into the cloned repo. Run `lua tests/run.lua`. Expect 106 pass.
7. Read this file again with the new working folder set, then proceed.

### Step 5 — Wait for human confirmation before any file modification
Even if the next step is "obvious", confirm with the human first. The human
is the learner and decision-maker.

---

## Appendix — Useful one-liners

| Goal | Command |
|---|---|
| Baseline test | `lua tests/run.lua` |
| Verify Git OK | `git --version && git status` |
| Verify Lua OK | `lua -v` |
| Diff before commit | `git status; git diff --stat; git diff` |
| Safe stage | `git add <explicit-path-1> <explicit-path-2>` |
| Safe push | `git pull --rebase && git push origin main` |
