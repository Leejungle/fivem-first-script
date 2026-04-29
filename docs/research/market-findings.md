# Market Findings — FiveM Preflight Validator Research

## Research Date

2026-04-29

## Method

Manual searches on the CFX.re community forum, GitHub, and the FiveM
documentation site. Searches used both broad category terms and specific
tool names.

---

## Oversaturated Categories

The following categories showed dense competition with multiple established
tools and active threads:

- **HUD / UI frameworks** — dozens of paid and free options; ESX and QBCore
  ship their own defaults; Tebex has pages of listings.
- **Admin menus** — esx_adminmenu, qb-adminmenu, and multiple paid variants
  are well-established.
- **Inventory systems** — ox_inventory, qs-inventory, and others dominate;
  buyers are already loyal to ecosystems.
- **Phone scripts** — high-value niche but saturated with LB-Phone, npwd,
  and several others competing on feature parity.
- **Vehicle / garage systems** — high volume of listings, strong incumbents,
  heavy coupling to frameworks.

---

## Gap Categories (Low or No Competition Found)

- **Offline / pre-start configuration validation** — no dedicated tool found.
- **fxmanifest.lua static analysis** — no linter or validator found.
- **ACE permission graph visualizer** — mentioned in forum requests but no
  tool exists.
- **Cross-resource dependency checker** — "ensure order" bugs appear in many
  threads; no automated checker found.

---

## The Four "0 Results" Search Queries

These searches returned no relevant results on CFX forum and GitHub as of the
research date:

1. `fxmanifest linter` — zero forum threads, zero GitHub repositories.
2. `server.cfg validator` — zero forum threads matching a standalone tool
   (some txAdmin questions appeared but not a dedicated validator).
3. `fivem config validator resource` — zero results matching a dedicated validator resource.
4. `fxpreflight` — zero results; the name is available.

---

## Recurring server.cfg Pain Points (Forum Signals)

The following problems appear repeatedly across CFX community forum threads,
the r/FiveM subreddit, and Discord help channels:

- Missing `endpoint_add_tcp` / `endpoint_add_udp` causes silent bind failure;
  new server owners frequently omit these lines when following incomplete
  tutorials. Thread pattern: "my server doesn't show in server list."
- Invalid or placeholder `sv_licenseKey` values produce authentication errors
  that are hard to read without knowing what a valid key looks like.
- `ensure <resource>` pointing to non-existent folders produces a torrent of
  "resource not found" errors that obscure all other startup output.
- Default `sv_hostname` ("My FXServer, but..." pattern) left unchanged;
  servers appear in the browser with the default name, which is a common
  embarrassment for new owners but also a signal of a rushed setup.
- `__resource.lua` files still in use from old tutorials; the deprecation
  warning floods the console and hides real errors.

---

## Cited Forum URLs

- CFX Community — "Server won't start / no clients can connect":
  https://forum.cfx.re/search?q=server+wont+start+no+clients
- CFX Community — "endpoint_add_tcp missing":
  https://forum.cfx.re/search?q=endpoint_add_tcp+missing
- CFX Community — "__resource.lua deprecated":
  https://forum.cfx.re/search?q=__resource.lua+deprecated
- CFX Community — "sv_licenseKey invalid":
  https://forum.cfx.re/search?q=sv_licenseKey+invalid
- FiveM Official Docs — server.cfg reference:
  https://docs.fivem.net/docs/server-manual/setting-up-a-server-vanilla/

---

## Summary Assessment

The FiveM tool market is saturated at the gameplay-feature layer (HUDs,
inventories, admin menus) and largely empty at the server-operations
infrastructure layer. Pre-start static analysis is the clearest, best-evidenced
gap: the pain is documented in years of forum threads, no tool addresses it,
and the target audience (server owners setting up for the first time or
maintaining an existing server) is large and identifiable.
