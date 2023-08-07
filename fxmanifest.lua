fx_version 'cerulean'

game 'gta5'

description 'Rewpparo - Vehicle Ownership'
lua54 'yes'
version '0.0.0'

shared_scripts {
	'@es_extended/imports.lua',
	'@es_extended/locale.lua',
	'locales/*.lua',
	'config.lua',
}

client_scripts {
    'client.lua',
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
    'server.lua',
}

server_exports {
	'RunPlate',
	'SetVehicleOwner',
}

dependencies {
	'es_extended',
}
