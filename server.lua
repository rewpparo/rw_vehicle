----------------------
-- Helper functions --
----------------------

function HasWritePermission(source)
    if IsPlayerAceAllowed(source, 'command.rw_vehicle.write') then return true end

    if not Config.RegistrationWrite then return false end
    if type(Config.RegistrationWrite)~='table' then return false end
    xPlayer = ESX.GetPlayerFromId(source)
    for k,v in ipairs(Config.RegistrationWrite) do
        if k==xPlayer.getJob().name and v>=xPlayer.getJob().grade then return true end
    end

    return false
end

function HasReadPermission(source)
    if IsPlayerAceAllowed(source, 'command.rw_vehicle.read') then return true end

    if not Config.RegistrationRead then return false end
    if type(Config.RegistrationRead)~='table' then return false end
    xPlayer = ESX.GetPlayerFromId(source)
    for k,v in ipairs(Config.RegistrationRead) do
        if k==xPlayer.getJob().name and v>=xPlayer.getJob().grade then return true end
    end
    
    return false
end

----------------
-- RUN PLATES --
----------------

--Command to get a notification with the plate run
RegisterCommand('RunPlate', function(source, args, rawCommand)
    if not HasReadPermission(source) then return end
    if #args<1 then 
        Citizen.Trace("Usage : RunPlate Plate\n")
        return
    end
    lsource = source
    RunPlateNotification(source, RunPlate(source, args[1]), args[1])
end,true)

--Event to send a notification to the caller with the plate run
RegisterNetEvent('rw_vehicle:RunPlate', function(plate)
    if not HasReadPermission(source) then return end
    local source = source
    RunPlateNotification(source, RunPlate(source), plate)
end)

--A callback that allows clients to get a run object. Optionally sends a notification (defaults true)
ESX.RegisterServerCallback('rw_vehicle:RunPlateCb', function(source, cb, plate, notification)
    if not HasReadPermission(source) then return nil end
    r = RunPlate(source, plate)
    if notification==nil then notification = true end
    if notification then
        RunPlateNotification(source, r)
    end
    cb(r)
end)

--Send a notification to client with a plate run
function RunPlateNotification(source, runresult)
    ownerstring = ""
    --Job vehicle ?
    if runresult.valid and runresult.job~="" then ownerstring = ownerstring.."Company : "..runresult.job.."\n" end
    --owner
    if runresult.valid then
        ownerstring = ownerstring.."Owner : "..runresult.lastname.." "..runresult.firstname.."\nDoB : "..runresult.dob
    end
    if not runresult.valid then ownerstring = "Plate not found" end

    local caller = ESX.GetPlayerFromId(source)
    caller.showAdvancedNotification("Running plate", runresult.plate, ownerstring, 'CHAR_ACTING_UP', 2)
end

--The actual plate running
function RunPlate(source, plate)
    local r = {
        plate = plate,
        valid = false,
        model = "###",
        id = "###",
        firstname = "###",
        lastname = "###",
        dob = "###",
        job = "###",
    }

    if not plate then return r end
    if not HasReadPermission(source) then return r end
    local carresult = MySQL.query.await('SELECT * FROM owned_vehicles WHERE plate = ?', { plate })
    if carresult and #carresult>0 then
        r.valid = true
        r.id = carresult[1].owner
        r.job = carresult[1].job
        local props = json.decode(carresult[1].vehicle)
        r.model = props.model
        --Owner info
        if r.id==nil then
            r.firstname = ""
            r.lastname = ""
            r.dob = ""
        else
            local ownerresult = MySQL.query.await('SELECT * FROM users WHERE identifier = ?', { r.id })
            if ownerresult and #ownerresult>0 then
                r.firstname = ownerresult[1].firstname
                r.lastname = ownerresult[1].lastname
                r.dob = ownerresult[1].dateofbirth
            end
        end
    end
    return r
end

-------------------------
-- REGISTRATION CHANGE --
-------------------------

--Only works on already owned vehicles
RegisterNetEvent('rw_vehicle:SetOwner', function(vehicleplate, newowneridentifier)
    local source = source
    if not source or source=="" then --If this is called with no source, then it's called by server and server scripts should give me a source
        source = lsource
        lsource = nil
    end

    if not HasWritePermission(source) then 
        caller.showAdvancedNotification("Vehicle Transfer", vehicleplate, "You're not allowed to do that", 'CHAR_BLOCKED', 2)
        return 
    end

    local caller = ESX.GetPlayerFromId(source)
    --It it a request to clear owner ?
    if newowneridentifier==nil then
        MySQL.update('UPDATE owned_vehicles SET owner = ? WHERE plate = ?', { nil, vehicleplate }, function(affectedRows)
            --Did the transfer work ?
            if affectedRows==1 then
                caller.showAdvancedNotification("Vehicle Transfer", vehicleplate, "Owner was cleared", 'CHAR_ACTING_UP', 2)
            elseif affectedrows<1 then
                caller.showAdvancedNotification("Vehicle Transfer", vehicleplate, "Vehicle not found", 'CHAR_BLOCKED', 2)
            elseif affectedrows>1 then
                caller.showAdvancedNotification("Vehicle Transfer", vehicleplate, "Duplicate plate", 'CHAR_BLOCKED', 2) 
            end
        end)
        return
    end
    --Is the identifier a valid user ?
    local ownerresult = MySQL.query.await('SELECT * FROM users WHERE identifier = ?', { newowneridentifier })
    if ownerresult and #ownerresult>0 then
        --Do the transfer
        local transferstring = "Transfered to "..ownerresult[1].firstname.." "..ownerresult[1].lastname.."\n"
        MySQL.update('UPDATE owned_vehicles SET owner = ? WHERE plate = ?', { newowneridentifier, vehicleplate }, function(affectedRows)
            --Did the transfer work ?
            if affectedRows==1 then
                caller.showAdvancedNotification("Vehicle Transfer", vehicleplate, transferstring, 'CHAR_ACTING_UP', 2)
            elseif affectedrows<1 then
                caller.showAdvancedNotification("Vehicle Transfer", vehicleplate, "Vehicle not found", 'CHAR_BLOCKED', 2)
            elseif affectedrows>1 then
                caller.showAdvancedNotification("Vehicle Transfer", vehicleplate, "Duplicate plate", 'CHAR_BLOCKED', 2) 
            end
        end)
    else 
        caller.showAdvancedNotification("Vehicle Transfer", vehicleplate, "New owner is incorrect", 'CHAR_BLOCKED', 2) 
    end
end)

--A callback to get a list of jobs available for registration
ESX.RegisterServerCallback('rw_vehicle:ListJobs', function(source, cb)
    r = {}
    if not HasWritePermission(source) then return r end
    local jobs = ESX.GetJobs()
    for k,v in pairs(jobs) do
        r[k] = v.label
    end
    cb(r)
end)

--Vehicle job change. newjob = nil means set to no job, owner needs to be valid then.
RegisterNetEvent('rw_vehicle:SetJob', function(vehicleplate, newjob)
    local source = source
    if not HasWritePermission(source) then return end

    local caller = ESX.GetPlayerFromId(source)
    --Clear job ?
    if newjob==nil then
        MySQL.update('UPDATE owned_vehicles SET job = ? WHERE plate = ?', { nil, vehicleplate }, function(affectedRows)
            --Did the transfer work ?
            if affectedRows==1 then
                caller.showAdvancedNotification("Vehicle Job", vehicleplate, "Job cleared", 'CHAR_ACTING_UP', 2)
            elseif affectedrows<1 then
                caller.showAdvancedNotification("Vehicle Job", vehicleplate, "Vehicle not found", 'CHAR_BLOCKED', 2)
            elseif affectedrows>1 then
                caller.showAdvancedNotification("Vehicle Job", vehicleplate, "Duplicate plate", 'CHAR_BLOCKED', 2) 
            end
        end)
    end

    --Is the job valid ?
    local jobresult = MySQL.query.await('SELECT * FROM jobs WHERE name = ?', { newjob })
    if jobresult and #jobresult>0 then
        --Do the transfer
        local transferstring = "Transfered to job "..jobresult[1].label.."\n"
        MySQL.update('UPDATE owned_vehicles SET job = ? WHERE plate = ?', { newjob, vehicleplate }, function(affectedRows)
            --Did the transfer work ?
            if affectedRows==1 then
                caller.showAdvancedNotification("Vehicle Job", vehicleplate, transferstring, 'CHAR_ACTING_UP', 2)
            elseif affectedrows<1 then
                caller.showAdvancedNotification("Vehicle Job", vehicleplate, "Vehicle not found", 'CHAR_BLOCKED', 2)
            elseif affectedrows>1 then
                caller.showAdvancedNotification("Vehicle Job", vehicleplate, "Duplicate plate", 'CHAR_BLOCKED', 2) 
            end
        end)
    end
end)
