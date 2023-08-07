Config = {}

Config.Locale = GetConvar('esx:locale', 'en')

--Permission to use the built in commands. Removing those lines will disable
--Alternatively, you can use Aces command.rw_vehicle.write and command.rw_vehicle.read. Admins typically have command.***
Config.RegistrationRead = {['police']=0, ['cardealer']=0}
Config.RegistrationWrite = {['police']=1, ['cardealer']=0}

Config.CruiseControl = {50,90,140}
