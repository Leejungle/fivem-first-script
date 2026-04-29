-- shared/parser_fxmanifest.lua
-- Parses a fxmanifest.lua file by loading it inside a sandboxed Lua environment
-- where every unknown global acts as a recorder function. This exploits the fact
-- that fxmanifest.lua IS valid Lua. No FXServer dependencies.

local M = {}

-- Build a recorder function for a directive name. Returns itself so chained
-- calls (e.g. my_data 'one' { key = val }) do not raise an error.
local function make_recorder(name, raw_calls, fields)
  local rec
  rec = function(...)
    local args = { ... }
    table.insert(raw_calls, { name = name, args = args })
    if #args == 1 then
      fields[name] = args[1]
    elseif #args > 1 then
      fields[name] = args
    end
    return rec
  end
  return rec
end

local function parse_text(text)
  local raw_calls = {}
  local fields    = {}

  -- The sandbox environment: any key access returns a fresh recorder.
  -- The empty table has no metatable-provided standard library, so the loaded
  -- chunk cannot call print, io, os, or any other built-in accidentally.
  local sandbox_mt = {
    __index = function(_, key)
      return make_recorder(key, raw_calls, fields)
    end,
  }
  local sandbox = setmetatable({}, sandbox_mt)

  local chunk, load_err = load(text, "fxmanifest.lua", "t", sandbox)
  if not chunk then
    return {
      raw                   = text,
      bytes                 = #text,
      parse_error           = "load() failed: " .. tostring(load_err),
      fields                = {},
      raw_calls             = {},
      is_deprecated_resource = false,
    }
  end

  local ok, run_err = pcall(chunk)
  return {
    raw                   = text,
    bytes                 = #text,
    parse_error           = (not ok) and tostring(run_err) or nil,
    fields                = fields,
    raw_calls             = raw_calls,
    is_deprecated_resource = fields.resource_manifest_version ~= nil,
  }
end

-- Parse a fxmanifest supplied as a string. Never returns a file-level error.
function M.parse_string(text)
  return parse_text(text), nil
end

-- Parse a fxmanifest file at the given path.
-- Returns (nil, error_string) if the file cannot be opened.
function M.parse_file(path)
  local fh, err = io.open(path, "r")
  if not fh then
    return nil, "could not open file: " .. path
  end
  local text = fh:read("*a")
  fh:close()
  return parse_text(text), nil
end

return M
