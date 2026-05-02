-- tests/test_reporter.lua
-- Tests for shared/reporter.lua: summarize(), format_console(), format_markdown().
-- Run via: lua tests/run.lua (from the workspace root)

local t        = require('tests.run')
local reporter = require('shared.reporter')

-- ---------------------------------------------------------------------------
-- Shared finding fixtures (used across the marquee / multi-severity tests)
-- ---------------------------------------------------------------------------
local F_R001_CRIT = {
  rule_id  = "R001",
  severity = "CRITICAL",
  file     = "server.cfg",
  line     = nil,
  message  = "Missing required network directive(s): endpoint_add_tcp",
}

local F_R008_CRIT = {
  rule_id  = "R008",
  severity = "CRITICAL",
  file     = "fxmanifest.lua",
  line     = nil,
  message  = "fxmanifest.lua is missing a valid fx_version field",
}

local F_R004_WARN = {
  rule_id  = "R004",
  severity = "WARNING",
  file     = "server.cfg",
  line     = 12,
  message  = "sv_hostname is still set to a default value: 'Default FXServer'",
}

local F_R013_INFO = {
  rule_id  = "R013",
  severity = "INFO",
  file     = "fxmanifest.lua",
  line     = nil,
  message  = "fxmanifest.lua sets lua54 'no'; Lua 5.3 was deprecated in June 2025",
}

-- ---------------------------------------------------------------------------
-- Group A: reporter.summarize
-- ---------------------------------------------------------------------------
t.describe("reporter.summarize", function()

  t.it("empty findings input -> total=0, by_severity all zero", function()
    local s = reporter.summarize({})
    t.assert_eq(s.total, 0, "total")
    t.assert_eq(s.by_severity.CRITICAL, 0, "CRITICAL count")
    t.assert_eq(s.by_severity.WARNING,  0, "WARNING count")
    t.assert_eq(s.by_severity.INFO,     0, "INFO count")
    t.assert_eq(#s.findings, 0, "findings length")
  end)

  t.it("nil input is treated as empty", function()
    local s = reporter.summarize(nil)
    t.assert_eq(s.total, 0, "total")
    t.assert_eq(#s.findings, 0, "findings length")
  end)

  t.it("single CRITICAL finding -> counts only CRITICAL", function()
    local s = reporter.summarize({ F_R001_CRIT })
    t.assert_eq(s.total, 1, "total")
    t.assert_eq(s.by_severity.CRITICAL, 1, "CRITICAL count")
    t.assert_eq(s.by_severity.WARNING,  0, "WARNING count")
    t.assert_eq(s.by_severity.INFO,     0, "INFO count")
  end)

  t.it("single WARNING finding -> counts only WARNING", function()
    local s = reporter.summarize({ F_R004_WARN })
    t.assert_eq(s.total, 1, "total")
    t.assert_eq(s.by_severity.CRITICAL, 0, "CRITICAL count")
    t.assert_eq(s.by_severity.WARNING,  1, "WARNING count")
    t.assert_eq(s.by_severity.INFO,     0, "INFO count")
  end)

  t.it("single INFO finding -> counts only INFO", function()
    local s = reporter.summarize({ F_R013_INFO })
    t.assert_eq(s.total, 1, "total")
    t.assert_eq(s.by_severity.CRITICAL, 0, "CRITICAL count")
    t.assert_eq(s.by_severity.WARNING,  0, "WARNING count")
    t.assert_eq(s.by_severity.INFO,     1, "INFO count")
  end)

  t.it("mixed 4 findings: counts are correct", function()
    local s = reporter.summarize({ F_R013_INFO, F_R001_CRIT, F_R004_WARN, F_R008_CRIT })
    t.assert_eq(s.total, 4, "total")
    t.assert_eq(s.by_severity.CRITICAL, 2, "CRITICAL count")
    t.assert_eq(s.by_severity.WARNING,  1, "WARNING count")
    t.assert_eq(s.by_severity.INFO,     1, "INFO count")
  end)

  t.it("sort: severity priority CRITICAL before WARNING before INFO", function()
    local s = reporter.summarize({ F_R013_INFO, F_R004_WARN, F_R001_CRIT })
    t.assert_eq(s.findings[1].severity, "CRITICAL", "first severity")
    t.assert_eq(s.findings[2].severity, "WARNING",  "second severity")
    t.assert_eq(s.findings[3].severity, "INFO",     "third severity")
  end)

  t.it("sort: same severity sorted by rule_id ascending", function()
    local f_r005_crit = {
      rule_id  = "R005",
      severity = "CRITICAL",
      file     = "server.cfg",
      line     = nil,
      message  = "synthetic",
    }
    local s = reporter.summarize({ f_r005_crit, F_R001_CRIT })
    t.assert_eq(s.findings[1].rule_id, "R001", "first rule_id")
    t.assert_eq(s.findings[2].rule_id, "R005", "second rule_id")
  end)

end)

-- ---------------------------------------------------------------------------
-- Group B: reporter.format_console (byte-exact assertions)
-- ---------------------------------------------------------------------------
t.describe("reporter.format_console", function()

  t.it("empty summary -> exact 3-line output ending with newline", function()
    local s = reporter.summarize({})
    local actual = reporter.format_console(s)
    local expected =
      "[fxpreflight] === Preflight report ===\n" ..
      "[fxpreflight] No findings.\n" ..
      "[fxpreflight] === Summary: 0 CRITICAL, 0 WARNING, 0 INFO ===\n"
    t.assert_eq(actual, expected, "empty console output")
  end)

  t.it("single CRITICAL finding with line=nil -> exact bytes", function()
    local s = reporter.summarize({ F_R001_CRIT })
    local actual = reporter.format_console(s)
    local expected =
      "[fxpreflight] === Preflight report ===\n" ..
      "[fxpreflight] [CRITICAL] R001  server.cfg            Missing required network directive(s): endpoint_add_tcp\n" ..
      "[fxpreflight] === Summary: 1 CRITICAL, 0 WARNING, 0 INFO ===\n"
    t.assert_eq(actual, expected, "single CRITICAL console output")
  end)

  t.it("single WARNING with line=12 -> file:line column, [WARNING ] padding", function()
    local s = reporter.summarize({ F_R004_WARN })
    local actual = reporter.format_console(s)
    local expected =
      "[fxpreflight] === Preflight report ===\n" ..
      "[fxpreflight] [WARNING ] R004  server.cfg:12         sv_hostname is still set to a default value: 'Default FXServer'\n" ..
      "[fxpreflight] === Summary: 0 CRITICAL, 1 WARNING, 0 INFO ===\n"
    t.assert_eq(actual, expected, "single WARNING console output")
  end)

  t.it("single INFO -> [INFO    ] severity bracket has 4 trailing spaces", function()
    local s = reporter.summarize({ F_R013_INFO })
    local actual = reporter.format_console(s)
    local expected =
      "[fxpreflight] === Preflight report ===\n" ..
      "[fxpreflight] [INFO    ] R013  fxmanifest.lua        fxmanifest.lua sets lua54 'no'; Lua 5.3 was deprecated in June 2025\n" ..
      "[fxpreflight] === Summary: 0 CRITICAL, 0 WARNING, 1 INFO ===\n"
    t.assert_eq(actual, expected, "single INFO console output")
  end)

  t.it("marquee 4-finding multi-severity full output", function()
    local s = reporter.summarize({ F_R013_INFO, F_R001_CRIT, F_R004_WARN, F_R008_CRIT })
    local actual = reporter.format_console(s)
    local expected =
      "[fxpreflight] === Preflight report ===\n" ..
      "[fxpreflight] [CRITICAL] R001  server.cfg            Missing required network directive(s): endpoint_add_tcp\n" ..
      "[fxpreflight] [CRITICAL] R008  fxmanifest.lua        fxmanifest.lua is missing a valid fx_version field\n" ..
      "[fxpreflight] [WARNING ] R004  server.cfg:12         sv_hostname is still set to a default value: 'Default FXServer'\n" ..
      "[fxpreflight] [INFO    ] R013  fxmanifest.lua        fxmanifest.lua sets lua54 'no'; Lua 5.3 was deprecated in June 2025\n" ..
      "[fxpreflight] === Summary: 2 CRITICAL, 1 WARNING, 1 INFO ===\n"
    t.assert_eq(actual, expected, "marquee console output")
  end)

  t.it("preserves message containing single quotes verbatim", function()
    local s = reporter.summarize({ F_R004_WARN })
    local actual = reporter.format_console(s)
    local expected =
      "[fxpreflight] === Preflight report ===\n" ..
      "[fxpreflight] [WARNING ] R004  server.cfg:12         sv_hostname is still set to a default value: 'Default FXServer'\n" ..
      "[fxpreflight] === Summary: 0 CRITICAL, 1 WARNING, 0 INFO ===\n"
    t.assert_eq(actual, expected, "byte-exact output preserves single quotes")
  end)

  t.it("output ends with a single trailing newline", function()
    local s = reporter.summarize({ F_R013_INFO, F_R001_CRIT, F_R004_WARN, F_R008_CRIT })
    local actual = reporter.format_console(s)
    t.assert_eq(actual:sub(-1), "\n", "last character is newline")
    t.assert_true(actual:sub(-2, -1) ~= "\n\n", "no double trailing newline")
  end)

end)

-- ---------------------------------------------------------------------------
-- Group C: reporter.format_markdown (byte-exact assertions)
-- ---------------------------------------------------------------------------
t.describe("reporter.format_markdown", function()

  t.it("empty summary -> exact No-findings markdown", function()
    local s = reporter.summarize({})
    local actual = reporter.format_markdown(s)
    local expected =
      "# fxpreflight Report\n" ..
      "\n" ..
      "**Summary:** 0 CRITICAL, 0 WARNING, 0 INFO\n" ..
      "\n" ..
      "No findings.\n"
    t.assert_eq(actual, expected, "empty markdown output")
  end)

  t.it("only CRITICAL findings -> no WARNING or INFO sections", function()
    local s = reporter.summarize({ F_R001_CRIT })
    local actual = reporter.format_markdown(s)
    local expected =
      "# fxpreflight Report\n" ..
      "\n" ..
      "**Summary:** 1 CRITICAL, 0 WARNING, 0 INFO\n" ..
      "\n" ..
      "## CRITICAL (1)\n" ..
      "\n" ..
      "- **R001** — `server.cfg` — Missing required network directive(s): endpoint_add_tcp\n"
    t.assert_eq(actual, expected, "CRITICAL-only markdown output")
  end)

  t.it("only INFO findings -> no CRITICAL or WARNING sections", function()
    local s = reporter.summarize({ F_R013_INFO })
    local actual = reporter.format_markdown(s)
    local expected =
      "# fxpreflight Report\n" ..
      "\n" ..
      "**Summary:** 0 CRITICAL, 0 WARNING, 1 INFO\n" ..
      "\n" ..
      "## INFO (1)\n" ..
      "\n" ..
      "- **R013** — `fxmanifest.lua` — fxmanifest.lua sets lua54 'no'; Lua 5.3 was deprecated in June 2025\n"
    t.assert_eq(actual, expected, "INFO-only markdown output")
  end)

  t.it("marquee 4-finding multi-severity full markdown", function()
    local s = reporter.summarize({ F_R013_INFO, F_R001_CRIT, F_R004_WARN, F_R008_CRIT })
    local actual = reporter.format_markdown(s)
    local expected =
      "# fxpreflight Report\n" ..
      "\n" ..
      "**Summary:** 2 CRITICAL, 1 WARNING, 1 INFO\n" ..
      "\n" ..
      "## CRITICAL (2)\n" ..
      "\n" ..
      "- **R001** — `server.cfg` — Missing required network directive(s): endpoint_add_tcp\n" ..
      "- **R008** — `fxmanifest.lua` — fxmanifest.lua is missing a valid fx_version field\n" ..
      "\n" ..
      "## WARNING (1)\n" ..
      "\n" ..
      "- **R004** — `server.cfg:12` — sv_hostname is still set to a default value: 'Default FXServer'\n" ..
      "\n" ..
      "## INFO (1)\n" ..
      "\n" ..
      "- **R013** — `fxmanifest.lua` — fxmanifest.lua sets lua54 'no'; Lua 5.3 was deprecated in June 2025\n"
    t.assert_eq(actual, expected, "marquee markdown output")
  end)

  t.it("output ends with a single trailing newline", function()
    local s = reporter.summarize({ F_R013_INFO, F_R001_CRIT, F_R004_WARN, F_R008_CRIT })
    local actual = reporter.format_markdown(s)
    t.assert_eq(actual:sub(-1), "\n", "last character is newline")
    t.assert_true(actual:sub(-2, -1) ~= "\n\n", "no double trailing newline")
  end)

end)
