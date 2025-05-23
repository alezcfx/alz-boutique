fx_version 'cerulean'
game 'gta5'

author 'Alez - https://github.com/alezcfx'
description 'Boutique style sensity'
version '1.0.0'

shared_script '@es_extended/imports.lua'
shared_script 'config.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/main.lua'
}