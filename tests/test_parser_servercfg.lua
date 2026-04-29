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
