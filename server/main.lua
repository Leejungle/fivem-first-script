-- server/main.lua
-- fxpreflight resource entry point -- Sub-phase 2.1 skeleton.
-- Job at this stage: load the 4 shared modules from disk via LoadResourceFile,
-- verify they expose the expected API, and print a one-line success log on
-- onResourceStart. Does NOT read server.cfg, does NOT scan resources/, does
-- NOT write any report. That belongs to Sub-phase 2.2 and beyond.

local RESOURCE = GetCurrentResourceName()
local PREFIX   = '[fxpreflight] '
local VERSION  = '0.1.0'

-- ---------------------------------------------------------------------------
-- loadShared(rel_path) -> table
-- Loads a shared/ Lua module from this resource's folder and returns the table
-- it returned (the "local M = {} ... return M" pattern). Errors loudly so a
-- broken module is impossible to ignore.
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

AddEventHandler('onResourceStart', function(name)
  if name ~= RESOURCE then return end
  print(string.format(
    '%sv%s skeleton OK -- modules loaded: 4, rules registered: %d',
    PREFIX, VERSION, #rules.list))
end)
