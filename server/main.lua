-- server/main.lua
-- fxpreflight resource entry point.
-- Sub-phase 2.1: load the 4 shared modules and verify their API contract.
-- Sub-phase 2.2: on onResourceStart, also read server.cfg, run every rule
-- whose applies_to == 'servercfg', and print the formatted preflight report
-- block to the FXServer console.
-- Sub-phase 2.3: also enumerate every loaded resource via FiveM natives,
-- read its fxmanifest.lua (or legacy __resource.lua) via LoadResourceFile,
-- run every rule whose applies_to == 'fxmanifest', and merge those findings
-- with the servercfg findings into a single report.
-- Sub-phase 2.3.5: skip Cfx-shipped default resources (DEFAULT_CFX_RESOURCES)
-- to keep the signal-to-noise ratio sane for v0.1.
-- Sub-phase 2.4: persist every preflight run to disk via SaveResourceFile so
-- the user can review or share the report without re-reading the FXServer
-- console. Two files land alongside the resource:
--   * fxpreflight_report.md  -- markdown, just the findings (shareable)
--   * fxpreflight_run.log    -- verbatim console output of the run (debug)
-- Both are gitignored. Every line printed by the preflight is also captured
-- in LOG_BUFFER and written to fxpreflight_run.log on completion.
-- Sub-phase 2.5: a console command 'fxpreflight' (RegisterCommand, restricted)
-- reruns the preflight without restarting the resource, which is much faster
-- than 'restart fxpreflight' during iterative development.
-- Out of scope (deferred): Discord webhook, HTML report, config.lua.

local RESOURCE = GetCurrentResourceName()
local PREFIX   = '[fxpreflight] '
local VERSION  = '0.1.0'

-- ---------------------------------------------------------------------------
-- DEFAULT_CFX_RESOURCES
-- Resources that ship with FXServer itself or with the official Cfx default
-- resources bundle. They are maintained by Cfx, intentionally pin legacy
-- fx_version values for backward compat, and a server owner cannot
-- meaningfully "fix" the warnings fxpreflight would emit against them.
-- Skipping them keeps the v0.1 report focused on resources the user actually
-- installed and owns. Verified on a fresh FXServer + default-resources build
-- on 2026-05-06; revisit in v0.2 when config.lua lets the user override.
-- ---------------------------------------------------------------------------
local DEFAULT_CFX_RESOURCES = {
  -- Core / system
  ['fivem']                       = true,
  ['fivem-map-hipster']           = true,
  ['fivem-map-skater']            = true,
  ['mapmanager']                  = true,
  ['monitor']                     = true,
  ['sessionmanager']              = true,
  ['sessionmanager-rdr3']         = true,
  ['webpack']                     = true,
  ['yarn']                        = true,

  -- Standard gameplay / RP scaffolding
  ['baseevents']                  = true,
  ['basic-gamemode']              = true,
  ['chat']                        = true,
  ['chat-theme-gtao']             = true,
  ['hardcap']                     = true,
  ['playernames']                 = true,
  ['rconlog']                     = true,
  ['runcode']                     = true,
  ['spawnmanager']                = true,

  -- Bundled examples / tutorials
  ['example-loadscreen']          = true,
  ['money']                       = true,
  ['money-fountain']              = true,
  ['money-fountain-example-map']  = true,
  ['ped-money-drops']             = true,
  ['player-data']                 = true,

  -- RedM
  ['redm-map-one']                = true,
}

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
-- LOG_BUFFER + say(line) -> nil
-- A per-run buffer of console lines. say() both prints to the FXServer
-- console (so the user still sees real-time output) AND appends to the
-- buffer so the run can be persisted to fxpreflight_run.log without
-- having to re-implement formatting. Reset at the start of every
-- runPreflight() invocation so each log file represents exactly one run.
-- ---------------------------------------------------------------------------
local LOG_BUFFER = {}

local function say(line)
  print(line)
  LOG_BUFFER[#LOG_BUFFER + 1] = line
end

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

  say(PREFIX .. 'ERROR: server.cfg.runtime is missing or empty.')
  say(PREFIX .. '       start.bat must snapshot server.cfg into the resource')
  say(PREFIX .. '       folder before FXServer boots. Add this line to')
  say(PREFIX .. '       F:\\FXServer\\server-data\\start.bat (before FXServer.exe):')
  say(PREFIX .. '         copy /Y server.cfg resources\\fxpreflight\\server.cfg.runtime > nul')
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
-- listOtherResources() -> array of resource names (excluding fxpreflight)
-- Walks every loaded resource at the moment of the call. Resources that
-- start AFTER fxpreflight will not be visible here; v0.1 documents that
-- fxpreflight should be ensured near the bottom of server.cfg so the
-- preflight scan sees the full set. A future /fxpreflight rescan command
-- (Sub-phase 2.5+) will lift this constraint.
-- ---------------------------------------------------------------------------
local function listOtherResources()
  local list = {}
  for i = 0, GetNumResources() - 1 do
    local name = GetResourceByFindIndex(i)
    if name and name ~= RESOURCE then
      table.insert(list, name)
    end
  end
  return list
end

-- ---------------------------------------------------------------------------
-- readManifestSource(resourceName) -> (text, filename) | (nil, nil)
-- Reads the manifest source of another resource via LoadResourceFile (which
-- IS allowed cross-resource, unlike io.open). Modern resources use
-- 'fxmanifest.lua'; very old ones still use the legacy '__resource.lua'.
-- We try both so the scan stays useful on long-running servers with mixed
-- resource generations.
-- ---------------------------------------------------------------------------
local function readManifestSource(resourceName)
  local src = LoadResourceFile(resourceName, 'fxmanifest.lua')
  if src and src ~= '' then return src, 'fxmanifest.lua' end
  src = LoadResourceFile(resourceName, '__resource.lua')
  if src and src ~= '' then return src, '__resource.lua' end
  return nil, nil
end

-- ---------------------------------------------------------------------------
-- collectFxManifestFindings() -> (findings, scanned, with_manifest, skipped)
-- For every other loaded resource that is NOT in DEFAULT_CFX_RESOURCES,
-- parse its manifest and run every 'fxmanifest' rule. Each finding is
-- annotated with the resource name in finding.file so the report is
-- unambiguous when multiple resources fire the same rule. Both the parser
-- call and each rule evaluation are wrapped in pcall so a single broken
-- manifest or buggy rule cannot prevent the rest of the scan from running.
-- The 'skipped' counter reports how many Cfx-shipped defaults were filtered
-- out so the user can see fxpreflight is aware of them, not ignoring silently.
-- ---------------------------------------------------------------------------
local function collectFxManifestFindings()
  local findings      = {}
  local scanned       = 0
  local with_manifest = 0
  local skipped       = 0

  for _, name in ipairs(listOtherResources()) do
    if DEFAULT_CFX_RESOURCES[name] then
      skipped = skipped + 1
    else
      scanned = scanned + 1
      local src, file_used = readManifestSource(name)
      if src then
        with_manifest = with_manifest + 1
        local ok_parse, parsed = pcall(parser_manifest.parse_string, src)
        if ok_parse and parsed then
          for _, rule in ipairs(rules.list) do
            if rule.applies_to == 'fxmanifest' then
              local ok_eval, result = pcall(rule.evaluate, parsed)
              if ok_eval and result then
                result.file = name .. '/' .. file_used
                table.insert(findings, result)
              end
            end
          end
        end
      end
    end
  end

  return findings, scanned, with_manifest, skipped
end

-- ---------------------------------------------------------------------------
-- sayBlock(block) -> nil
-- Splits a multi-line string and routes each line through say(), so every
-- visible console row carries the FiveM '[script:fxpreflight]' prefix AND
-- gets captured into LOG_BUFFER for persistence.
-- ---------------------------------------------------------------------------
local function sayBlock(block)
  for line in block:gmatch('([^\n]+)') do
    say(line)
  end
end

-- ---------------------------------------------------------------------------
-- flushReport(summary) -> nil
-- Persists the just-finished run as two sibling files inside the resource
-- folder (which is the only place the FiveM sandbox lets us write):
--   * fxpreflight_report.md  -- the user-facing markdown report
--   * fxpreflight_run.log    -- the literal console output of this run
-- The .md file is the one a server owner would paste into a forum or
-- Discord; the .log file is for debugging and for the dev workflow where
-- the next chat turn can read the run output directly without anyone
-- having to copy-paste from the FXServer console.
-- ---------------------------------------------------------------------------
local function flushReport(summary)
  local md = reporter.format_markdown(summary)
  local ok_md = SaveResourceFile(RESOURCE, 'fxpreflight_report.md', md, -1)
  if ok_md then
    say(string.format('%sreport written -> fxpreflight_report.md (%d bytes)',
      PREFIX, #md))
  else
    say(PREFIX .. 'WARNING: failed to write fxpreflight_report.md')
  end

  -- Write the log LAST so the report-written status line above is included.
  local logtext = table.concat(LOG_BUFFER, '\n') .. '\n'
  local ok_log = SaveResourceFile(RESOURCE, 'fxpreflight_run.log', logtext, -1)
  if not ok_log then
    -- Cannot persist the failure to the log file, but still surface it
    -- in the live console so the user notices immediately.
    print(PREFIX .. 'WARNING: failed to write fxpreflight_run.log')
  end
end

-- ---------------------------------------------------------------------------
-- runPreflight() -> nil
-- The full preflight pipeline: read snapshot, parse, run servercfg rules,
-- scan resources, run fxmanifest rules, merge, summarise, format, print,
-- persist. Extracted from the onResourceStart handler so the same code
-- path runs from RegisterCommand('fxpreflight', ...) too.
-- ---------------------------------------------------------------------------
local function runPreflight()
  -- Reset the per-run buffer so each fxpreflight_run.log represents
  -- exactly one run rather than concatenated history.
  LOG_BUFFER = {}

  say(string.format(
    '%sv%s preflight starting -- modules loaded: 4, rules registered: %d',
    PREFIX, VERSION, #rules.list))

  -- Sub-phase 2.2: server.cfg ingestion -------------------------------------
  local cfg_text, cfg_path_used = readServerCfg()
  if not cfg_text then
    -- readServerCfg() already explained the problem via say(); persist what
    -- we have so the dev workflow can still see why the run aborted.
    SaveResourceFile(RESOURCE, 'fxpreflight_run.log',
      table.concat(LOG_BUFFER, '\n') .. '\n', -1)
    return
  end

  local parsed       = parser_cfg.parse_string(cfg_text)
  local cfg_findings = collectServerCfgFindings(parsed)

  -- Sub-phase 2.3 + 2.3.5: scan other resources, skip Cfx defaults ---------
  -- Wrapped in pcall so a native-call surprise cannot prevent the servercfg
  -- report from being printed.
  local mf_findings, scanned, with_manifest, skipped = {}, 0, 0, 0
  local ok, ret_findings, s, w, sk = pcall(collectFxManifestFindings)
  if ok then
    mf_findings, scanned, with_manifest, skipped = ret_findings, s, w, sk
  else
    say(PREFIX .. 'WARNING: fxmanifest scan crashed: ' .. tostring(ret_findings))
  end

  -- Merge servercfg + fxmanifest findings into a single sorted report.
  local findings = {}
  for _, f in ipairs(cfg_findings) do table.insert(findings, f) end
  for _, f in ipairs(mf_findings)  do table.insert(findings, f) end

  local summary = reporter.summarize(findings)
  local block   = reporter.format_console(summary)

  say(string.format('%spreflight on %s -- %d bytes parsed',
    PREFIX, cfg_path_used, parsed.bytes))
  say(string.format(
    '%sscanned %d resources, %d with manifest (%d Cfx defaults skipped)',
    PREFIX, scanned, with_manifest, skipped))
  sayBlock(block)

  -- Sub-phase 2.4: persist this run --------------------------------------
  flushReport(summary)
end

-- ---------------------------------------------------------------------------
-- Boot trigger: run preflight automatically the first time fxpreflight
-- itself starts. After that, the operator can rerun on demand via the
-- 'fxpreflight' console command without having to restart the resource.
-- ---------------------------------------------------------------------------
AddEventHandler('onResourceStart', function(name)
  if name ~= RESOURCE then return end
  runPreflight()
end)

-- ---------------------------------------------------------------------------
-- Sub-phase 2.5: 'fxpreflight' console command
-- The third argument 'true' marks the command as restricted (admin-only).
-- That means it can be invoked from the server console or from a player
-- with the 'command.fxpreflight' ACE, but a regular player cannot trigger
-- it through chat. For v0.1 we only care about the console use case --
-- typing 'fxpreflight' in the FXServer console reruns the pipeline,
-- regenerates the .md/.log files, and is meaningfully faster than
-- 'restart fxpreflight' because it avoids tearing down and rebuilding
-- the resource's script environment.
-- ---------------------------------------------------------------------------
RegisterCommand('fxpreflight', function(_source, _args, _raw)
  runPreflight()
end, true)
