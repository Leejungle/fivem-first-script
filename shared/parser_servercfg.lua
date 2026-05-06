-- shared/parser_servercfg.lua
-- Parses a FiveM server.cfg text into a structured table of lines and directives.
-- API: parse_string(text) -> result, nil
--      parse_file(path)   -> result, nil  |  nil, error_string
-- No FXServer dependencies; runs under a plain Lua 5.4 interpreter.

local M = {}

-- Strip surrounding double-quotes from a string, if present.
local function strip_quotes(s)
  if #s >= 2 and s:sub(1, 1) == '"' and s:sub(-1) == '"' then
    return s:sub(2, -2)
  end
  return s
end

-- Convar-setting prefixes recognised by FXServer's cfg parser. When a line
-- begins with one of these and is followed by an inner convar name, we want
-- the directive to be indexed under the inner name (e.g. steam_webApiKey),
-- not under the prefix word, so rules can find it without having to know
-- which form the user wrote. The original prefix is preserved on the entry
-- as set_kind for rules that legitimately care (e.g. detecting that a
-- replicated convar was correctly written with `setr`).
local SET_PREFIXES = { set = true, setr = true, sets = true }

-- Build the result table from raw text.
local function parse_text(text)
  local result = {
    raw        = text,
    bytes      = #text,
    lines      = {},
    directives = {},
  }

  -- Normalise: ensure text ends with exactly one newline so the gmatch loop
  -- produces one entry per line without an extra trailing blank.
  local source = text
  if source:sub(-1) ~= "\n" then
    source = source .. "\n"
  end

  local n = 0
  for raw_line in source:gmatch("([^\n]*)\n") do
    n = n + 1
    local trimmed = raw_line:match("^%s*(.-)%s*$")
    local entry = { n = n, raw = raw_line }

    if trimmed == "" then
      entry.kind    = "blank"
      entry.key     = nil
      entry.value   = nil
      entry.comment = nil

    elseif trimmed:sub(1, 1) == "#" then
      entry.kind    = "comment"
      entry.key     = nil
      entry.value   = nil
      entry.comment = trimmed

    else
      -- First whitespace-separated token is the directive key; the rest is the value.
      local key, rest = trimmed:match("^(%S+)%s*(.*)")
      rest = rest or ""

      -- BUG-001 unwrap: if the line is `set/setr/sets <inner_key> <value>` and
      -- there IS an inner key, promote the inner key to be the directive key
      -- and remember the original prefix in set_kind. Lines like a bare `set`
      -- with nothing after it fall through unchanged so we never silently drop
      -- a malformed line.
      local set_kind = nil
      if SET_PREFIXES[key] and rest ~= "" then
        local inner_key, inner_rest = rest:match("^(%S+)%s*(.*)")
        if inner_key and inner_key ~= "" then
          set_kind = key
          key      = inner_key
          rest     = inner_rest or ""
        end
      end

      local value = strip_quotes(rest)

      entry.kind     = "directive"
      entry.key      = key
      entry.value    = value
      entry.set_kind = set_kind
      entry.comment  = nil

      if not result.directives[key] then
        result.directives[key] = {}
      end
      table.insert(result.directives[key],
        { value = value, line = n, set_kind = set_kind })
    end

    table.insert(result.lines, entry)
  end

  return result
end

-- Parse a server.cfg supplied as a string. Never returns an error.
function M.parse_string(text)
  return parse_text(text), nil
end

-- Parse a server.cfg file at the given path.
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
