-- tests/test_rules_critical_fxmanifest.lua
-- Tests for the R008 evaluator against fxmanifest fixtures and synthetic inputs.
-- Run via: lua tests/run.lua (from the workspace root)

local t      = require('tests.run')
local parser = require('shared.parser_fxmanifest')
local rules  = require('shared.rules')

local FIXTURES = 'fixtures/fxmanifest/'

-- Locate a rule descriptor by ID.
local function find_rule(id)
  for _, rule in ipairs(rules.list) do
    if rule.id == id then return rule end
  end
  error("Rule " .. id .. " not found in rules.list", 2)
end

local r008 = find_rule("R008")

-- ---------------------------------------------------------------------------
-- R008 — valid manifest
-- ---------------------------------------------------------------------------
t.describe("rules.R008 (fx_version present — good-cerulean.lua)", function()

  t.it("returns nil when fx_version is set to 'cerulean'", function()
    local parsed  = parser.parse_file(FIXTURES .. 'good-cerulean.lua')
    local finding = r008.evaluate(parsed)
    t.assert_nil(finding, "R008 should not fire when fx_version is valid")
  end)

end)

-- ---------------------------------------------------------------------------
-- R008 — deprecated manifest (no fx_version)
-- ---------------------------------------------------------------------------
t.describe("rules.R008 (deprecated resource — no fx_version)", function()

  t.it("returns a CRITICAL finding for bad-deprecated-resource.lua", function()
    local parsed  = parser.parse_file(FIXTURES .. 'bad-deprecated-resource.lua')
    local finding = r008.evaluate(parsed)
    t.assert_true(finding ~= nil,
      "R008 should fire: legacy file has no fx_version field")
    t.assert_eq(finding.rule_id,  "R008",     "rule_id")
    t.assert_eq(finding.severity, "CRITICAL", "severity")
    t.assert_true(type(finding.file) == "string", "file should be a string")
  end)

end)

-- ---------------------------------------------------------------------------
-- R008 — synthetic inputs via parse_string
-- ---------------------------------------------------------------------------
t.describe("rules.R008 (synthetic inputs)", function()

  t.it("returns nil for 'fx_version cerulean'", function()
    local parsed  = parser.parse_string("fx_version 'cerulean'\n")
    local finding = r008.evaluate(parsed)
    t.assert_nil(finding, "R008 should not fire when fx_version is 'cerulean'")
  end)

  t.it("returns a CRITICAL finding for empty string (no fx_version call)", function()
    local parsed  = parser.parse_string("")
    local finding = r008.evaluate(parsed)
    t.assert_true(finding ~= nil, "R008 should fire on empty manifest")
    t.assert_eq(finding.rule_id,  "R008",     "rule_id")
    t.assert_eq(finding.severity, "CRITICAL", "severity")
  end)

  t.it("returns a CRITICAL finding for fx_version '' (empty string value)", function()
    local parsed  = parser.parse_string("fx_version ''\n")
    local finding = r008.evaluate(parsed)
    t.assert_true(finding ~= nil, "R008 should fire when fx_version is empty string")
    t.assert_eq(finding.rule_id,  "R008",     "rule_id")
    t.assert_eq(finding.severity, "CRITICAL", "severity")
  end)

  t.it("returns a CRITICAL finding when load() fails (parse_error set)", function()
    -- Unterminated string causes load() to fail.
    local parsed  = parser.parse_string("fx_version 'cerulean")
    t.assert_true(parsed.parse_error ~= nil, "precondition: parse_error should be set")
    local finding = r008.evaluate(parsed)
    t.assert_true(finding ~= nil, "R008 should fire when manifest cannot be parsed")
    t.assert_eq(finding.rule_id,  "R008",     "rule_id")
    t.assert_eq(finding.severity, "CRITICAL", "severity")
    t.assert_true(finding.message:find("parse") ~= nil,
      "message should mention the parse failure")
  end)

  t.it("finding.file is always a string", function()
    local parsed  = parser.parse_string("")
    local finding = r008.evaluate(parsed)
    t.assert_true(type(finding.file) == "string", "file field must be a string")
  end)

end)
