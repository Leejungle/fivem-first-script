-- BAD — deprecated __resource.lua format
-- What is wrong: this file uses the old __resource.lua syntax that was
-- deprecated and replaced by fxmanifest.lua. A resource that ships an
-- __resource.lua instead of fxmanifest.lua will produce deprecation warnings
-- on modern FXServer versions and will eventually stop loading entirely.
-- fxpreflight should fire R010 CRITICAL when it finds a file named
-- __resource.lua in a resource directory.
--
-- NOTE: This file is stored as bad-deprecated-resource.lua so that it does
-- not actually confuse tools in this repository. The test suite references it
-- by its descriptive name and simulates it being named __resource.lua.

resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'

-- The old format used 'client_script' (singular) and 'server_script' (singular)
-- instead of the table-based syntax in fxmanifest.lua.
client_script 'client/main.lua'
server_script 'server/main.lua'
