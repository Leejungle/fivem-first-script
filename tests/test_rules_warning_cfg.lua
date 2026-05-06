-- tests/test_rules_warning_cfg.lua
-- Tests for R004, R005, and R007 evaluators against cfg fixtures and synthetic inputs.
-- Run via: lua tests/run.lua (from the workspace root)

local t          = require('tests.run')
local parser_cfg = require('shared.parser_servercfg')
local rules      = require('shared.rules')

local FIXTURES = 'fixtures/server-cfg/'

local function find_rule(id)
  for _, rule in ipairs(rules.list) do
    if rule.id == id then return rule end
  end
  error("Rule " .. id .. " not found in rules.list", 2)
end

local r004 = find_rule("R004")
local r005 = find_rule("R005")
local r007 = find_rule("R007")

-- ---------------------------------------------------------------------------
-- R004 — sv_hostname missing or default
-- ---------------------------------------------------------------------------
t.describe("rules.R004 (sv_hostname default or missing)", function()

  t.it("returns nil on good-minimal.cfg ('fxpreflight Test Server' is custom)", function()
    local parsed  = parser_cfg.parse_file(FIXTURES .. 'good-minimal.cfg')
    local finding = r004.evaluate(parsed)
    t.assert_nil(finding, "R004 should not fire on a custom hostname")
  end)

  t.it("returns nil on good-full.cfg ('My Community Server' is custom)", function()
    local parsed  = parser_cfg.parse_file(FIXTURES .. 'good-full.cfg')
    local finding = r004.evaluate(parsed)
    t.assert_nil(finding, "R004 should not fire on good-full.cfg")
  end)

  t.it("fires when sv_hostname directive is absent", function()
    local parsed  = parser_cfg.parse_string("sv_maxclients 32\n")
    local finding = r004.evaluate(parsed)
    t.assert_true(finding ~= nil, "R004 should fire when sv_hostname is missing")
    t.assert_eq(finding.rule_id,  "R004",   "rule_id")
    t.assert_eq(finding.severity, "WARNING","severity")
  end)

  t.it("fires on known default 'FXServer, but unconfigured'", function()
    local parsed  = parser_cfg.parse_string('sv_hostname "FXServer, but unconfigured"\n')
    local finding = r004.evaluate(parsed)
    t.assert_true(finding ~= nil,
      "R004 should fire on the 'FXServer, but unconfigured' default")
    t.assert_eq(finding.severity, "WARNING", "severity")
  end)

  t.it("fires case-insensitively on 'MY NEW FXSERVER'", function()
    local parsed  = parser_cfg.parse_string('sv_hostname "MY NEW FXSERVER"\n')
    local finding = r004.evaluate(parsed)
    t.assert_true(finding ~= nil,
      "R004 should fire on 'MY NEW FXSERVER' (case-insensitive match)")
  end)

  t.it("fires on known default 'Default FXServer'", function()
    local parsed  = parser_cfg.parse_string('sv_hostname "Default FXServer"\n')
    local finding = r004.evaluate(parsed)
    t.assert_true(finding ~= nil, "R004 should fire on 'Default FXServer'")
  end)

  t.it("returns nil on a clearly custom hostname", function()
    local parsed  = parser_cfg.parse_string('sv_hostname "Awesome RP Server #1"\n')
    local finding = r004.evaluate(parsed)
    t.assert_nil(finding, "R004 should not fire on a custom hostname")
  end)

end)

-- ---------------------------------------------------------------------------
-- R005 — sv_maxclients missing or out of range
-- ---------------------------------------------------------------------------
t.describe("rules.R005 (sv_maxclients range)", function()

  t.it("returns nil on good-minimal.cfg (32 clients)", function()
    local parsed  = parser_cfg.parse_file(FIXTURES .. 'good-minimal.cfg')
    local finding = r005.evaluate(parsed)
    t.assert_nil(finding, "R005 should not fire for sv_maxclients 32")
  end)

  t.it("returns nil on good-full.cfg (64 clients)", function()
    local parsed  = parser_cfg.parse_file(FIXTURES .. 'good-full.cfg')
    local finding = r005.evaluate(parsed)
    t.assert_nil(finding, "R005 should not fire for sv_maxclients 64")
  end)

  t.it("fires when sv_maxclients directive is absent", function()
    local parsed  = parser_cfg.parse_string("sv_hostname \"test\"\n")
    local finding = r005.evaluate(parsed)
    t.assert_true(finding ~= nil, "R005 should fire when sv_maxclients is missing")
    t.assert_eq(finding.rule_id,  "R005",   "rule_id")
    t.assert_eq(finding.severity, "WARNING","severity")
  end)

  t.it("fires on sv_maxclients 2049 (exceeds maximum)", function()
    local parsed  = parser_cfg.parse_string("sv_maxclients 2049\n")
    local finding = r005.evaluate(parsed)
    t.assert_true(finding ~= nil, "R005 should fire for 2049")
    t.assert_true(finding.message:find("2049") ~= nil, "message should include the value")
  end)

  t.it("fires on sv_maxclients abc (non-numeric)", function()
    local parsed  = parser_cfg.parse_string("sv_maxclients abc\n")
    local finding = r005.evaluate(parsed)
    t.assert_true(finding ~= nil, "R005 should fire for non-numeric value")
    t.assert_true(finding.message:find("abc") ~= nil, "message should include the value")
  end)

  t.it("fires on sv_maxclients 0 (below minimum)", function()
    local parsed  = parser_cfg.parse_string("sv_maxclients 0\n")
    local finding = r005.evaluate(parsed)
    t.assert_true(finding ~= nil, "R005 should fire for 0")
  end)

  t.it("returns nil on sv_maxclients 2048 (boundary is OK)", function()
    local parsed  = parser_cfg.parse_string("sv_maxclients 2048\n")
    local finding = r005.evaluate(parsed)
    t.assert_nil(finding, "R005 should not fire at exactly 2048")
  end)

  t.it("returns nil on sv_maxclients 1 (minimum is OK)", function()
    local parsed  = parser_cfg.parse_string("sv_maxclients 1\n")
    local finding = r005.evaluate(parsed)
    t.assert_nil(finding, "R005 should not fire at exactly 1")
  end)

end)

-- ---------------------------------------------------------------------------
-- R007 — Steam Web API key placeholder
-- ---------------------------------------------------------------------------
t.describe("rules.R007 (steam_webApiKey placeholder)", function()

  t.it("returns nil on good-minimal.cfg (steam_webApiKey line is commented out)", function()
    local parsed  = parser_cfg.parse_file(FIXTURES .. 'good-minimal.cfg')
    local finding = r007.evaluate(parsed)
    t.assert_nil(finding, "R007 should not fire when directive is absent")
  end)

  t.it("returns nil on good-full.cfg ('PASTE_STEAM_KEY_HERE' is not 'none')", function()
    local parsed  = parser_cfg.parse_file(FIXTURES .. 'good-full.cfg')
    local finding = r007.evaluate(parsed)
    t.assert_nil(finding, "R007 should not fire on a non-placeholder key")
  end)

  t.it("fires on steam_webApiKey \"\" (empty value)", function()
    local parsed  = parser_cfg.parse_string('steam_webApiKey ""\n')
    local finding = r007.evaluate(parsed)
    t.assert_true(finding ~= nil, "R007 should fire on empty steam_webApiKey")
    t.assert_eq(finding.rule_id,  "R007",   "rule_id")
    t.assert_eq(finding.severity, "WARNING","severity")
  end)

  t.it("fires on steam_webApiKey \"none\"", function()
    local parsed  = parser_cfg.parse_string('steam_webApiKey "none"\n')
    local finding = r007.evaluate(parsed)
    t.assert_true(finding ~= nil, "R007 should fire when key is 'none'")
  end)

  t.it("fires case-insensitively on steam_webApiKey \"NONE\"", function()
    local parsed  = parser_cfg.parse_string('steam_webApiKey "NONE"\n')
    local finding = r007.evaluate(parsed)
    t.assert_true(finding ~= nil, "R007 should fire for 'NONE' (case-insensitive)")
  end)

  t.it("returns nil when steam_webApiKey directive is absent entirely", function()
    local parsed  = parser_cfg.parse_string("sv_maxclients 32\n")
    local finding = r007.evaluate(parsed)
    t.assert_nil(finding, "R007 should not fire when directive is missing")
  end)

  t.it("returns nil on a real-looking key value", function()
    local parsed  = parser_cfg.parse_string('steam_webApiKey "ABCDEFGH"\n')
    local finding = r007.evaluate(parsed)
    t.assert_nil(finding, "R007 should not fire on a non-placeholder value")
  end)

  -- BUG-001 regression: real-world cfgs almost always write this convar via
  -- the `set` form (FXServer's default cfg template uses `set steam_webApiKey ""`).
  -- Before the parser fix, R007 would silently miss it because the parser
  -- stored the line under directives.set instead of directives.steam_webApiKey.
  t.it("fires on set steam_webApiKey \"\" (BUG-001 regression)", function()
    local parsed  = parser_cfg.parse_string('set steam_webApiKey ""\n')
    local finding = r007.evaluate(parsed)
    t.assert_true(finding ~= nil,
      "R007 must fire for set-form empty steam_webApiKey")
    t.assert_eq(finding.severity, "WARNING", "severity")
    t.assert_eq(finding.rule_id,  "R007",    "rule_id")
  end)

end)
