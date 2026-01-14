Config = {}

Config.Locale = 'sv'

Config.Debug = true -- set to false to remove the red markers

Config.NotificationPosition = 'top-right'

Config.Boss = {
    coords = vec4(584.0250, 138.2623, 99.4748, 161.5417),
    model = 'a_f_m_tourist_01'
}

Config.GraffitiSpots = {
    { coords = vec4(-18.0516, -1443.4097, 30.6364, 5.6144), radius = 1.5 },
    { coords = vec4(-20.1711, -1435.5317, 30.6566, 268.0368), radius = 1.5 },
    { coords = vec4(-11.6263, -1426.3762, 30.6727, 182.6944), radius = 1.5 }
}

Config.OwnerPed = {
    coords = vec4(-14.2115, -1442.5901, 31.0998, 181.4803),
    model = 'ig_ramp_gang',
    weapon = 'WEAPON_BAT'
}

Config.TargetVehicle = {
    coords = vec4(-24.7297, -1439.6055, 30.2731, 180.5746),
    model = nil,
    spawnIfMissing = true
}

Config.Reward = {
    moneyType = 'cash',
    amount = 500
}

Config.Graffiti = {
    duration = 5000,
    animDict = 'anim@scripted@freemode@postertag@graffiti_spray@male@',
    animName = 'shake_can_male',
    propModel = 'prop_cs_spray_can',
    propBone = 28422,
    propPos = vec3(0.0, 0.0, 0.07),
    propRot = vec3(0.001736, 0.0, 0.0)
}

Config.Locales = {}

Config.Locales = {}

function L(key, ...)
    local lang = Config.Locale or 'sv'
    local locale = Config.Locales[lang] or {}
    local str = locale[key] or ('[' .. key .. ']')

    if ... and select('#', ...) > 0 then
        return str:format(...)
    end

    return str
end
