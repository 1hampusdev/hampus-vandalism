local missionActive = false
local graffitiIndex = 0
local ownerPed = nil
local missionVehicle = nil
local carDestroyed = false
local drawCarText = false
local carDamagePercent = 0
local missionBlip = nil
local OWNER_REL_GROUP = 'OWNER_ENEMY'

local function loadModel(model)
    local hash = type(model) == 'string' and joaat(model) or model
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end
    return hash
end

local function loadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
end


local function showInstruction(text, type)
    lib.notify({
        title = L('mission_instructions_title'),
        description = text,
        type = type or 'info',
        position = Config.NotificationPosition
    })
end

local function drawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
        local factor = (string.len(text)) / 200
        DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 68)
    end
end

local function spawnBoss()
    local bossHash = loadModel(Config.Boss.model)
    local c = Config.Boss.coords

    local ped = CreatePed(4, bossHash, c.x, c.y, c.z - 1.0, c.w, false, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'hampus-vandalism_boss',
            icon = 'fa-solid fa-user',
            label = L('boss_target'),
            onSelect = function()

                if missionActive then
                    if graffitiIndex >= #Config.GraffitiSpots and carDestroyed then
                        TriggerServerEvent('hampus-vandalism:server:setState', 'completed')
                        TriggerServerEvent('hampus-vandalism:server:missionCompleted')
                        missionActive = false
                        graffitiIndex = 0
                        ownerPed = nil
                        missionVehicle = nil
                        carDestroyed = false
                        drawCarText = false
                    else
                        showInstruction(L('mission_already_active'), 'error')
                    end
                    return
                end

                local alert = lib.alertDialog({
                    header = L('dialog_title'),
                    content = L('dialog_question'),
                    centered = true,
                    cancel = true,
                    labels = {
                        confirm = L('dialog_yes'),
                        cancel = L('dialog_no')
                    }
                })

                if alert == 'confirm' then
                    lib.callback('hampus-vandalism:server:canStart', false, function(canStart, msg)
                        if not canStart then
                            showInstruction(msg or L('mission_already_active'), 'error')
                            return
                        end

                        missionActive = true
                        graffitiIndex = 0
                        carDestroyed = false
                        drawCarText = false

                        local first = Config.GraffitiSpots[1].coords
                        SetNewWaypoint(first.x, first.y)

                        if missionBlip then RemoveBlip(missionBlip) end
                        missionBlip = AddBlipForCoord(first.x, first.y, first.z)
                        SetBlipSprite(missionBlip, 280)
                        SetBlipScale(missionBlip, 0.9)
                        SetBlipColour(missionBlip, 1)
                        BeginTextCommandSetBlipName("STRING")
                        AddTextComponentString("Klotterplats")
                        EndTextCommandSetBlipName(missionBlip)

                        showInstruction(L('mission_start_notify'), 'info')
                        showInstruction(L('mission_step_graffiti'), 'info')
                    end)
                else
                    lib.notify({
                        description = L('dialog_no_notify'),
                        type = 'error',
                        position = Config.NotificationPosition
                    })
                end
            end
        }
    })
end

CreateThread(spawnBoss)

local function doGraffitiSpot(i)
    local spot = Config.GraffitiSpots[i]
    if not spot or not missionActive then return end

    local ped = PlayerPedId()
    TaskTurnPedToFaceCoord(ped, spot.coords.x, spot.coords.y, spot.coords.z, 1000)
    Wait(1000)

    loadAnimDict(Config.Graffiti.animDict)

    local propHash = loadModel(Config.Graffiti.propModel)
    local x, y, z = table.unpack(GetEntityCoords(ped))
    local prop = CreateObject(propHash, x, y, z + 0.2, true, true, true)

    AttachEntityToEntity(
        prop, ped, GetPedBoneIndex(ped, Config.Graffiti.propBone),
        Config.Graffiti.propPos.x, Config.Graffiti.propPos.y, Config.Graffiti.propPos.z,
        Config.Graffiti.propRot.x, Config.Graffiti.propRot.y, Config.Graffiti.propRot.z,
        true, true, false, true, 1, true
    )

    TaskPlayAnim(ped, Config.Graffiti.animDict, Config.Graffiti.animName, 4.0, -4.0, Config.Graffiti.duration, 49, 0, false, false, false)

    local success = lib.progressCircle({
        duration = Config.Graffiti.duration,
        label = L('graffiti_progress'),
        disable = { move = true, car = true, combat = true }
    })

    ClearPedTasks(ped)
    if prop then DeleteEntity(prop) end
    if not success then return end

    graffitiIndex += 1
    showInstruction(L('graffiti_done_step', tostring(graffitiIndex)), 'success')

    if graffitiIndex >= #Config.GraffitiSpots then
        if missionBlip then RemoveBlip(missionBlip) missionBlip = nil end

        showInstruction(L('all_graffiti_done'), 'info')
        showInstruction(L('mission_step_kill_owner'), 'info')

        if not DoesRelationshipGroupExist(OWNER_REL_GROUP) then
            AddRelationshipGroup(OWNER_REL_GROUP)
            SetRelationshipBetweenGroups(5, OWNER_REL_GROUP, `PLAYER`)
            SetRelationshipBetweenGroups(5, `PLAYER`, OWNER_REL_GROUP)
        end

        local ownerHash = loadModel("ig_ramp_gang")
        local o = Config.OwnerPed.coords

        ownerPed = CreatePed(4, ownerHash, o.x, o.y, o.z + 0.3, o.w, true, true)
        SetEntityAsMissionEntity(ownerPed, true, true)
        FreezeEntityPosition(ownerPed, false)

        ClearPedTasksImmediately(ownerPed)
        ClearPedSecondaryTask(ownerPed)

        SetPedRelationshipGroupHash(ownerPed, OWNER_REL_GROUP)
        GiveWeaponToPed(ownerPed, joaat(Config.OwnerPed.weapon), 999, false, true)

        SetBlockingOfNonTemporaryEvents(ownerPed, false)
        SetPedFleeAttributes(ownerPed, 0, false)
        SetPedCombatAttributes(ownerPed, 46, true)
        SetPedCombatAttributes(ownerPed, 5, true)
        SetPedCombatMovement(ownerPed, 3)
        SetPedCombatRange(ownerPed, 2)
        SetPedAlertness(ownerPed, 3)
        SetPedAccuracy(ownerPed, 100)

        TaskCombatPed(ownerPed, ped, 0, 16)

        lib.notify({
            description = L('owner_attacks'),
            type = 'warning',
            position = Config.NotificationPosition
        })
    end
end

CreateThread(function()
    for i, spot in ipairs(Config.GraffitiSpots) do
        exports.ox_target:addSphereZone({
            coords = vector3(spot.coords.x, spot.coords.y, spot.coords.z),
            radius = spot.radius or 1.5,
            options = {
                {
                    name = 'hampus-vandalism_graffiti_' .. i,
                    icon = 'fa-solid fa-spray-can',
                    label = L('graffiti_progress'),
                    canInteract = function()
                        return missionActive and graffitiIndex + 1 == i
                    end,
                    onSelect = function()
                        doGraffitiSpot(i)
                    end
                }
            }
        })
    end
end)

CreateThread(function()
    while true do
        Wait(500)

        if missionActive and ownerPed and DoesEntityExist(ownerPed) then
            if IsPedDeadOrDying(ownerPed, true) then
                local tv = Config.TargetVehicle

                local veh = GetClosestVehicle(tv.coords.x, tv.coords.y, tv.coords.z, 5.0, 0, 70)

                if veh ~= 0 then
                    missionVehicle = veh
                elseif tv.spawnIfMissing then
                    local modelName = tv.model or "buffalo2"
                    local modelHash = loadModel(modelName)
                    missionVehicle = CreateVehicle(modelHash, tv.coords.x, tv.coords.y, tv.coords.z, tv.coords.w, true, true)
                    if missionVehicle ~= 0 then
                        SetVehicleOnGroundProperly(missionVehicle)
                        SetEntityAsMissionEntity(missionVehicle, true, true)
                    end
                end

                if missionVehicle and DoesEntityExist(missionVehicle) then
                    drawCarText = true
                    showInstruction(L('mission_step_destroy_car'), 'info')
                else
                    showInstruction('Kunde inte hitta eller spawna bilen, kolla Config.TargetVehicle.', 'error')
                end

                ownerPed = nil
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)

        if drawCarText and missionVehicle and DoesEntityExist(missionVehicle) then
            local engine = GetVehicleEngineHealth(missionVehicle)
            local body = GetVehicleBodyHealth(missionVehicle)

            engine = math.max(0, math.min(engine, 1000))
            body = math.max(0, math.min(body, 1000))

            local damage = math.floor(((1000 - math.min(engine, body)) / 10))
            carDamagePercent = damage

            local coords = GetEntityCoords(missionVehicle)
            drawText3D(coords.x, coords.y, coords.z + 1.0, L('car_instruction', damage))

            if damage >= 100 then
    carDestroyed = true
    drawCarText = false

    showInstruction(L('car_done'), 'success')
    showInstruction(L('mission_step_return_boss'), 'info')

    local boss = Config.Boss.coords

            if missionBlip then
                RemoveBlip(missionBlip)
                missionBlip = nil
            end

            SetNewWaypoint(boss.x, boss.y)

            missionBlip = AddBlipForCoord(boss.x, boss.y, boss.z)
            SetBlipSprite(missionBlip, 280)
            SetBlipScale(missionBlip, 0.9)
            SetBlipColour(missionBlip, 2)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Karin")
            EndTextCommandSetBlipName(missionBlip)

            TriggerServerEvent('hampus-vandalism:server:setState', 'completed')
        end

        else
            Wait(500)
        end
    end
end)


CreateThread(function()
    while true do
        Wait(1000)

        if missionActive and ownerPed and DoesEntityExist(ownerPed) and not IsPedDeadOrDying(ownerPed, true) then
            local player = PlayerPedId()

            if not IsPedInCombat(ownerPed, player) then
                ClearPedTasks(ownerPed)
                TaskCombatPed(ownerPed, player, 0, 16)
            end
        end
    end
end)


CreateThread(function()
    while true do
        if Config.Debug then
            for _, spot in ipairs(Config.GraffitiSpots) do
                DrawMarker(
                    1,
                    spot.coords.x, spot.coords.y, spot.coords.z - 1.0,
                    0,0,0, 0,0,0,
                    1.5,1.5,1.0,
                    255,0,0,150,
                    false,false,2,false
                )
            end
            Wait(0)
        else
            Wait(1000)
        end
    end
end)
