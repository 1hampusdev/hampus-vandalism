fx_version 'cerulean'
game 'gta5'

name 'qbx_karin_vandal_mission'
author 'Hampus'
description 'Hampus Resources - https://discord.gg/Kk4RDxmr2n'
version '1.0.0'

lua54 'yes'

shared_script {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    '@qbx_core/import.lua',
    '@ox_target/init.lua',
    'locales/*.lua',
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    '@qbx_core/import.lua',
    'server.lua'
}
