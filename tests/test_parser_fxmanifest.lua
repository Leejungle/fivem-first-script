-- tests/test_parser_fxmanifest.lua
-- Unit tests for shared/parser_fxmanifest.lua against the two fxmanifest fixtures.
-- Run via: lua tests/run.lua (from the workspace root)

local t      = require('tests.run')
local parser = require('shared.parser_fxmanifest')

local FIXTURES = 'fixtures/fxmanifest/'

-- ---------------------------------------------------------------------------
-- good-cerulean.lua — valid modern manifest
-- ---------------------------------------------------------------------------
t.describe("parser_fxmanifest — good-cerulean.lua", function()

  local result, err = parser.parse_file(FIXTURES .. 'good-cerulean.lua')

  t.it("returns a non-nil result with no file error", function()
    t.assert_true(result ~= nil, "result should not be nil")
    t.assert_nil(err, "file-open error should be nil")
  end)

  t.it("parse_error is nil (valid Lua)", function()
    t.assert_nil(result.parse_error, "parse_error should be nil for valid Lua")
  end)

  t.it("fields.fx_version == 'cerulean'", function()
    t.assert_eq(result.fields.fx_version, "cerulean", "fx_version")
  end)

  t.it("fields.games is a table with one entry 'gta5'", function()
    local g = result.fields.games
    t.assert_true(type(g) == "table", "games should be a table")
    t.assert_eq(#g, 1, "games table length")
    t.assert_eq(g[1], "gta5", "games[1]")
  end)

  t.it("fields.author is a non-empty string", function()
    t.assert_true(type(result.fields.author) == "string", "author should be a string")
    t.assert_true(#result.fields.author > 0, "author should be non-empty")
  end)

  t.it("fields.description is a non-empty string", function()
    t.assert_true(type(result.fields.description) == "string",
      "description should be a string")
    t.assert_true(#result.fields.description > 0, "description should be non-empty")
  end)

  t.it("fields.version is a non-empty string", function()
    t.assert_true(type(result.fields.version) == "string", "version should be a string")
    t.assert_true(#result.fields.version > 0, "version should be non-empty")
  end)

  t.it("fields.client_scripts is a table with at least one entry", function()
    local cs = result.fields.client_scripts
    t.assert_true(type(cs) == "table", "client_scripts should be a table")
    t.assert_true(#cs >= 1, "client_scripts should have at least one entry")
  end)

  t.it("fields.server_scripts is a table with at least one entry", function()
    local ss = result.fields.server_scripts
    t.assert_true(type(ss) == "table", "server_scripts should be a table")
    t.assert_true(#ss >= 1, "server_scripts should have at least one entry")
  end)

  t.it("fields.lua54 == 'yes'", function()
    t.assert_eq(result.fields.lua54, "yes", "lua54")
  end)

  t.it("is_deprecated_resource == false", function()
    t.assert_eq(result.is_deprecated_resource, false,
      "good-cerulean.lua should not be flagged as deprecated")
  end)

  t.it("raw_calls is a non-empty ordered list", function()
    t.assert_true(type(result.raw_calls) == "table", "raw_calls should be a table")
    t.assert_true(#result.raw_calls > 0, "raw_calls should have entries")
  end)

  t.it("bytes > 0", function()
    t.assert_true(result.bytes > 0, "bytes should be positive")
  end)

end)

-- ---------------------------------------------------------------------------
-- bad-deprecated-resource.lua — legacy __resource.lua style
-- ---------------------------------------------------------------------------
t.describe("parser_fxmanifest — bad-deprecated-resource.lua", function()

  local result = parser.parse_file(FIXTURES .. 'bad-deprecated-resource.lua')

  t.it("parse_error is nil (file is syntactically valid Lua)", function()
    t.assert_nil(result.parse_error,
      "the deprecated file is still valid Lua; parse_error should be nil")
  end)

  t.it("fields.resource_manifest_version is a non-empty string", function()
    local rmv = result.fields.resource_manifest_version
    t.assert_true(type(rmv) == "string", "resource_manifest_version should be a string")
    t.assert_true(#rmv > 0, "resource_manifest_version should be non-empty")
  end)

  t.it("is_deprecated_resource == true", function()
    t.assert_eq(result.is_deprecated_resource, true,
      "resource_manifest_version present → is_deprecated_resource must be true")
  end)

  t.it("fields.fx_version is nil (not set in legacy file)", function()
    t.assert_nil(result.fields.fx_version,
      "legacy file has no fx_version; fields.fx_version should be nil")
  end)

end)

-- ---------------------------------------------------------------------------
-- parse_string — inline inputs
-- ---------------------------------------------------------------------------
t.describe("parser_fxmanifest.parse_string — inline inputs", function()

  t.it("empty string: parse_error is nil and fields is empty", function()
    local result = parser.parse_string("")
    t.assert_nil(result.parse_error, "empty input should not produce a parse error")
    t.assert_eq(next(result.fields), nil, "fields should be empty for empty input")
    t.assert_eq(#result.raw_calls, 0, "raw_calls should be empty for empty input")
  end)

  t.it("malformed Lua (unterminated string) sets parse_error", function()
    -- "fx_version 'cerulean" has an unterminated string literal
    local result = parser.parse_string("fx_version 'cerulean")
    t.assert_true(result.parse_error ~= nil,
      "unterminated string should produce a parse_error")
    t.assert_eq(next(result.fields), nil,
      "fields should be empty when load() fails")
    t.assert_eq(#result.raw_calls, 0,
      "raw_calls should be empty when load() fails")
  end)

  t.it("valid single-directive input records the field", function()
    local result = parser.parse_string("fx_version 'cerulean'\n")
    t.assert_nil(result.parse_error, "single valid directive should not error")
    t.assert_eq(result.fields.fx_version, "cerulean", "fx_version field")
  end)

  t.it("bytes equals the byte length of the input string", function()
    local text   = "fx_version 'cerulean'\n"
    local result = parser.parse_string(text)
    t.assert_eq(result.bytes, #text, "bytes field")
  end)

  t.it("chained-call style records the directive without error", function()
    -- e.g. games { 'gta5' } — games is called with a table argument
    local result = parser.parse_string("games { 'gta5' }\n")
    t.assert_nil(result.parse_error, "table-argument call should not error")
    local g = result.fields.games
    t.assert_true(type(g) == "table", "games should be a table")
    t.assert_eq(g[1], "gta5", "games[1]")
  end)

end)

-- ---------------------------------------------------------------------------
-- parse_file error handling
-- ---------------------------------------------------------------------------
t.describe("parser_fxmanifest.parse_file — error handling", function()

  t.it("returns (nil, error_string) for a non-existent path", function()
    local result, err = parser.parse_file(FIXTURES .. 'does-not-exist.lua')
    t.assert_nil(result, "result should be nil for missing file")
    t.assert_true(err ~= nil, "err should be a non-nil string")
  end)

end)
