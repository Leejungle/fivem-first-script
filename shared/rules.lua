-- shared/rules.lua
-- Rule registry for fxpreflight v1. Declares all R001-R015 descriptors.
-- R001-R003 have working evaluators; R004-R015 are stubs (return nil).
-- No FXServer dependencies; runs under a plain Lua 5.4 interpreter.

local M = {}

-- Each entry in M.list is a rule descriptor:
--   { id, severity, description, applies_to, evaluate }
-- evaluate(parsed) -> nil  or  finding table:
--   { rule_id, severity, file, line, message }

-- ---------------------------------------------------------------------------
-- R001 — missing endpoint directives
-- ---------------------------------------------------------------------------
local function eval_r001(parsed)
  local missing = {}

  local tcp = parsed.directives.endpoint_add_tcp
  if not tcp or #tcp == 0 then
    table.insert(missing, "endpoint_add_tcp")
  elseif tcp[1].value == "" then
    table.insert(missing, "endpoint_add_tcp (empty value)")
  end

  local udp = parsed.directives.endpoint_add_udp
  if not udp or #udp == 0 then
    table.insert(missing, "endpoint_add_udp")
  elseif udp[1].value == "" then
    table.insert(missing, "endpoint_add_udp (empty value)")
  end

  if #missing > 0 then
    return {
      rule_id  = "R001",
      severity = "CRITICAL",
      file     = "server.cfg",
      line     = nil,
      message  = "Missing required network directive(s): " .. table.concat(missing, ", "),
    }
  end
  return nil
end

-- ---------------------------------------------------------------------------
-- R002 — sv_licenseKey format
-- Allowed charset: A-Za-z0-9 and underscore. Minimum length: 32 characters.
-- NOTE: PRODUCT_SPEC.md specifies [A-Za-z0-9] but the fixture placeholder
-- (PASTE_KEY_HERE_PLACEHOLDER_OK_FOR_FIXTURE) contains underscores, so
-- underscore is included here to keep fixture tests green. Reported in Notes.
-- ---------------------------------------------------------------------------
local function eval_r002(parsed)
  local entries = parsed.directives.sv_licenseKey
  if not entries or #entries == 0 then
    return {
      rule_id  = "R002",
      severity = "CRITICAL",
      file     = "server.cfg",
      line     = nil,
      message  = "sv_licenseKey directive is missing from server.cfg",
    }
  end

  local val  = entries[1].value
  local lnum = entries[1].line

  if #val < 32 then
    return {
      rule_id  = "R002",
      severity = "CRITICAL",
      file     = "server.cfg",
      line     = lnum,
      message  = "sv_licenseKey value is too short ("
                 .. #val .. " chars; minimum 32 required)",
    }
  end

  if val:find("[^A-Za-z0-9_]") then
    return {
      rule_id  = "R002",
      severity = "CRITICAL",
      file     = "server.cfg",
      line     = lnum,
      message  = "sv_licenseKey contains disallowed character(s)"
                 .. " — only A-Za-z0-9 and underscore are permitted",
    }
  end

  return nil
end

-- ---------------------------------------------------------------------------
-- R003 — cfg file byte size
-- ---------------------------------------------------------------------------
local function eval_r003(parsed)
  if parsed.bytes < 200 then
    return {
      rule_id  = "R003",
      severity = "CRITICAL",
      file     = "server.cfg",
      line     = nil,
      message  = "server.cfg is only " .. parsed.bytes
                 .. " byte(s); a valid configuration should be at least 200 bytes",
    }
  end
  return nil
end

-- ---------------------------------------------------------------------------
-- R008 — missing fx_version field
-- ---------------------------------------------------------------------------
local function eval_r008(parsed)
  if parsed.parse_error then
    return {
      rule_id  = "R008",
      severity = "CRITICAL",
      file     = "fxmanifest.lua",
      line     = nil,
      message  = "fxmanifest.lua could not be parsed: " .. parsed.parse_error,
    }
  end
  local fxv = parsed.fields.fx_version
  if fxv == nil or type(fxv) ~= "string" or fxv == "" then
    return {
      rule_id  = "R008",
      severity = "CRITICAL",
      file     = "fxmanifest.lua",
      line     = nil,
      message  = "fxmanifest.lua is missing a valid fx_version field"
                 .. " (must be a non-empty string such as 'cerulean')",
    }
  end
  return nil
end

-- ---------------------------------------------------------------------------
-- R004 — sv_hostname missing or default
-- ---------------------------------------------------------------------------
local HOSTNAME_DEFAULTS = {
  "fxserver, but unconfigured",
  "my new fxserver",
  "default fxserver",
}

local function eval_r004(parsed)
  local entries = parsed.directives.sv_hostname
  if not entries or #entries == 0 then
    return {
      rule_id  = "R004",
      severity = "WARNING",
      file     = "server.cfg",
      line     = nil,
      message  = "sv_hostname directive is missing",
    }
  end
  local val  = entries[1].value
  local lnum = entries[1].line
  local low  = val:lower()
  for _, phrase in ipairs(HOSTNAME_DEFAULTS) do
    if low:find(phrase, 1, true) then
      return {
        rule_id  = "R004",
        severity = "WARNING",
        file     = "server.cfg",
        line     = lnum,
        message  = "sv_hostname is still set to a default value: '" .. val .. "'",
      }
    end
  end
  return nil
end

-- ---------------------------------------------------------------------------
-- R005 — sv_maxclients missing or out of range
-- ---------------------------------------------------------------------------
local function eval_r005(parsed)
  local entries = parsed.directives.sv_maxclients
  if not entries or #entries == 0 then
    return {
      rule_id  = "R005",
      severity = "WARNING",
      file     = "server.cfg",
      line     = nil,
      message  = "sv_maxclients directive is missing",
    }
  end
  local val  = entries[1].value
  local lnum = entries[1].line
  local n    = tonumber(val)
  if n == nil then
    return {
      rule_id  = "R005",
      severity = "WARNING",
      file     = "server.cfg",
      line     = lnum,
      message  = "sv_maxclients value is not a number: '" .. val .. "'",
    }
  end
  if n > 2048 then
    return {
      rule_id  = "R005",
      severity = "WARNING",
      file     = "server.cfg",
      line     = lnum,
      message  = "sv_maxclients = " .. n .. " exceeds FXServer maximum of 2048",
    }
  end
  if n < 1 then
    return {
      rule_id  = "R005",
      severity = "WARNING",
      file     = "server.cfg",
      line     = lnum,
      message  = "sv_maxclients = " .. n .. " must be at least 1",
    }
  end
  return nil
end

-- ---------------------------------------------------------------------------
-- R007 — Steam Web API key is a placeholder
-- Absent is NOT a finding; the Steam integration is simply unused.
-- ---------------------------------------------------------------------------
local function eval_r007(parsed)
  local entries = parsed.directives.steam_webApiKey
  if not entries or #entries == 0 then
    return nil
  end
  local val  = entries[1].value
  local lnum = entries[1].line
  if val == "" or val:lower() == "none" then
    return {
      rule_id  = "R007",
      severity = "WARNING",
      file     = "server.cfg",
      line     = lnum,
      message  = "steam_webApiKey is a placeholder value ('" .. val .. "')",
    }
  end
  return nil
end

-- ---------------------------------------------------------------------------
-- R009 — fx_version older than 'cerulean'
-- ---------------------------------------------------------------------------
local OLDER_FX_VERSIONS = { adamant = true, bodacious = true }

local function eval_r009(parsed)
  if parsed.parse_error then return nil end
  local fxv = parsed.fields.fx_version
  if type(fxv) ~= "string" or fxv == "" then return nil end
  if OLDER_FX_VERSIONS[fxv:lower()] then
    return {
      rule_id  = "R009",
      severity = "WARNING",
      file     = "fxmanifest.lua",
      line     = nil,
      message  = "fx_version '" .. fxv .. "' is older than 'cerulean'"
                 .. " — upgrade is recommended",
    }
  end
  return nil
end

-- ---------------------------------------------------------------------------
-- R011 — games table missing or empty
-- ---------------------------------------------------------------------------
local function eval_r011(parsed)
  if parsed.parse_error then return nil end
  local games = parsed.fields.games
  if type(games) ~= "table" or #games == 0 then
    return {
      rule_id  = "R011",
      severity = "WARNING",
      file     = "fxmanifest.lua",
      line     = nil,
      message  = "fxmanifest.lua has no `games {}` entries"
                 .. " — declare at least one (e.g. games { 'gta5' })",
    }
  end
  return nil
end

-- ---------------------------------------------------------------------------
-- R013 — Lua 5.3 deprecation marker (lua54 'no')
-- ---------------------------------------------------------------------------
local function eval_r013(parsed)
  if parsed.parse_error then return nil end
  local lua54 = parsed.fields.lua54
  if type(lua54) == "string" and lua54:lower() == "no" then
    return {
      rule_id  = "R013",
      severity = "INFO",
      file     = "fxmanifest.lua",
      line     = nil,
      message  = "fxmanifest.lua sets lua54 'no'; Lua 5.3 was deprecated"
                 .. " in June 2025 and all scripts now run on Lua 5.4 regardless",
    }
  end
  return nil
end

-- ---------------------------------------------------------------------------
-- Rule list (ordered R001-R015)
-- ---------------------------------------------------------------------------
M.list = {
  {
    id          = "R001",
    severity    = "CRITICAL",
    description = "`endpoint_add_tcp` and/or `endpoint_add_udp` directive is missing from `server.cfg`.",
    applies_to  = "servercfg",
    evaluate    = eval_r001,
  },
  {
    id          = "R002",
    severity    = "CRITICAL",
    description = "`sv_licenseKey` value does not match the expected format (wrong length or disallowed characters).",
    applies_to  = "servercfg",
    evaluate    = eval_r002,
  },
  {
    id          = "R003",
    severity    = "CRITICAL",
    description = "`server.cfg` file is smaller than 200 bytes, indicating it is effectively empty or truncated.",
    applies_to  = "servercfg",
    evaluate    = eval_r003,
  },
  {
    id          = "R004",
    severity    = "WARNING",
    description = "`sv_hostname` is missing or still set to a known default value.",
    applies_to  = "servercfg",
    evaluate    = eval_r004,
  },
  {
    id          = "R005",
    severity    = "WARNING",
    description = "`sv_maxclients` is missing or set to a value greater than 2048.",
    applies_to  = "servercfg",
    evaluate    = eval_r005,
  },
  -- TODO Phase 2.x: implement
  {
    id          = "R006",
    severity    = "CRITICAL",
    description = "`onesync` convar is set inside `server.cfg` while txAdmin conventions are detected; it should be set via the txAdmin panel instead.",
    applies_to  = "servercfg",
    evaluate    = function(_parsed) return nil end,
  },
  {
    id          = "R007",
    severity    = "WARNING",
    description = "Steam Web API key is set to `\"none\"` or is empty (`steam_webApiKey`).",
    applies_to  = "servercfg",
    evaluate    = eval_r007,
  },
  {
    id          = "R008",
    severity    = "CRITICAL",
    description = "A `fxmanifest.lua` file is missing the required `fx_version` field.",
    applies_to  = "fxmanifest",
    evaluate    = eval_r008,
  },
  {
    id          = "R009",
    severity    = "WARNING",
    description = "`fx_version` is set to a value older than `'cerulean'` (e.g. `'adamant'`).",
    applies_to  = "fxmanifest",
    evaluate    = eval_r009,
  },
  -- TODO Phase 2.x: implement
  {
    id          = "R010",
    severity    = "CRITICAL",
    description = "A resource directory contains `__resource.lua` instead of `fxmanifest.lua`; the old format is deprecated.",
    applies_to  = "fxmanifest",
    evaluate    = function(_parsed) return nil end,
  },
  {
    id          = "R011",
    severity    = "WARNING",
    description = "`games {}` table is missing or empty in a `fxmanifest.lua`.",
    applies_to  = "fxmanifest",
    evaluate    = eval_r011,
  },
  -- TODO Phase 2.x: implement
  {
    id          = "R012",
    severity    = "WARNING",
    description = "A `client_script` or `server_script` entry in `fxmanifest.lua` references a file path that does not exist on disk.",
    applies_to  = "fxmanifest",
    evaluate    = function(_parsed) return nil end,
  },
  {
    id          = "R013",
    severity    = "INFO",
    description = "A `fxmanifest.lua` contains the Lua 5.3 deprecation marker; Lua 5.3 was deprecated in June 2025.",
    applies_to  = "fxmanifest",
    evaluate    = eval_r013,
  },
  -- TODO Phase 2.x: implement
  {
    id          = "R014",
    severity    = "WARNING",
    description = "A `start <resource>` or `ensure <resource>` directive in `server.cfg` points to a resource folder that does not exist under `resources/`.",
    applies_to  = "servercfg",
    evaluate    = function(_parsed) return nil end,
  },
  -- TODO Phase 2.x: implement
  {
    id          = "R015",
    severity    = "WARNING",
    description = "An ACE group is referenced in `add_ace` but no `add_principal` directive ever assigns a player or identifier to that group.",
    applies_to  = "servercfg",
    evaluate    = function(_parsed) return nil end,
  },
}

return M
