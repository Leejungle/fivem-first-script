# Product Spec — fxpreflight v1

## Resource Layout

```
fxpreflight/
├── fxmanifest.lua              (Phase 2 will create)
├── config.lua                  (Phase 2)
├── shared/
│   ├── rules.lua
│   ├── parser_servercfg.lua
│   ├── parser_fxmanifest.lua
│   └── reporter.lua
├── server/
│   └── main.lua
└── tests/
    ├── run.lua
    └── fixtures/
```

> **Development vs shipped layout:** The directory tree above shows the shipped
> resource structure — the folder hierarchy as it will exist when fxpreflight is
> packaged and dropped into a buyer's `resources/` folder. During development in
> this workspace, the rule-engine fixture files live at `/fixtures/` in the
> workspace root, not inside the resource tree. Phase 2 will copy or symlink
> them into the resource's `tests/fixtures/` folder when the resource is
> assembled for integration testing or packaging.

## Activation

Add the following line to `server.cfg`:

```
ensure fxpreflight
```

Restart FXServer. The validator runs once at startup and exits cleanly. No
further interaction is required.

## Trigger

fxpreflight registers a single event handler in `server/main.lua`:

```lua
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    -- run the validator
end)
```

`onResourceStart` fires when FXServer finishes loading a resource. Because
fxpreflight listens for its own resource name, validation runs exactly once per
server start, after all other resources have been enumerated by FXServer.

## Inputs

- **`server.cfg`** — located in the server data folder. The path is resolved
  by walking upward from `GetResourcePath(GetCurrentResourceName())` until
  `server.cfg` is found.
- **`fxmanifest.lua` files** — discovered by recursively walking the
  `resources/` directory tree relative to the server data folder.

## Outputs

- **Console log lines** — each finding is printed to the FXServer console with
  a severity prefix (`[CRITICAL]`, `[WARNING]`, `[INFO]`).
- **`fxpreflight_report.md`** — a Markdown summary written to the server data
  folder alongside `server.cfg`. Findings are grouped by severity.
- **Discord webhook** (optional) — when a webhook URL is configured in
  `config.lua`, the report is sent via `PerformHttpRequest`.

## Severity Model

| Severity | Meaning |
|----------|---------|
| CRITICAL | The server is likely misconfigured in a way that will cause startup failure or severe functional problems. |
| WARNING  | Something is non-standard or potentially problematic; the server may still start but the configuration should be reviewed. |
| INFO     | Informational notice; the server functions correctly but the finding is worth knowing. |

## Rule List v1

Each rule has an ID, severity, and short description. The rule engine applies
all rules that are relevant to the file type being processed.

| ID   | Severity | Description |
|------|----------|-------------|
| R001 | CRITICAL | `endpoint_add_tcp` and/or `endpoint_add_udp` directive is missing from `server.cfg`. |
| R002 | CRITICAL | `sv_licenseKey` value does not match the expected format (wrong length, or characters outside the allowed `[A-Za-z0-9_]` charset). |
| R003 | CRITICAL | `server.cfg` file is smaller than 200 bytes, indicating it is effectively empty or truncated. |
| R004 | WARNING  | `sv_hostname` is missing or still set to a known default value. |
| R005 | WARNING  | `sv_maxclients` is missing or set to a value greater than 2048. |
| R006 | CRITICAL | `onesync` convar is set inside `server.cfg` while txAdmin conventions are detected; it should be set via the txAdmin panel instead. |
| R007 | WARNING  | Steam Web API key is set to `"none"` or is empty (`steam_webApiKey`). |
| R008 | CRITICAL | A `fxmanifest.lua` file is missing the required `fx_version` field. |
| R009 | WARNING  | `fx_version` is set to a value older than `'cerulean'` (e.g. `'adamant'`). |
| R010 | CRITICAL | A resource directory contains `__resource.lua` instead of `fxmanifest.lua`; the old format is deprecated. |
| R011 | WARNING  | `games {}` table is missing or empty in a `fxmanifest.lua`. |
| R012 | WARNING  | A `client_script` or `server_script` entry in `fxmanifest.lua` references a file path that does not exist on disk. |
| R013 | INFO     | A `fxmanifest.lua` contains the Lua 5.3 deprecation marker; Lua 5.3 was deprecated in June 2025. |
| R014 | WARNING  | A `start <resource>` or `ensure <resource>` directive in `server.cfg` points to a resource folder that does not exist under `resources/`. |
| R015 | WARNING  | An ACE group is referenced in `add_ace` but no `add_principal` directive ever assigns a player or identifier to that group. |

## Out of Scope for v1

- No NUI or in-game web panel.
- No auto-fixing of detected problems.
- No live watch mode or continuous monitoring.
- No runtime validation (connecting to a live FXServer or querying any API).
- No framework-specific checks (ESX, QBCore, QBOX, or any other framework).
- No SQL schema or database connectivity validation.
- No asset file integrity checks (streaming files, audio, textures).
- No network reachability testing (DNS, port scanning).
- No rules beyond R001–R015 listed above.

## shared/ File Responsibilities

| File | Responsibility |
|------|----------------|
| `rules.lua` | Declares the rule registry: each rule's ID, severity, description, and a reference to its evaluator function. |
| `parser_servercfg.lua` | Reads `server.cfg` as plain text and returns a structured table of directives for the rule engine to evaluate. |
| `parser_fxmanifest.lua` | Loads `fxmanifest.lua` files in a sandboxed Lua environment using `load()` and returns a structured table of manifest fields. |
| `reporter.lua` | Formats findings into console log lines and the Markdown report; handles optional Discord webhook dispatch. |
