# ADR 0001 — Language Choice for v1

**Status:** Superseded by 0002  
**Date:** 2026-04-29

This ADR was based on the assumption that fxpreflight would ship as a standalone
CLI tool. Subsequent market research confirmed that sellable FiveM products are
distributed as Lua resources via Tebex escrow. The CLI assumption is therefore
invalid. See ADR 0002 for the accepted decision.

---

## Context

fxpreflight needs to parse plain-text files (`server.cfg`, `fxmanifest.lua`),
walk a directory tree, apply a set of rules, and print a report. The tool must
be usable without a running FXServer instance. The primary developer does not
yet have a stable FXServer runtime available locally.

Two candidate languages were evaluated: **Lua** (the language used inside
FiveM resources) and **Node.js with TypeScript** (a mainstream, standalone
runtime).

Lua was considered because it is native to FiveM and would make a future
in-game resource wrapper straightforward. However, Lua has no standard
package manager with broad ecosystem support, its standard library for
filesystem operations is minimal, and running a standalone Lua script requires
either installing a Lua interpreter separately or shipping it alongside the
tool — neither of which is a good developer experience on Windows. More
critically, the Lua testing ecosystem is thin, making fixture-based TDD harder
to set up quickly.

Node.js with TypeScript is a mature standalone runtime, ships with `npm` for
dependency management, has first-class filesystem APIs, and has an excellent
testing ecosystem (Jest, Vitest). TypeScript adds static type-checking, which
is valuable when defining a rule engine with multiple data shapes. Both are
already installed or trivially installable on any developer machine.

## Decision

Use **Node.js + TypeScript** for v1 of fxpreflight.

The tool is a CLI application that runs outside FiveM, not a FiveM resource.
Choosing a language because of its FiveM affinity is premature optimisation at
this stage. Node.js provides everything needed for v1 with no trade-offs, and
the rule engine logic is entirely language-agnostic — if a future phase wraps
fxpreflight as an in-game resource, the parsing and rule logic can be ported
or called via a child process.

## Consequences

- **Positive:** Developers can run `fxpreflight` from any terminal without
  installing FXServer or a Lua runtime.
- **Positive:** npm ecosystem gives immediate access to well-tested libraries
  for argument parsing, file walking, and test running.
- **Positive:** TypeScript interfaces make the rule registry and finding types
  self-documenting and catch shape errors at compile time.
- **Negative:** The codebase is in a different language from FiveM resources,
  so a contributor who only knows Lua will face a small learning curve.
- **Negative:** When v1.5 wraps the tool as an in-game resource, a bridge
  layer (child process or HTTP) will be needed rather than a direct Lua import.
  This is acceptable and planned for.
