# fixtures/fxmanifest

This folder contains `fxmanifest.lua` sample files (and one deprecated
`__resource.lua`-style sample) used as static test inputs for fxpreflight's
manifest rule engine.

## Files

| File | Purpose |
|------|---------|
| `good-cerulean.lua` | A fully valid fxmanifest.lua targeting `fx_version 'cerulean'`. Should produce zero findings. |
| `bad-deprecated-resource.lua` | Content modeled on the deprecated `__resource.lua` format. Stored here as a `.lua` file; the test suite will treat it as if it were named `__resource.lua`. Expected to trigger R010 CRITICAL and possibly R008 CRITICAL. |

## Conventions

- These files are read-only fixture inputs. fxpreflight never writes to them.
- The "bad" file is stored with a descriptive name rather than the literal
  deprecated filename to avoid confusing editors and version-control tools.
  The test suite passes the correct filename when simulating the failing
  scenario for R010.
