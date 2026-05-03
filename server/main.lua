-- server/main.lua
-- fxpreflight resource entry point.
-- Sub-phase 2.1: load the 4 shared modules and verify their API contract.
-- Sub-phase 2.2: on onResourceStart, also read server.cfg, run every rule
-- whose applies_to == 'servercfg', and print the formatted preflight report
-- block to the FXServer console.
-- Out of scope (deferred to later sub-phases): scanning resources/ for
-- fxmanifest.lua files, writing fxpreflight_report.md to disk, and any
-- network calls (Discord webhook).

local RESOURCE = GetCurrentResourceName()
local PREFIX   = '[fxpreflight] '
local VERSION  = '0.1.0'

-- ---------------------------------------------------------------------------
-- loadShared(rel_path) -> table
-- Loads a shared/ Lua module from this resource's folder and returns the
-- table it returned (the "local M = {} ... return M" pattern). Errors loudly
-- so a broken module is impossible to ignore.
-- ---------------------------------------------------------------------------
local function loadShared(rel_path)
  local source = LoadResourceFile(RESOURCE, rel_path)
  if not source then
    error(PREFIX .. 'LoadResourceFile failed for ' .. rel_path)
  end
  local chunk, compile_err = load(source, '@' .. rel_path, 't')
  if not chunk then
    error(PREFIX .. 'compile error in ' .. rel_path .. ': ' .. tostring(compile_err))
  end
  local ok, mod_or_err = pcall(chunk)
  if not ok then
    error(PREFIX .. 'runtime error in ' .. rel_path .. ': ' .. tostring(mod_or_err))
  end
  if type(mod_or_err) ~= 'table' then
    error(PREFIX .. rel_path .. ' did not return a table (got ' .. type(mod_or_err) .. ')')
  end
  return mod_or_err
end

local parser_cfg      = loadShared('shared/parser_servercfg.lua')
local parser_manifest = loadShared('shared/parser_fxmanifest.lua')
local rules           = loadShared('shared/rules.lua')
local reporter        = loadShared('shared/reporter.lua')

-- API contract assertions: loud failure if a module drifts later.
assert(type(parser_cfg.parse_string)        == 'function', 'parser_servercfg.parse_string missing')
assert(type(parser_cfg.parse_file)          == 'function', 'parser_servercfg.parse_file missing')
assert(type(parser_manifest.parse_string)   == 'function', 'parser_fxmanifest.parse_string missing')
assert(type(parser_manifest.parse_file)     == 'function', 'parser_fxmanifest.parse_file missing')
assert(type(rules.list)                     == 'table',    'rules.list missing')
assert(type(reporter.summarize)             == 'function', 'reporter.summarize missing')
assert(type(reporter.format_console)        == 'function', 'reporter.format_console missing')
assert(type(reporter.format_markdown)       == 'function', 'reporter.format_markdown missing')

-- ---------------------------------------------------------------------------
-- readServerCfg() -> (text, source_label) | (nil, nil)
-- Reads the boot-time snapshot of server.cfg that start.bat copies into the
-- resource folder. We use LoadResourceFile (FiveM-native) instead of io.open
-- because FiveM sandboxes io.open server-side and refuses to read files
-- outside the resource folder, even when the file exists and is readable
-- by the underlying OS process (verified on 2026-05-03 against
-- F:\FXServer\server-data\server.cfg). The snapshot is regenerated every
-- boot, so a typical edit-and-restart workflow always sees fresh content.
-- ---------------------------------------------------------------------------
local function readServerCfg()
  local snapshot = LoadResourceFile(RESOURCE, 'server.cfg.runtime')
  if snapshot and snapshot ~= '' then
    return snapshot, 'server.cfg.runtime (boot-time snapshot)'
  end

  print(PREFIX .. 'ERROR: server.cfg.runtime is missing or empty.')
  print(PREFIX .. '       start.bat must snapshot server.cfg into the resource')
  print(PREFIX .. '       folder before FXServer boots. Add this line to')
  print(PREFIX .. '       F:\\FXServer\\server-data\\start.bat (before FXServer.exe):')
  print(PREFIX .. '         copy /Y server.cfg resources\\fxpreflight\\server.cfg.runtime > nul')
  return nil, nil
end

-- ---------------------------------------------------------------------------
-- collectServerCfgFindings(parsed) -> findings array
-- Iterates the rule registry and runs every rule whose applies_to is
-- 'servercfg'. Stub rules (R006, R014, R015 at this sub-phase) return nil
-- and contribute nothing.
-- ---------------------------------------------------------------------------
local function collectServerCfgFindings(parsed)
  local findings = {}
  for _, rule in ipairs(rules.list) do
    if rule.applies_to == 'servercfg' then
      local result = rule.evaluate(parsed)
      if result then
        table.insert(findings, result)
      end
    end
  end
  return findings
end

-- ---------------------------------------------------------------------------
-- printBlock(block) -> nil
-- Splits a multi-line string and prints each line via print(), so every
-- visible console row carries the FiveM '[script:fxpreflight]' prefix
-- instead of one prefix for the whole block plus prefix-less continuation
-- lines.
-- ---------------------------------------------------------------------------
local function printBlock(block)
  for line in block:gmatch('([^\n]+)') do
    print(line)
  end
end

AddEventHandler('onResourceStart', function(name)
  if name ~= RESOURCE then return end

  print(string.format(
    '%sv%s skeleton OK -- modules loaded: 4, rules registered: %d',
    PREFIX, VERSION, #rules.list))

  -- Sub-phase 2.2: server.cfg ingestion -------------------------------------
  local cfg_text, cfg_path_used = readServerCfg()
  if not cfg_text then
    return
  end

  local parsed   = parser_cfg.parse_string(cfg_text)
  local findings = collectServerCfgFindings(parsed)
  local summary  = reporter.summarize(findings)
  local block    = reporter.format_console(summary)

  print(string.format('%spreflight on %s -- %d bytes parsed',
    PREFIX, cfg_path_used, parsed.bytes))
  printBlock(block)
end)
