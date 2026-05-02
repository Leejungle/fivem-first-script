-- shared/reporter.lua
-- Pure-function module that summarizes and formats fxpreflight findings.
-- No file I/O, no network calls, no FiveM natives, no global state.

local M = {}

-- ---------------------------------------------------------------------------
-- Sort helpers
-- ---------------------------------------------------------------------------
local SEVERITY_RANK = {
  CRITICAL = 1,
  WARNING  = 2,
  INFO     = 3,
}

local function compare_findings(a, b)
  local ra = SEVERITY_RANK[a.severity] or 99
  local rb = SEVERITY_RANK[b.severity] or 99
  if ra ~= rb then return ra < rb end
  if a.rule_id ~= b.rule_id then return a.rule_id < b.rule_id end
  if a.file ~= b.file then return a.file < b.file end
  local la = a.line or 0
  local lb = b.line or 0
  return la < lb
end

-- ---------------------------------------------------------------------------
-- Format helpers
-- ---------------------------------------------------------------------------
local SEVERITY_LABEL = {
  CRITICAL = "[CRITICAL]",
  WARNING  = "[WARNING ]",
  INFO     = "[INFO    ]",
}

local SEVERITY_ORDER = { "CRITICAL", "WARNING", "INFO" }

local CONSOLE_PREFIX = "[fxpreflight] "

local function file_column(finding)
  if finding.line == nil then
    return finding.file
  end
  return finding.file .. ":" .. tostring(finding.line)
end

-- ---------------------------------------------------------------------------
-- M.summarize(findings) -> { total, by_severity, findings }
-- ---------------------------------------------------------------------------
function M.summarize(findings)
  findings = findings or {}

  -- Shallow copy of the input array so we never mutate the caller's table.
  local sorted = {}
  for i = 1, #findings do
    sorted[i] = findings[i]
  end
  table.sort(sorted, compare_findings)

  local summary = {
    total       = #sorted,
    by_severity = { CRITICAL = 0, WARNING = 0, INFO = 0 },
    findings    = sorted,
  }
  for _, f in ipairs(sorted) do
    if summary.by_severity[f.severity] ~= nil then
      summary.by_severity[f.severity] = summary.by_severity[f.severity] + 1
    end
  end
  return summary
end

-- ---------------------------------------------------------------------------
-- M.format_console(summary) -> string
-- ---------------------------------------------------------------------------
function M.format_console(summary)
  local lines = {}
  table.insert(lines, CONSOLE_PREFIX .. "=== Preflight report ===")

  if summary.total == 0 then
    table.insert(lines, CONSOLE_PREFIX .. "No findings.")
  else
    for _, f in ipairs(summary.findings) do
      local sev = SEVERITY_LABEL[f.severity] or ("[" .. tostring(f.severity) .. "]")
      local fl  = file_column(f)
      table.insert(lines,
        CONSOLE_PREFIX
        .. string.format("%s %s  %-20s  %s", sev, f.rule_id, fl, f.message))
    end
  end

  table.insert(lines,
    CONSOLE_PREFIX
    .. string.format("=== Summary: %d CRITICAL, %d WARNING, %d INFO ===",
                     summary.by_severity.CRITICAL,
                     summary.by_severity.WARNING,
                     summary.by_severity.INFO))

  return table.concat(lines, "\n") .. "\n"
end

-- ---------------------------------------------------------------------------
-- M.format_markdown(summary) -> string
-- ---------------------------------------------------------------------------
function M.format_markdown(summary)
  if summary.total == 0 then
    return "# fxpreflight Report\n"
        .. "\n"
        .. "**Summary:** 0 CRITICAL, 0 WARNING, 0 INFO\n"
        .. "\n"
        .. "No findings.\n"
  end

  local parts = {}
  table.insert(parts, "# fxpreflight Report\n")
  table.insert(parts, "\n")
  table.insert(parts, string.format(
    "**Summary:** %d CRITICAL, %d WARNING, %d INFO\n",
    summary.by_severity.CRITICAL,
    summary.by_severity.WARNING,
    summary.by_severity.INFO))
  table.insert(parts, "\n")

  for _, sev in ipairs(SEVERITY_ORDER) do
    local count = summary.by_severity[sev] or 0
    if count > 0 then
      table.insert(parts, string.format("## %s (%d)\n", sev, count))
      table.insert(parts, "\n")
      for _, f in ipairs(summary.findings) do
        if f.severity == sev then
          local fl = file_column(f)
          table.insert(parts, string.format(
            "- **%s** — `%s` — %s\n", f.rule_id, fl, f.message))
        end
      end
      table.insert(parts, "\n")
    end
  end

  -- Drop the last trailing blank line so the output ends with the last
  -- finding line + a single "\n".
  if parts[#parts] == "\n" then
    parts[#parts] = nil
  end

  return table.concat(parts)
end

return M
