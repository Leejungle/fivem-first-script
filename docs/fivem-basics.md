# FiveM Basics — Beginner Cheatsheet

## What Is a Resource?

A FiveM resource is a self-contained package of scripts, assets, and
configuration that FXServer loads at startup. Each resource lives in its own
subfolder inside the server's `resources/` directory. FXServer will only load
a resource if it is listed in `server.cfg` with an `ensure` (or legacy `start`)
directive. Resources are the unit of deployment in FiveM — every script, UI
element, or game mode is a resource.

---

## fxmanifest.lua Minimal Example

Every resource must contain a file named `fxmanifest.lua` in its root folder.
A minimal valid manifest looks like this:

```lua
fx_version 'cerulean'
games { 'gta5' }

author 'YourName'
description 'What this resource does.'
version '1.0.0'

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}
```

Key fields:
- `fx_version` — required. Determines which FiveM API surface the resource
  targets. Use `'cerulean'` (the current version). Lua 5.4 is available from
  `'cerulean'` onwards.
- `games` — strongly recommended. Tells FXServer which game this resource is
  for (`'gta5'`, `'rdr3'`).
- `client_scripts` / `server_scripts` — lists of Lua (or JS) files to load.

---

## The [category] Bracket Convention

The `resources/` directory can use subdirectory grouping with square-bracket
folder names, for example `resources/[standalone]/myscript/`. FXServer treats
any folder whose name is wrapped in `[` `]` as a category folder — it is not
itself a resource, but its children are. The official documentation shows
examples with multiple levels of bracket folders (e.g.,
`[category]/[another]/resource/`); no strict depth limit is stated. This
convention keeps large resource directories organized but is purely cosmetic
from FXServer's perspective.

---

## server.cfg Basic Structure

`server.cfg` is read by FXServer at startup. It uses a simple line-based
directive format:

```
# This is a comment

endpoint_add_tcp "0.0.0.0:30120"
endpoint_add_udp "0.0.0.0:30120"

sv_licenseKey "cfx-your-key-here"
sv_hostname "My Server"
sv_maxclients 32

# Load resources
ensure mapmanager
ensure chat
ensure spawnmanager
ensure my-custom-resource
```

Important directives:
- `endpoint_add_tcp` / `endpoint_add_udp` — required for the server to bind
  to a port. Without both, the server will not accept connections.
- `sv_licenseKey` — your Cfx.re license key. Required for the server to appear
  in the server list.
- `ensure <name>` — tells FXServer to start and keep running a named resource.

---

## ACE Permissions in One Paragraph

FiveM's Access Control Entries (ACE) system controls who can do what on a
server. You define groups with `add_principal identifier.<steamid> group.<name>`
(assigning a player to a group) and grant permissions with `add_ace group.<name>
command.<cmd> allow` (granting a group the right to run a command). Scripts can
check permissions at runtime with `IsPlayerAceAllowed`. The system is
hierarchical: a principal can inherit from another via `add_principal
group.child group.parent`. All ACE directives live in `server.cfg`.

---

## Lua 5.4 Note — 5.3 Deprecated June 2025

FiveM supported both Lua 5.3 and Lua 5.4 for an extended period. As of
June 2025, Lua 5.3 has been deprecated and all Lua scripts now run on Lua 5.4
regardless of manifest settings. The `lua54 'yes'` manifest field is therefore
deprecated — it is accepted by FXServer but has no effect, and does not need to
be included in new resources. Resources that previously relied on Lua
5.3-specific behavior may encounter compatibility issues after the transition.
[UNVERIFIED: whether FXServer still emits a console warning for resources that
were written against Lua 5.3 and have not been updated.]

---

## Resource Lifecycle — onResourceStart

`onResourceStart` is a built-in FiveM event that fires on the server the moment
FXServer finishes loading a resource. Any resource can listen for it by
registering an `AddEventHandler('onResourceStart', function(resourceName) ...
end)` in a server-side script. The `resourceName` argument identifies which
resource just started. By comparing it to `GetCurrentResourceName()`, a resource
can detect its own start event and run initialization logic exactly once per
server boot.

fxpreflight uses this pattern to trigger the validator automatically: when
FXServer starts fxpreflight, the `onResourceStart` handler fires, the rule
engine runs against `server.cfg` and all `fxmanifest.lua` files, and the report
is written. No manual trigger is needed; the resource owner simply ensures
fxpreflight is listed in `server.cfg`.

---

## Official Documentation Links

- FiveM server setup guide:
  https://docs.fivem.net/docs/server-manual/setting-up-a-server-vanilla/
- fxmanifest.lua reference:
  https://docs.fivem.net/docs/scripting-reference/resource-manifest/resource-manifest/
- Native reference (client/server functions):
  https://docs.fivem.net/natives/
- ACE permissions guide:
  https://docs.fivem.net/docs/server-manual/access-control-list/
- CFX community forum:
  https://forum.cfx.re/
