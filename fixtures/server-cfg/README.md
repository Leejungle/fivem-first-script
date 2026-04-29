# fixtures/server-cfg

This folder contains `server.cfg` sample files used as static test inputs for
fxpreflight's rule engine. No live FXServer is required to use these files.

## Files

| File | Purpose |
|------|---------|
| `good-minimal.cfg` | A minimal but fully valid server.cfg. Should produce zero findings. |
| `good-full.cfg` | A more complete valid server.cfg with ACE groups, multiple resources, and common optional directives. Should produce zero findings. |
| `bad-missing-endpoint.cfg` | Valid in all other respects but missing `endpoint_add_tcp` and `endpoint_add_udp`. Expected to trigger R001 CRITICAL. |
| `bad-license-key.cfg` | Contains an obviously invalid `sv_licenseKey` value. Expected to trigger R002 CRITICAL. |

## Conventions

- Lines starting with `#` are comments.
- All files use the real FiveM `server.cfg` directive syntax.
- License key values in "good" fixtures use a clearly marked placeholder
  (`PASTE_KEY_HERE_PLACEHOLDER_OK_FOR_FIXTURE`) so the files are valid in
  structure without containing a real credential.
- These files are inputs only. fxpreflight never writes to them.
