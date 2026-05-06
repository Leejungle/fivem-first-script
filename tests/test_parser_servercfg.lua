-- tests/test_parser_servercfg.lua
-- Unit tests for shared/parser_servercfg.lua against the four cfg fixtures.
-- Run via: lua tests/run.lua (from the workspace root)

local t      = require('tests.run')
local parser = require('shared.parser_servercfg')

local FIXTURES = 'fixtures/server-cfg/'

-- ---------------------------------------------------------------------------
-- Basic file loading
-- ---------------------------------------------------------------------------
t.describe("parser_servercfg.parse_file — basic loading", function()

  t.it("returns a result table for good-minimal.cfg", function()
    local result, err = parser.parse_file(FIXTURES .. 'good-minimal.cfg')
    t.assert_true(result ~= nil, "result should not be nil")
    t.assert_nil(err, "err should be nil on success")
  end)

  t.it("bytes > 0 for good-minimal.cfg", function()
    local result = parser.parse_file(FIXTURES .. 'good-minimal.cfg')
    t.assert_true(result.bytes > 0, "bytes should be positive")
  end)

  t.it("returns nil + error string for a non-existent path", function()
    local result, err = parser.parse_file(FIXTURES .. 'does-not-exist.cfg')
    t.assert_nil(result, "result should be nil when file is missing")
    t.assert_true(err ~= nil, "err should be a non-nil string")
  end)

end)

-- ---------------------------------------------------------------------------
-- Directives — good-minimal.cfg
-- ---------------------------------------------------------------------------
t.describe("parser_servercfg — directives (good-minimal.cfg)", function()

  local result = parser.parse_file(FIXTURES .. 'good-minimal.cfg')

  t.it("endpoint_add_tcp has exactly 1 entry", function()
    local entries = result.directives.endpoint_add_tcp
    t.assert_true(entries ~= nil, "endpoint_add_tcp should be present")
    t.assert_eq(#entries, 1, "endpoint_add_tcp entry count")
  end)

  t.it("endpoint_add_udp has exactly 1 entry", function()
    local entries = result.directives.endpoint_add_udp
    t.assert_true(entries ~= nil, "endpoint_add_udp should be present")
    t.assert_eq(#entries, 1, "endpoint_add_udp entry count")
  end)

  t.it("sv_licenseKey value has surrounding quotes stripped", function()
    local entries = result.directives.sv_licenseKey
    t.assert_true(entries ~= nil, "sv_licenseKey should be present")
    local val = entries[1].value
    t.assert_true(val:sub(1, 1) ~= '"', "value should not start with a double-quote")
    t.assert_true(#val > 0, "value should be non-empty after quote stripping")
  end)

  t.it("ensure has 3 entries in order: mapmanager, chat, spawnmanager", function()
    local entries = result.directives.ensure
    t.assert_true(entries ~= nil, "ensure directives should be present")
    t.assert_eq(#entries, 3, "ensure entry count")
    t.assert_eq(entries[1].value, "mapmanager",   "first ensure value")
    t.assert_eq(entries[2].value, "chat",          "second ensure value")
    t.assert_eq(entries[3].value, "spawnmanager",  "third ensure value")
  end)

  t.it("endpoint_add_tcp value has quotes stripped (0.0.0.0:30120)", function()
    local val = result.directives.endpoint_add_tcp[1].value
    t.assert_eq(val, "0.0.0.0:30120", "endpoint_add_tcp stripped value")
  end)

end)

-- ---------------------------------------------------------------------------
-- Line classification — good-minimal.cfg
-- ---------------------------------------------------------------------------
t.describe("parser_servercfg — line kinds (good-minimal.cfg)", function()

  local result = parser.parse_file(FIXTURES .. 'good-minimal.cfg')

  t.it("at least one line is classified as 'comment'", function()
    local found = false
    for _, line in ipairs(result.lines) do
      if line.kind == "comment" then found = true; break end
    end
    t.assert_true(found, "expected at least one comment line")
  end)

  t.it("at least one line is classified as 'blank'", function()
    local found = false
    for _, line in ipairs(result.lines) do
      if line.kind == "blank" then found = true; break end
    end
    t.assert_true(found, "expected at least one blank line")
  end)

  t.it("directive lines have kind = 'directive'", function()
    local found = false
    for _, line in ipairs(result.lines) do
      if line.kind == "directive" then found = true; break end
    end
    t.assert_true(found, "expected at least one directive line")
  end)

end)

-- ---------------------------------------------------------------------------
-- bad-missing-endpoint.cfg — both endpoint lines are commented out
-- ---------------------------------------------------------------------------
t.describe("parser_servercfg — bad-missing-endpoint.cfg", function()

  local result = parser.parse_file(FIXTURES .. 'bad-missing-endpoint.cfg')

  t.it("endpoint_add_tcp is absent from directives", function()
    t.assert_nil(result.directives.endpoint_add_tcp,
      "endpoint_add_tcp should not appear (lines are commented out)")
  end)

  t.it("endpoint_add_udp is absent from directives", function()
    t.assert_nil(result.directives.endpoint_add_udp,
      "endpoint_add_udp should not appear (lines are commented out)")
  end)

  t.it("ensure directives are still parsed correctly", function()
    local entries = result.directives.ensure
    t.assert_true(entries ~= nil, "ensure should still be present")
    t.assert_eq(#entries, 3, "ensure entry count in bad-missing-endpoint.cfg")
  end)

end)

-- ---------------------------------------------------------------------------
-- good-full.cfg — spot-check ACE and multiple ensures
-- ---------------------------------------------------------------------------
t.describe("parser_servercfg — good-full.cfg", function()

  local result = parser.parse_file(FIXTURES .. 'good-full.cfg')

  t.it("returns a result with bytes > 0", function()
    t.assert_true(result ~= nil, "result should not be nil")
    t.assert_true(result.bytes > 0, "bytes should be positive")
  end)

  t.it("add_ace directives are present", function()
    t.assert_true(result.directives.add_ace ~= nil,
      "add_ace should be present in good-full.cfg")
  end)

  t.it("add_principal directives are present", function()
    t.assert_true(result.directives.add_principal ~= nil,
      "add_principal should be present in good-full.cfg")
  end)

end)

-- ---------------------------------------------------------------------------
-- parse_string — inline input tests
-- ---------------------------------------------------------------------------
t.describe("parser_servercfg.parse_string — inline inputs", function()

  t.it("empty string produces zero directive entries", function()
    local result = parser.parse_string("")
    t.assert_eq(next(result.directives), nil, "directives should be empty")
  end)

  t.it("single comment line is classified correctly", function()
    local result = parser.parse_string("# hello world\n")
    t.assert_eq(#result.lines, 1, "should have exactly one line")
    t.assert_eq(result.lines[1].kind, "comment", "line kind")
  end)

  t.it("unquoted value is stored as-is", function()
    local result = parser.parse_string("ensure mapmanager\n")
    local entries = result.directives.ensure
    t.assert_true(entries ~= nil, "ensure should be present")
    t.assert_eq(entries[1].value, "mapmanager", "unquoted value")
  end)

  t.it("bytes field equals the byte length of the input string", function()
    local text   = "# tiny\n"
    local result = parser.parse_string(text)
    t.assert_eq(result.bytes, #text, "bytes should equal string length")
  end)

end)

-- ---------------------------------------------------------------------------
-- BUG-001: set / setr / sets directive unwrapping
-- `set steam_webApiKey ""` must produce directives.steam_webApiKey, NOT
-- directives.set with the inner key folded into the value. Each unwrapped
-- entry carries a set_kind metadata field ("set" | "setr" | "sets") so future
-- rules can distinguish replicated/server-only convars from regular ones.
-- Direct-form directives (no set/setr/sets prefix) keep set_kind = nil.
-- ---------------------------------------------------------------------------
t.describe("parser_servercfg — set/setr/sets unwrapping (BUG-001)", function()

  t.it("set <convar> <value>: unwraps to directives.<convar>", function()
    local result = parser.parse_string('set steam_webApiKey "abc"\n')
    t.assert_true(result.directives.steam_webApiKey ~= nil,
      "directives.steam_webApiKey must exist after unwrap")
    t.assert_eq(result.directives.steam_webApiKey[1].value, "abc",
      "value must be the unwrapped (quote-stripped) inner value")
    t.assert_eq(result.directives.steam_webApiKey[1].set_kind, "set",
      "set_kind metadata must be 'set'")
  end)

  t.it("set <convar> '': unwraps to empty value (R007 trigger case)", function()
    local result = parser.parse_string('set steam_webApiKey ""\n')
    t.assert_true(result.directives.steam_webApiKey ~= nil,
      "directives.steam_webApiKey must exist even when the value is empty")
    t.assert_eq(result.directives.steam_webApiKey[1].value, "",
      "empty quoted value must unwrap to empty string")
  end)

  t.it("setr <convar> <value>: unwraps and tags set_kind='setr'", function()
    local result = parser.parse_string('setr something_replicated 1\n')
    t.assert_true(result.directives.something_replicated ~= nil,
      "directives.something_replicated must exist after setr unwrap")
    t.assert_eq(result.directives.something_replicated[1].value, "1",
      "setr value must be the second token, not the convar name")
    t.assert_eq(result.directives.something_replicated[1].set_kind, "setr",
      "set_kind must be 'setr'")
  end)

  t.it("sets <convar> <value>: unwraps and tags set_kind='sets'", function()
    local result = parser.parse_string('sets sv_projectName "My Server"\n')
    t.assert_true(result.directives.sv_projectName ~= nil,
      "directives.sv_projectName must exist after sets unwrap")
    t.assert_eq(result.directives.sv_projectName[1].value, "My Server",
      "sets value must be the unquoted inner value")
    t.assert_eq(result.directives.sv_projectName[1].set_kind, "sets",
      "set_kind must be 'sets'")
  end)

  t.it("does NOT create directives.set / .setr / .sets after unwrap", function()
    local result = parser.parse_string('set a 1\nsetr b 2\nsets c 3\n')
    t.assert_nil(result.directives.set,
      "directives.set must be absent (consumed by unwrap)")
    t.assert_nil(result.directives.setr,
      "directives.setr must be absent (consumed by unwrap)")
    t.assert_nil(result.directives.sets,
      "directives.sets must be absent (consumed by unwrap)")
    t.assert_true(result.directives.a ~= nil, "directives.a must exist")
    t.assert_true(result.directives.b ~= nil, "directives.b must exist")
    t.assert_true(result.directives.c ~= nil, "directives.c must exist")
  end)

  t.it("direct form (no set prefix) still works and set_kind is nil", function()
    local result = parser.parse_string('steam_webApiKey "abc"\n')
    t.assert_true(result.directives.steam_webApiKey ~= nil,
      "directives.steam_webApiKey must exist for direct form")
    t.assert_eq(result.directives.steam_webApiKey[1].value, "abc",
      "direct-form value must still be unquoted")
    t.assert_nil(result.directives.steam_webApiKey[1].set_kind,
      "set_kind must be nil for direct form")
  end)

  t.it("lone 'set' with no value falls back to directives.set", function()
    -- Edge case: the line is just `set` with nothing after it. The unwrap
    -- helper has no inner token to promote, so we must NOT silently drop
    -- the line; keep it under directives.set as a last-resort fallback so
    -- a future rule could flag it as malformed.
    local result = parser.parse_string('set\n')
    t.assert_true(result.directives.set ~= nil,
      "lone 'set' must still appear in directives.set as fallback")
  end)

end)
