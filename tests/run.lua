-- tests/run.lua
-- Minimal test runner for fxpreflight. No external dependencies.
-- Run from the workspace root: lua tests/run.lua
-- Exit code: 0 = all tests passed, 1 = one or more failures.

-- Make shared.* and tests.* resolvable from the workspace root.
package.path = './?.lua;./?/init.lua;' .. package.path

local M = {}

-- Self-register before test files are loaded so that require('tests.run')
-- inside those files returns this same module table (Lua caches by key).
package.loaded['tests.run'] = M

local pass_count = 0
local fail_count = 0

io.write("================================\n")
io.write("fxpreflight test runner\n")
io.write("================================\n")

-- Begin a named group of tests. fn() is called immediately.
function M.describe(name, fn)
  io.write("\n" .. name .. "\n")
  fn()
end

-- Declare a single test case. fn() is called immediately inside pcall so
-- that a failing assertion does not abort the rest of the suite.
function M.it(name, fn)
  local ok, err = pcall(fn)
  if ok then
    io.write("  [PASS] " .. name .. "\n")
    pass_count = pass_count + 1
  else
    io.write("  [FAIL] " .. name .. "\n")
    io.write("    " .. tostring(err) .. "\n")
    fail_count = fail_count + 1
  end
end

-- Assert that two values are equal (using ==).
function M.assert_eq(actual, expected, message)
  if actual ~= expected then
    local prefix = message and (message .. ": ") or ""
    error(prefix .. "expected " .. tostring(expected)
          .. ", got " .. tostring(actual), 2)
  end
end

-- Assert that a value is truthy (not nil and not false).
function M.assert_true(value, message)
  if not value then
    error((message or "expected truthy value")
          .. ", got " .. tostring(value), 2)
  end
end

-- Assert that a value is nil.
function M.assert_nil(value, message)
  if value ~= nil then
    local prefix = message and (message .. ": ") or ""
    error(prefix .. "expected nil, got " .. tostring(value), 2)
  end
end

-- Print the final summary and exit with the appropriate code.
function M.report_and_exit()
  io.write("\n--------------------------------\n")
  io.write(pass_count .. " passed, " .. fail_count .. " failed\n")
  io.write("--------------------------------\n")
  if fail_count > 0 then
    os.exit(1)
  else
    os.exit(0)
  end
end

-- discover and require test files
require('tests.test_parser_servercfg')
require('tests.test_rules_critical_cfg')
require('tests.test_parser_fxmanifest')
require('tests.test_rules_critical_fxmanifest')
require('tests.test_rules_warning_cfg')
require('tests.test_rules_warning_fxmanifest')
-- print summary, exit with code 0 if all passed, 1 otherwise
M.report_and_exit()
