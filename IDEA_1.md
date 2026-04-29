# IDEA_1 — FiveM Preflight Validator (fxpreflight)

## Concept

fxpreflight is a static analysis tool for FiveM server configurations. It is
distributed as a Lua resource that server owners drop into their `resources/`
folder. When FXServer starts, fxpreflight runs once, reads `server.cfg` and
every `fxmanifest.lua` under `resources/`, applies a documented rule set, and
prints a severity-prefixed report to the console while writing a Markdown
summary next to `server.cfg`. Think of it as a linter for FiveM configuration
that speaks the same language — literally — as the rest of the server.

## Buyer Profile

The primary user is a FiveM server owner who is past the "rent-a-ZAP-Hosting-
panel" stage and is managing their own server files directly. They may be
self-hosting on a VPS, running a small private server, or building a community
server for the first time. They are technical enough to edit config files but
not experienced enough to know every obscure FiveM convention by heart. They
have almost certainly stared at a blank console wondering why their server
refuses to start.

## Pain Solved

- Servers silently fail to bind because `endpoint_add_tcp` / `endpoint_add_udp`
  are missing or commented out — forum threads show this is one of the most
  common first-start failures.
- Malformed or placeholder license keys (`cfx_XXXX` format not followed)
  produce cryptic authentication errors that beginners cannot decode.
- Resources are listed in `ensure` directives but the actual folder does not
  exist, causing a stream of "resource not found" errors at startup.
- `__resource.lua` was deprecated years ago but tutorials still reference it;
  servers using it produce warning floods that hide real errors.
- Missing `fx_version` in `fxmanifest.lua` causes silent resource loading
  failures that are nearly impossible to trace without knowing where to look.

## Why It Might Sell

- No existing tool performs offline, file-level static analysis on both
  `server.cfg` and `fxmanifest.lua` simultaneously — the gap is confirmed by
  multiple searches returning zero relevant results on the CFX forum and GitHub.
- The pain is acute and reproducible: every new server owner hits at least one
  of these problems on their first or second setup attempt.
- The tool is framework-agnostic (works with ESX, QBCore, QBOX, vanilla FiveM,
  or any other setup), which maximises the addressable audience.
- Being a Lua resource means buyers install it exactly the same way they
  install every other FiveM script — drop folder, add `ensure`, restart.
  There is zero friction and no new toolchain to learn.
- Lua resources are eligible for Tebex escrow, so the product can be sold and
  protected through the same storefront that buyers already use and trust.

## Why It Might NOT Sell

- txAdmin already ships basic sanity checks at startup, so some users may feel
  their needs are met even if those checks are shallower than fxpreflight's.
- The FiveM server management market is small compared to mainstream DevOps
  tooling; the ceiling on revenue is correspondingly low.
- A sufficiently skilled server owner can already read error logs manually,
  meaning the tool saves time rather than unlocking a capability that is
  otherwise impossible.
- Lua has weaker developer experience than a TypeScript codebase (no compile-
  time type checking, thinner tooling), but this matches the market expectation
  exactly — FiveM buyers expect Lua resources, not compiled binaries.

## Competition Snapshot

**txAdmin built-in checks:** txAdmin validates that FXServer itself starts and
can read the config, and it surfaces runtime errors in its web UI. It does NOT
perform pre-start static analysis of fxmanifest files, does NOT flag deprecated
`__resource.lua`, and does NOT cross-reference `ensure` directives against the
filesystem before the server boots.

**PerformanceSentry:** Focuses on runtime performance metrics (tick rates,
memory, script timing). Owns the "is my server healthy while running" space.
Does not touch configuration files or pre-start validation at all.

**DF_Logs:** A logging and diagnostics resource (currently in preview). Operates
at runtime, captures server and resource events. Not a static analysis tool.

**Agency Reports V2:** Focused on in-game player activity and report management.
Adjacent to server administration but entirely different problem space.

**"0 results" searches:** Searches for "fxmanifest linter", "server.cfg
validator", "fivem config validator resource", and "fxpreflight" on the CFX
forum and GitHub all returned zero relevant results as of the research date,
confirming there is no direct competitor in this exact niche.

## Why We Chose It Over the Other 9 Candidates

The shortlist of ten ideas was evaluated on three axes: pain clarity (is the
problem real and well-documented?), feasibility without a live runtime (can v1
be built and tested statically?), and differentiation (is there a gap a new
tool can actually fill?). fxpreflight scored highest on all three. The pain is
extensively documented in CFX forum threads going back several years, the entire
v1 rule set operates on text files so the rule engine can be developed and unit-
tested using a standalone Lua 5.4 interpreter against fixture files with no
FXServer required, and the competitive search confirmed that nobody has shipped
a dedicated offline validator.

The other candidates — which included an ACE permission visualizer, a resource
dependency grapher, a txAdmin theme marketplace, and several in-game HUD tools
— were either too dependent on a live runtime to build first, too narrowly
scoped to justify a standalone product, or already partially covered by txAdmin
or PerformanceSentry. fxpreflight is the one idea where we can ship something
genuinely useful to real server owners without waiting for infrastructure that
does not yet exist locally.

## Risks

- FiveM's cfg syntax could change in a future FXServer release, requiring
  regular rule-set maintenance to stay accurate.
- If txAdmin ships a static analysis feature before fxpreflight reaches v1,
  the differentiation narrows significantly.
- The tool's value proposition shrinks for experienced server owners who have
  already learned to avoid the common pitfalls — adoption may be concentrated
  at the beginner end of the market.
- The Lua resource format means the product must be marketed on Tebex and the
  CFX forum rather than through developer channels; discoverability depends on
  optimising for those platforms specifically.
