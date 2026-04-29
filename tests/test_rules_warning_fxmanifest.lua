-- tests/test_rules_warning_fxmanifest.lua
-- Tests for R009, R011, and R013 evaluators against fxmanifest fixtures and
-- synthetic inputs. Run via: lua tests/run.lua (from the workspace root)

local t              = require('tests.run')
local parser_manifest = require('shared.parser_fxmanifest')
local rules          = require('shared.rules')

local FIXTURES = 'fixtures/fxmanifest/'

local function find_rule(id)
  for _, rule in ipairs(rules.list) do
    if rule.id == id then return rule end
  end
  error("Rule " .. id .. " not found in rules.list", 2)
end

local r009 = find_rule("R009")
local r011 = find_rule("R011")
local r013 = find_rule("R013")

-- ---------------------------------------------------------------------------
-- R009 — fx_version older than 'cerulean'
-- ---------------------------------------------------------------------------
t.describe("rules.R009 (fx_version older than cerulean)", function()

  t.it("returns nil on good-cerulean.lua ('cerulean' is current)", function()
    local parsed  = parser_manifest.parse_file(FIXTURES .. 'good-cerulean.lua')
    local finding = r009.evaluate(parsed)
    t.assert_nil(finding, "R009 should not fire for 'cerulean'")
  end)

  t.it("returns nil on bad-deprecated-resource.lua (no fx_version → R008 handles it)", function()
    local parsed  = parser_manifest.parse_file(FIXTURES .. 'bad-deprecated-resource.lua')
    local finding = r009.evaluate(parsed)
    t.assert_nil(finding, "R009 should return nil when fx_version is absent")
  end)

  t.it("fires WARNING on synthetic fx_version 'adamant'", function()
    local parsed  = parser_manifest.parse_string("fx_version 'adamant'\n")
    local finding = r009.evaluate(parsed)
    t.assert_true(finding ~= nil, "R009 should fire for 'adamant'")
    t.assert_eq(finding.rule_id,  "R009",   "rule_id")
    t.assert_eq(finding.severity, "WARNING","severity")
    t.assert_true(finding.message:find("adamant") ~= nil,
      "message should include the old version value")
  end)

  t.it("fires WARNING on synthetic fx_version 'bodacious'", function()
    local parsed  = parser_manifest.parse_string("fx_version 'bodacious'\n")
    local finding = r009.evaluate(parsed)
    t.assert_true(finding ~= nil, "R009 should fire for 'bodacious'")
    t.assert_eq(finding.severity, "WARNING","severity")
  end)

  t.it("returns nil on synthetic fx_version 'cerulean'", function()
    local parsed  = parser_manifest.parse_string("fx_version 'cerulean'\n")
    local finding = r009.evaluate(parsed)
    t.assert_nil(finding, "R009 should not fire for 'cerulean'")
  end)

  t.it("returns nil on an unknown fx_version value (not in the older list)", function()
    local parsed  = parser_manifest.parse_string("fx_version 'unknown'\n")
    local finding = r009.evaluate(parsed)
    t.assert_nil(finding, "R009 should not fire for an unrecognised version")
  end)

end)

-- ---------------------------------------------------------------------------
-- R011 — games table missing or empty
-- ---------------------------------------------------------------------------
t.describe("rules.R011 (games table missing or empty)", function()

  t.it("returns nil on good-cerulean.lua (games { 'gta5' } is present)", function()
    local parsed  = parser_manifest.parse_file(FIXTURES .. 'good-cerulean.lua')
    local finding = r011.evaluate(parsed)
    t.assert_nil(finding, "R011 should not fire when games is populated")
  end)

  t.it("fires WARNING on bad-deprecated-resource.lua (no games declaration)", function()
    local parsed  = parser_manifest.parse_file(FIXTURES .. 'bad-deprecated-resource.lua')
    local finding = r011.evaluate(parsed)
    t.assert_true(finding ~= nil,
      "R011 should fire when games is missing entirely")
    t.assert_eq(finding.rule_id,  "R011",   "rule_id")
    t.assert_eq(finding.severity, "WARNING","severity")
  end)

  t.it("fires WARNING on a synthetic manifest with no games entry", function()
    local parsed  = parser_manifest.parse_string("fx_version 'cerulean'\n")
    local finding = r011.evaluate(parsed)
    t.assert_true(finding ~= nil, "R011 should fire when games is absent")
  end)

  t.it("returns nil on a synthetic manifest with games { 'gta5' }", function()
    local parsed  = parser_manifest.parse_string("games { 'gta5' }\n")
    local finding = r011.evaluate(parsed)
    t.assert_nil(finding, "R011 should not fire when games has at least one entry")
  end)

  t.it("fires WARNING on a synthetic manifest with games {} (empty table)", function()
    local parsed  = parser_manifest.parse_string("games {}\n")
    local finding = r011.evaluate(parsed)
    t.assert_true(finding ~= nil, "R011 should fire for an empty games table")
    t.assert_eq(finding.severity, "WARNING","severity")
  end)

end)

-- ---------------------------------------------------------------------------
-- R013 — Lua 5.3 deprecation marker (lua54 'no')
-- ---------------------------------------------------------------------------
t.describe("rules.R013 (Lua 5.3 deprecation marker)", function()

  t.it("returns nil on good-cerulean.lua (lua54 'yes')", function()
    local parsed  = parser_manifest.parse_file(FIXTURES .. 'good-cerulean.lua')
    local finding = r013.evaluate(parsed)
    t.assert_nil(finding, "R013 should not fire when lua54 is 'yes'")
  end)

  t.it("returns nil on bad-deprecated-resource.lua (no lua54 declaration)", function()
    local parsed  = parser_manifest.parse_file(FIXTURES .. 'bad-deprecated-resource.lua')
    local finding = r013.evaluate(parsed)
    t.assert_nil(finding, "R013 should not fire when lua54 is absent")
  end)

  t.it("fires INFO on synthetic manifest with lua54 'no'", function()
    local parsed  = parser_manifest.parse_string("lua54 'no'\n")
    local finding = r013.evaluate(parsed)
    t.assert_true(finding ~= nil, "R013 should fire when lua54 is 'no'")
    t.assert_eq(finding.rule_id,  "R013", "rule_id")
    t.assert_eq(finding.severity, "INFO", "severity")
  end)

  t.it("fires case-insensitively on lua54 'NO'", function()
    local parsed  = parser_manifest.parse_string("lua54 'NO'\n")
    local finding = r013.evaluate(parsed)
    t.assert_true(finding ~= nil, "R013 should fire for 'NO' (case-insensitive)")
    t.assert_eq(finding.severity, "INFO", "severity")
  end)

  t.it("returns nil on synthetic manifest with lua54 'yes'", function()
    local parsed  = parser_manifest.parse_string("lua54 'yes'\n")
    local finding = r013.evaluate(parsed)
    t.assert_nil(finding, "R013 should not fire when lua54 is 'yes'")
  end)

  t.it("returns nil when lua54 is not declared at all", function()
    local parsed  = parser_manifest.parse_string("fx_version 'cerulean'\n")
    local finding = r013.evaluate(parsed)
    t.assert_nil(finding, "R013 should not fire when lua54 is absent")
  end)

end)
