local playerMissionState = {}

local function setMissionState(src, state)
    playerMissionState[src] = state
end

local function getMissionState(src)
    return playerMissionState[src]
end

AddEventHandler('playerDropped', function()
    local src = source
    playerMissionState[src] = nil
end)

lib.callback.register('hampus-vandalism:server:canStart', function(src)
    if getMissionState(src) then
        return false, L('mission_already_active')
    end

    setMissionState(src, 'started')
    return true
end)

RegisterNetEvent('hampus-vandalism:server:setState', function(state)
    local src = source
    if state == 'completed' or state == 'started' or state == nil then
        setMissionState(src, state)
    end
end)

RegisterNetEvent('hampus-vandalism:server:missionCompleted', function()
    local src = source
    local state = getMissionState(src)

    if state ~= 'completed' then
        return
    end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    player.Functions.AddMoney(Config.Reward.moneyType, Config.Reward.amount)

    -- Notification for rewards
    TriggerClientEvent('ox_lib:notify', src, {
        title = "Reward Received",
        description = "Reward Received",
        type = 'success'
    })

    setMissionState(src, nil)
end)
