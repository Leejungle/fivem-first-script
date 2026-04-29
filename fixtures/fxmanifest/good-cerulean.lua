-- Good fxmanifest.lua — targets fx_version 'cerulean'
-- Expected fxpreflight result: zero findings.

fx_version 'cerulean'
games { 'gta5' }

author 'fxpreflight Fixture'
description 'A minimal but fully valid example resource manifest.'
version '1.0.0'

-- lua54 'yes' is deprecated as of June 2025 (Lua 5.4 is now the universal
-- default). The line is kept here as harmless documentation of the old opt-in.
lua54 'yes'

-- Client-side scripts
client_scripts {
    'client/main.lua',
    'client/utils.lua',
}

-- Server-side scripts
server_scripts {
    'server/main.lua',
}

-- Shared scripts loaded on both client and server
shared_scripts {
    'shared/config.lua',
}
