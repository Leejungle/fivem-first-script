-- tests/test_rules_critical_cfg.lua
-- Tests for R001, R002, and R003 evaluators against cfg fixtures.
-- Run via: lua tests/run.lua (from the workspace root)

local t      = require('tests.run')
local parser = require('shared.parser_servercfg')
local rules  = require('shared.rules')

local FIXTURES = 'fixtures/server-cfg/'

-- Locate a rule descriptor by ID.
local function find_rule(id)
  for _, rule in ipairs(rules.list) do
    if rule.id == id then return rule end
  end
  error("Rule " .. id .. " not found in rules.list", 2)
end

local r001 = find_rule("R001")
local r002 = find_rule("R002")
local r003 = find_rule("R003")

-- ---------------------------------------------------------------------------
-- R001 — endpoint directives
-- ---------------------------------------------------------------------------
t.describe("rules.R001 (endpoint directives)", function()

  t.it("returns nil on good-minimal.cfg (both endpoints present)", function()
    local parsed  = parser.parse_file(FIXTURES .. 'good-minimal.cfg')
    local finding = r001.evaluate(parsed)
    t.assert_nil(finding, "R001 should not fire on a fully valid cfg")
  end)

  t.it("returns nil on good-full.cfg", function()
    local parsed  = parser.parse_file(FIXTURES .. 'good-full.cfg')
    local finding = r001.evaluate(parsed)
    t.assert_nil(finding, "R001 should not fire on good-full.cfg")
  end)

  t.it("returns a CRITICAL finding on bad-missing-endpoint.cfg", function()
    local parsed  = parser.parse_file(FIXTURES .. 'bad-missing-endpoint.cfg')
    local finding = r001.evaluate(parsed)
    t.assert_true(finding ~= nil, "R001 should fire when both endpoint lines are absent")
    t.assert_eq(finding.rule_id,  "R001",     "rule_id")
    t.assert_eq(finding.severity, "CRITICAL", "severity")
  end)

  t.it("finding message mentions the missing directive name", function()
    local parsed  = parser.parse_file(FIXTURES .. 'bad-missing-endpoint.cfg')
    local finding = r001.evaluate(parsed)
    t.assert_true(finding.message:find("endpoint_add") ~= nil,
      "message should name the missing directive(s)")
  end)

  t.it("returns nil on a synthetic cfg with both endpoints present", function()
    local text = table.concat({
      'endpoint_add_tcp "0.0.0.0:30120"',
      'endpoint_add_udp "0.0.0.0:30120"',
      'sv_licenseKey "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"',
      '',
    }, "\n")
    local parsed  = parser.parse_string(text)
    local finding = r001.evaluate(parsed)
    t.assert_nil(finding, "R001 should not fire when both endpoints are present")
  end)

  t.it("fires when only endpoint_add_tcp is missing", function()
    local text = table.concat({
      'endpoint_add_udp "0.0.0.0:30120"',
      'sv_licenseKey "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"',
      '',
    }, "\n")
    local parsed  = parser.parse_string(text)
    local finding = r001.evaluate(parsed)
    t.assert_true(finding ~= nil, "R001 should fire when tcp is absent")
    t.assert_true(finding.message:find("endpoint_add_tcp") ~= nil,
      "message should cite endpoint_add_tcp")
  end)

end)

-- ---------------------------------------------------------------------------
-- R002 — sv_licenseKey format
-- ---------------------------------------------------------------------------
t.describe("rules.R002 (license key format)", function()

  t.it("returns nil on good-minimal.cfg (placeholder key passes length + charset)", function()
    local parsed  = parser.parse_file(FIXTURES .. 'good-minimal.cfg')
    local finding = r002.evaluate(parsed)
    t.assert_nil(finding, "R002 should not fire on the valid placeholder key")
  end)

  t.it("returns nil on good-full.cfg", function()
    local parsed  = parser.parse_file(FIXTURES .. 'good-full.cfg')
    local finding = r002.evaluate(parsed)
    t.assert_nil(finding, "R002 should not fire on good-full.cfg")
  end)

  t.it("returns a CRITICAL finding on bad-license-key.cfg ('INVALID' is too short)", function()
    local parsed  = parser.parse_file(FIXTURES .. 'bad-license-key.cfg')
    local finding = r002.evaluate(parsed)
    t.assert_true(finding ~= nil, "R002 should fire on 'INVALID' (7 chars < 32)")
    t.assert_eq(finding.rule_id,  "R002",     "rule_id")
    t.assert_eq(finding.severity, "CRITICAL", "severity")
  end)

  t.it("fires when sv_licenseKey is absent entirely", function()
    local parsed  = parser.parse_string("sv_hostname \"test\"\n")
    local finding = r002.evaluate(parsed)
    t.assert_true(finding ~= nil, "R002 should fire when key is missing")
    t.assert_true(finding.message:find("missing") ~= nil,
      "message should say 'missing'")
  end)

  t.it("fires when key value contains a disallowed character", function()
    -- 32+ chars but contains a space
    local text    = 'sv_licenseKey "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA!"\n'
    local parsed  = parser.parse_string(text)
    local finding = r002.evaluate(parsed)
    t.assert_true(finding ~= nil, "R002 should fire on disallowed character")
  end)

end)

-- ---------------------------------------------------------------------------
-- R003 — cfg file byte size
-- ---------------------------------------------------------------------------
t.describe("rules.R003 (cfg byte size)", function()

  t.it("returns nil on good-minimal.cfg (well above 200 bytes)", function()
    local parsed  = parser.parse_file(FIXTURES .. 'good-minimal.cfg')
    local finding = r003.evaluate(parsed)
    t.assert_nil(finding, "R003 should not fire on a normal cfg file")
  end)

  t.it("returns nil on good-full.cfg", function()
    local parsed  = parser.parse_file(FIXTURES .. 'good-full.cfg')
    local finding = r003.evaluate(parsed)
    t.assert_nil(finding, "R003 should not fire on good-full.cfg")
  end)

  t.it("returns a CRITICAL finding on a synthetic tiny input (< 200 bytes)", function()
    local parsed  = parser.parse_string("# tiny\n")
    local finding = r003.evaluate(parsed)
    t.assert_true(finding ~= nil, "R003 should fire on a 7-byte input")
    t.assert_eq(finding.rule_id,  "R003",     "rule_id")
    t.assert_eq(finding.severity, "CRITICAL", "severity")
  end)

  t.it("finding message includes the actual byte count", function()
    local text    = "# tiny\n"
    local parsed  = parser.parse_string(text)
    local finding = r003.evaluate(parsed)
    t.assert_true(finding.message:find(tostring(#text)) ~= nil,
      "message should contain the byte count")
  end)

  t.it("boundary: exactly 199 bytes fires, exactly 200 bytes does not", function()
    local small = string.rep("x", 199)
    local ok    = string.rep("x", 200)
    local f_small = r003.evaluate(parser.parse_string(small))
    local f_ok    = r003.evaluate(parser.parse_string(ok))
    t.assert_true(f_small ~= nil, "199 bytes should fire R003")
    t.assert_nil(f_ok,            "200 bytes should not fire R003")
  end)

end)
