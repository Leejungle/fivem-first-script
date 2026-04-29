# ADR 0002 — Pivot to Pure-Lua FiveM Resource

**Status:** Accepted  
**Date:** 2026-04-29

---

## Context

Real FiveM products are sold as Lua resources via Tebex with escrow protection.
A CLI tool written in Node.js has no precedent in the FiveM marketplace: buyers
do not install Node.js runtimes, do not run terminal commands to validate their
servers, and would not find such a tool through Tebex or the CFX forum. A
Node.js CLI binary cannot be submitted to Tebex escrow, which is the standard
mechanism for protecting FiveM script sales from piracy.

Buyers of FiveM tools expect a drop-in resource: copy a folder into
`resources/`, add one line to `server.cfg`, restart. Every established FiveM
tool — paid or free — follows this distribution format. Deviating from it
increases buyer friction to the point where the product would not sell through
the standard channels.

The primary developer does not yet have a stable FXServer runtime available
locally. This means a server-side resource cannot be integration-tested
immediately, but the core rule engine logic (parsing text files and applying
rules) is entirely independent of FXServer and can be developed and tested using
a standalone Lua 5.4 interpreter against fixture files. FXServer is only needed
for the final integration step.

ADR 0001 chose Node.js + TypeScript under the assumption of a CLI tool. That
assumption has been invalidated by the market research above.

## Decision

Pivot v1 to a pure-Lua FiveM resource.

The resource is installed by dropping the `fxpreflight/` folder into
`resources/[tools]/fxpreflight/` and adding `ensure fxpreflight` to
`server.cfg`. Validation is triggered by an `onResourceStart` event handler in
`server/main.lua` and runs once per server boot.

All rule engine logic lives in `shared/` Lua files. These files are unit-tested
using a standalone Lua 5.4 interpreter (`lua.exe`) running a Lua test runner
against the fixture files in `/fixtures/` at the workspace root (these will be
copied into the shipped resource's `tests/fixtures/` at packaging time). No FXServer instance is required
for this development phase. The `server/main.lua` wrapper that wires the engine
to the FiveM API will be written once a local FXServer runtime is available.

The product is listed on Tebex with escrow protection, matching the standard
distribution and monetization model for the FiveM marketplace.

## Consequences

**Positive:**

- Matches the distribution format buyers expect; zero additional friction at
  install time compared to any other FiveM resource.
- Lua resources are eligible for Tebex escrow, enabling standard copy-
  protection for paid sales.
- A single Lua codebase is directly reusable for v2 and v3 add-on modules
  without a bridge layer or port.
- Marketing through Tebex and the CFX forum is frictionless; the product
  belongs in the same category as every other tool on those platforms.
- The rule engine can be developed offline using a standalone Lua interpreter,
  unblocking Phase 2 without waiting for a local FXServer.

**Negative:**

- Lua provides weaker developer experience than TypeScript: no compile-time
  type checking, no first-class package manager, and thinner IDE tooling.
- Some parsing logic must be hand-rolled in Lua (e.g. `fxmanifest.lua` is
  parsed by running it through `load()` in a sandboxed environment) rather
  than using a well-tested npm library.
- The `server/main.lua` FiveM API wrapper cannot be tested until a local
  FXServer runtime is available, introducing a late-stage integration risk.
