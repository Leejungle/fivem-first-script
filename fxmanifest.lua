fx_version 'cerulean'
games { 'gta5' }

author 'Lee_Jungle'
description 'Static analysis preflight check for FiveM server.cfg and resource manifests.'
version '0.1.0'

lua54 'yes'

server_script 'server/main.lua'

-- shared/ modules are loaded at runtime by server/main.lua via LoadResourceFile().
-- They use the "local M = {}; ... return M" pattern, which is incompatible with
-- the server_scripts top-down execution model. Declaring them under files{} keeps
-- them packaged into the resource and available for LoadResourceFile to read.
files {
  'shared/parser_servercfg.lua',
  'shared/parser_fxmanifest.lua',
  'shared/rules.lua',
  'shared/reporter.lua',
}
