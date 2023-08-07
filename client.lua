----------------------
-- HELPER FUNCTIONS --
----------------------
function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

------------------
-- Vehicle menu --
------------------
RegisterCommand('VehicleMenu', function(source, args, rawCommand)
    VehicleMenu()
end,false)

function VehicleMenuCruiseControl()
    local elems = {
        {label = 'off', value = 'off'},
    }
    for i,v in pairs(Config.CruiseControl) do
        table.insert(elems, {label=tostring(v), value=tostring(v)})
    end

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'CruiseControl',{
        title    = 'Vehicle Menu',
        align = 'top-right',
        elements = elems
    },
    function(data, menu)
        if data.current.value=='off' then 
            menu.close()
            --TODO : close cruise control
        else
            menu.close()
            --TODO : set cruisecontrol to tonumber(data.current.value)
        end
    end,
    function(data, menu)
        menu.close()
    end)
end

function VehicleMenuEngine()
end

function VehicleMenuDoors()
end

function VehicleMenuLights()
end

function VehicleMenu()
    local elems = {
        {label = 'CruiseControl', value = 'cruisecontrol'},
        {label = 'Engine', value = 'engine'},
        {label = 'Doors', value = 'doors'},
        {label = 'Lights', value = 'lights'},
    }
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'VehicleMenu',{
        title    = 'Vehicle Menu',
        align = 'top-right',
        elements = elems
    },
    function(data, menu)
        Citizen.Trace(data.current.value.."\n")
        if data.current.value=='cruisecontrol' then 
            menu.close()
            VehicleMenuCruiseControl()
        elseif data.current.value=='engine' then
            menu.close()
            VehicleMenuEngine()
        elseif data.current.value=='doors' then 
            menu.close()
            VehicleMenuDoors()
        elseif data.current.value=='lights' then 
            menu.close()
            VehicleMenuLights()
        end
    end,
    function(data, menu)
        menu.close()
    end)
end

-----------------------------
-- Vehicle Registration UI --
-----------------------------
VehicleRegistrationPlate = ""

RegisterCommand('VehicleRegistration', function(source, args, rawCommand)
    if #args>0 then VehicleRegistrationPlate=args[1] end
    VehicleRegistrationMenu()
end,false)

function VehicleRegistrationPlateselect()
    --Text box to enter a plate to run
    ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'platechooser',{ title = ('Enter a plate to run') },
    --submit
    function(data, menu)
        menu.close()
        VehicleRegistrationPlate = data.value
        VehicleRegistrationMenu()
    end,
    --cancel
    function(data, menu)
        menu.close()
        VehicleRegistrationMenu()
    end)
end

function VehicleRegistrationOwner()
    --Select players in area and change owner. Option to set to no owner if job vehicle
    data = {
        head = {"Choose new owner", ""},
        rows = {
            {data = 'PlayerChooser', cols = {"Clear Owner", '{{Choose|nil}}'} },
            {data = 'PlayerChooser', cols = {ESX.PlayerData.lastName.." "..ESX.PlayerData.firstName, '{{Choose|'..ESX.PlayerData.identifier..'}}'} },
        }
    }

    players = ESX.Game.GetPlayersInArea(ESX.PlayerData.coords, 10)
    for i,v in pairs(players) do
        table.insert(data.rows, { data = 'owner', cols = {v.Name, '{{Choose|'..v.identifier..'}}'} })
    end

    ESX.UI.Menu.Open("list", GetCurrentResourceName(), 'PlayerChooser', data, 
    --submit
    function(data,menu)
        local id = data.value
        if id == "nil" then id = nil end
        TriggerServerEvent('rw_vehicle:SetOwner', VehicleRegistrationPlate, id)
        menu.close()
        Wait(500) --Wait for server event to process
        VehicleRegistrationMenu()
    end,
    --Menu canceled
    function(data,menu)
        menu.close()
        VehicleRegistrationMenu()
    end)
end

function VehicleRegistrationJob()
    --list available jobs and change job
    ESX.TriggerServerCallback('rw_vehicle:ListJobs', function(jobs)
        --Make elements for jobs
        data = {
            head = {"Select job", ""},
            rows = { { data = 'ListJobs', cols = {"Clear Job", '{{Choose|nil}}'} } }
        }
        for k,v in pairs(jobs) do
            table.insert(data.rows, { data = 'ListJobs', cols = {v, '{{Choose|'..k..'}}'} })
        end
        ESX.UI.Menu.Open("list", GetCurrentResourceName(), 'Registration', data, 
        -- Item selected
        function(data,menu)
            local newjob = data.value
            if newjob=="nil" then newjob=nil end
            TriggerServerEvent('rw_vehicle:SetJob', VehicleRegistrationPlate, newjob)
            Wait(500) --Give time to server to process
            menu.close()
            VehicleRegistrationMenu()
        end,
        --Menu canceled
        function(data, menu)
            menu.close()
            VehicleRegistrationMenu()
        end)
    end)
end

function VehicleRegistrationMenu()
    ESX.TriggerServerCallback('rw_vehicle:RunPlateCb', function(run)
        --Load plate select if incorrect plate
        if not run.valid then
            ESX.ShowNotification("Incorrect plate", "error")
            VehicleRegistrationPlateselect()
            return
        end
        --Load vehicle information from plate
        data = {}
        data.head = {"Vehicle Regsitration Form", "Read", "Write"}
        data.rows = {
                { data = 'Registration', cols = {"Request car info", '', '{{Load|Req}}'} },
                { data = 'Registration', cols = {"Plate", run.plate, ''} },
                { data = 'Registration', cols = {"Model", GetDisplayNameFromVehicleModel(run.model), ''} },
                --{ data = 'Registration', cols = {"Color", color, ''} },
                { data = 'Registration', cols = {"Job", run.job, '{{Change|Job}}'} },
                { data = 'Registration', cols = {"Owner", run.lastname.." "..run.firstname, '{{Change|Owner}}'} },
                { data = 'Registration', cols = {"DoB", run.dob, ''} },
                { data = 'Registration', cols = {'', '', '{{Close|Close}}'} },
            }
        ESX.UI.Menu.Open("list", GetCurrentResourceName(), 'Registration', data, 
        -- Item selected
        function(data,menu)
            if     data.value=="Req" then
                menu.close()
                VehicleRegistrationPlateselect()
            elseif data.value=="Owner" then
                menu.close()
                VehicleRegistrationOwner()
            elseif data.value=="Job" then
                menu.close()
                VehicleRegistrationJob()
            elseif data.value=="Close" then
                VehicleRegistrationPlate=""
                menu.close()
            end
        end,
        --Menu canceled
        function(data, menu)
            VehicleRegistrationPlate=""
            menu.close()
        end)
    end, VehicleRegistrationPlate, false)
end

-------------------
-- DEBUG VEHICLE --
-------------------

function printwheel(vehicle, wheelid)
    --Will also return if tyre is removed
    --if not DoesVehicleTyreExist(vehicle, wheelid) then return end
    --Workaround, health null but tyre not exploded is a good indication that that's a fake tyre ^^
    if GetTyreHealth(vehicle, wheelid)==0 and not IsVehicleTyreBurst(vehicle, wheelid, false) then return end

    if wheelid==0 then Citizen.Trace("  Driver front, ") end
    if wheelid==1 then Citizen.Trace("  Passenger Front, ") end
    if wheelid==2 then Citizen.Trace("  Driver mid, ") end
    if wheelid==3 then Citizen.Trace("  Passenger mid, ") end
    if wheelid==4 then Citizen.Trace("  Driver rear, ") end
    if wheelid==5 then Citizen.Trace("  Passenger rear, ") end
    if wheelid==45 then Citizen.Trace("  Driver mid trailer, ") end
    if wheelid==47 then Citizen.Trace("  Passenger mid trailer, ") end

    Citizen.Trace("health : "..GetTyreHealth(vehicle, wheelid)..", ")
    Citizen.Trace("Burst : "..tostring(IsVehicleTyreBurst(vehicle, wheelid, false))..", ")
    Citizen.Trace("Completely : "..tostring(IsVehicleTyreBurst(vehicle, wheelid, true))..", ")
    Citizen.Trace("Powered : "..GetVehicleWheelIsPowered(vehicle, wheelid)..", ")
    Citizen.Trace("\n")
end

RegisterCommand('DebugVehicle', function(source, args, rawCommand)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, true)
    if not vehicle then
        --TODO : Not reliable, use worldGetAllVehicles instead ?
        vehicle = GetClosestVehicle(GetEntityCoords(ped).x, GetEntityCoords(ped).y, GetEntityCoords(ped).z, 10, 0, 70)
    end
    if not vehicle then return end
    local model = GetEntityModel(vehicle)
    --Critical events
    if not IsVehicleDriveable(vehicle, 0) then Citizen.Trace(" --UNDRIVABLE-- ") end
    if IsVehicleEngineOnFire(vehicle) then Citizen.Trace(" --ON FIRE-- ") end
    if IsVehicleAudiblyDamaged(vehicle) then Citizen.Trace(" --MAKES A SOUND-- ") end
    if IsVehicleBeingHalted(vehicle) then Citizen.Trace(" --HALTED-- ") end
    if IsEntityPositionFrozen(vehicle) then Citizen.Trace(" --FROZEN-- ") end
    if not IsVehicleOnAllWheels(vehicle) then Citizen.Trace(" --NOT ON WHEELS-- ") end
    if IsVehicleStolen(vehicle) then Citizen.Trace(" --STOLEN-- ") end
    --Owner information
    plate = GetVehicleNumberPlateText(vehicle)
    Citizen.Trace("OWNER : Plate : "..GetVehicleNumberPlateText(vehicle)..", ")
    Citizen.Trace("\n")
    --Model information
    Citizen.Trace("MODEL : Make : "..GetMakeNameFromVehicleModel(model)..", ")
    Citizen.Trace("Model : "..GetDisplayNameFromVehicleModel(model)..", ")
    if IsVehicleAConvertible(vehicle) then Citizen.Trace("Convertible, ") end
    --Citizen.Trace("Type : "..GetVehicleType(vehicle)..", ") --Server only
    Occupants = GetVehicleNumberOfPassengers(vehicle)
    if not IsVehicleSeatFree(vehicle, -1) then Occupants = Occupants+1 end
    Citizen.Trace("Seats : "..Occupants.."/"..GetVehicleModelNumberOfSeats(model)..", ")
    Citizen.Trace("Value : "..GetVehicleModelValue(model)..", ")
    Citizen.Trace("Num Gear: "..GetVehicleHighGear(vehicle)..", ")
    Citizen.Trace("Acceleration : "..round(GetVehicleModelAcceleration(model),2)..", ")
    Citizen.Trace("\n   ")
    Citizen.Trace("Agility : "..round(GetVehicleModelEstimatedAgility(model),2)..", ")
    Citizen.Trace("Max speed : "..round(GetVehicleModelEstimatedMaxSpeed(model),2)..", ")
    Citizen.Trace("Max breaking : "..round(GetVehicleModelMaxBraking(model),2)..", ")
    Citizen.Trace("Max traction : "..round(GetVehicleModelMaxTraction(model),2)..", ")
    Citizen.Trace("Move resistance : "..round(GetVehicleModelMoveResistance(model),2)..", ")
    Citizen.Trace("\n")
    --HEALTH
    Citizen.Trace("STATUS : Health : "..tostring(GetVehicleBodyHealth(vehicle))..", ")
    Citizen.Trace("Health% : "..GetVehicleHealthPercentage(vehicle)..", ")
    Citizen.Trace("Tank health : "..GetVehiclePetrolTankHealth(vehicle)..", ")
    Citizen.Trace("Fuel : "..round(GetVehicleFuelLevel(vehicle),2)..", ")
    Citizen.Trace("Dirt : "..round(GetVehicleDirtLevel(vehicle),2)..", ")
    Citizen.Trace("Handbrake : "..tostring(GetVehicleHandbrake(vehicle))..", ")
    if IsVehicleBumperBouncing(vehicle, true) then Citizen.Trace("Front bumper bouncing, ") end
    if IsVehicleBumperBouncing(vehicle, false) then Citizen.Trace("Rear bumper bouncing, ") end
    if IsVehicleBumperBrokenOff(vehicle, true) then Citizen.Trace("Front bumper broken, ") end
    if IsVehicleBumperBrokenOff(vehicle, false) then Citizen.Trace("Rear bumper broken, ") end
    Citizen.Trace("\n")
    --DOORS
    Citizen.Trace("DOORS : "..GetNumberOfVehicleDoors(vehicle)..", ")
    Citizen.Trace("lock : ")
    if GetVehicleDoorLockStatus(vehicle)==0 then Citizen.Trace("Unlocked") end
    if GetVehicleDoorLockStatus(vehicle)==1 then Citizen.Trace("Unlocked") end
    if GetVehicleDoorLockStatus(vehicle)==2 then Citizen.Trace("Locked") end
    if GetVehicleDoorLockStatus(vehicle)==3 then Citizen.Trace("Locked for player") end
    if GetVehicleDoorLockStatus(vehicle)==4 then Citizen.Trace("Stick Player inside") end
    if GetVehicleDoorLockStatus(vehicle)==7 then Citizen.Trace("Can be broken into") end
    if GetVehicleDoorLockStatus(vehicle)==8 then Citizen.Trace("Can be broken into persist") end
    if GetVehicleDoorLockStatus(vehicle)==10 then Citizen.Trace("Cannot be tried to enter") end
    Citizen.Trace("\n")
    for i=0,5,1 do
        if GetIsDoorValid(vehicle, i) then
            Citizen.Trace("  Door : "..i..", ")
            if i==0 then Citizen.Trace("Driver Front, ") end
            if i==1 then Citizen.Trace("Driver Back, ") end
            if i==2 then Citizen.Trace("Passenger Front, ") end
            if i==3 then Citizen.Trace("Passenger Back, ") end
            if i==4 then Citizen.Trace("Bonnet, ") end
            if i==5 then Citizen.Trace("Hood, ") end
            Citizen.Trace("damaged : "..tostring(IsVehicleDoorDamaged(vehicle, i))..", ")
            Citizen.Trace("open : "..tostring(IsVehicleDoorFullyOpen(vehicle, i))..", ")
            Citizen.Trace("\n")
        end
    end
    --Engine
    Citizen.Trace("ENGINE : running : "..tostring(GetIsVehicleEngineRunning(vehicle))..", ")
    Citizen.Trace("Starting : "..tostring(IsVehicleEngineStarting(vehicle))..", ")
    Citizen.Trace("Health : "..GetVehicleEngineHealth(vehicle)..", ")
    Citizen.Trace("Needs hotwire : "..tostring(IsVehicleNeedsToBeHotwired(vehicle))..", ")
    Citizen.Trace("Temperature : "..round(GetVehicleEngineTemperature(vehicle),2)..", ")
    Citizen.Trace("Oil level : "..GetVehicleOilLevel(vehicle)..", ")
    Citizen.Trace("\n   ")
    Citizen.Trace("Turbo pressure : "..GetVehicleTurboPressure(vehicle)..", ")
    Citizen.Trace("Clutch : "..round(GetVehicleClutch(vehicle),2)..", ")
    Citizen.Trace("Gear : "..GetVehicleCurrentGear(vehicle)..", ")
    Citizen.Trace("High Gear : "..GetVehicleHighGear(vehicle)..", ")
    Citizen.Trace("RPM : "..round(GetVehicleCurrentRpm(vehicle),2)..", ")
    Citizen.Trace("Cheat Power : "..GetVehicleCheatPowerIncrease(vehicle)..", ")
    Citizen.Trace("\n")
    --Wheels
    Citizen.Trace("WHEELS : "..GetVehicleNumberOfWheels(vehicle)..", ")
    Citizen.Trace("type : ")
    if GetVehicleWheelType(vehicle)==0 then Citizen.Trace("Sport, ") end
    if GetVehicleWheelType(vehicle)==1 then Citizen.Trace("Muscle, ") end
    if GetVehicleWheelType(vehicle)==2 then Citizen.Trace("Lowrider, ") end
    if GetVehicleWheelType(vehicle)==3 then Citizen.Trace("SUV, ") end
    if GetVehicleWheelType(vehicle)==4 then Citizen.Trace("Offroad, ") end
    if GetVehicleWheelType(vehicle)==5 then Citizen.Trace("Tuner, ") end
    if GetVehicleWheelType(vehicle)==6 then Citizen.Trace("Bike, ") end
    if GetVehicleWheelType(vehicle)==7 then Citizen.Trace("Hi end, ") end
    if GetVehicleWheelType(vehicle)==8 then Citizen.Trace("Super : Benny's original, ") end
    if GetVehicleWheelType(vehicle)==9 then Citizen.Trace("Super : Benny's bespoke, ") end
    if GetVehicleWheelType(vehicle)==10 then Citizen.Trace("Super : Open wheel, ") end
    if GetVehicleWheelType(vehicle)==11 then Citizen.Trace("Super : Street, ") end
    if GetVehicleWheelType(vehicle)==12 then Citizen.Trace("Super : Track, ") end
    Citizen.Trace("size : "..GetVehicleWheelSize(vehicle)..", ")
    Citizen.Trace("Collider Size : "..GetVehicleWheelRimColliderSize(vehicle)..", ")
    Citizen.Trace("Retractable : "..tostring(GetHasRetractableWheels(vehicle))..", ")
    Citizen.Trace("\n")
    printwheel(vehicle, 0)
    printwheel(vehicle, 1)
    printwheel(vehicle, 2)
    printwheel(vehicle, 3)
    printwheel(vehicle, 4)
    printwheel(vehicle, 5)
    printwheel(vehicle, 45)
    printwheel(vehicle, 47)
end,true)
