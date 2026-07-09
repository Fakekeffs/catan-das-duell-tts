local productionDieGuid = "5c2f94"

local resourceFieldGuids = {}
local productionRollInProgress = false

local multiplierCards = {
    {
        name = "Getreidemühle",
        resource = "Weizen",
        multiplier = 2,
        range = 5.0
    },
    {
        name = "Webstube",
        resource = "Schaf",
        multiplier = 2,
        range = 5.0
    },
    {
        name = "Ziegelbrennerei",
        resource = "Lehm",
        multiplier = 2,
        range = 5.0
    },
    {
        name = "Holzfällerlager",
        resource = "Holz",
        multiplier = 2,
        range = 5.0
    },
    {
        name = "Eisenschmelze",
        resource = "Stein",
        multiplier = 2,
        range = 5.0
    }
}

function registerResourceField(params)
    resourceFieldGuids[params.guid] = true
end

function onObjectRandomize(object, playerColor)
    if object.getGUID() ~= productionDieGuid then
        return
    end

    Wait.condition(
        function()
            handleProductionRollOnce(object.getValue())
        end,
        function()
            return object.resting
        end
    )
end

function handleProductionRollOnce(roll)
    if productionRollInProgress then
        print("Ertragswurf ignoriert, Verarbeitung läuft bereits")
        return
    end

    productionRollInProgress = true
    handleProductionRoll(roll)

    Wait.time(
        function()
            productionRollInProgress = false
        end,
        0.5
    )
end

function handleProductionRoll(roll)
    print("🎲 Ertragswürfel: " .. tostring(roll))

    for guid, _ in pairs(resourceFieldGuids) do
        local field = getObjectFromGUID(guid)

        if field ~= nil then
            field.call("produce", { roll = roll })
        end
    end
end

function getAdjacentProductionMultiplier(params)
    local field = getObjectFromGUID(params.fieldGuid)

    if field == nil then
        return 1
    end

    local fieldPosition = field.getPosition()
    local bestMultiplier = 1

    for _, multiplierConfig in ipairs(multiplierCards) do
        if multiplierConfig.resource == params.resource then
            for _, multiplierObject in ipairs(getAllObjects()) do
                if multiplierObject ~= field and isExpectedMultiplierObject(multiplierObject, multiplierConfig) then
                    local distance = getHorizontalDistance(fieldPosition, multiplierObject.getPosition())

                    if distance <= multiplierConfig.range then
                        bestMultiplier = math.max(bestMultiplier, multiplierConfig.multiplier)
                    end
                end
            end
        end
    end

    return bestMultiplier
end

function debugMultipliers(params)
    local field = getObjectFromGUID(params.fieldGuid)

    if field == nil then
        print("Debug Doppler: Feld nicht gefunden")
        return
    end

    local fieldPosition = field.getPosition()

    print("Debug Doppler für Feld: " .. field.getGUID())
    print("Gesuchte Ressource: " .. tostring(params.resource))

    for _, multiplierConfig in ipairs(multiplierCards) do
        local foundAny = false

        for _, multiplierObject in ipairs(getAllObjects()) do
            if multiplierObject ~= field and isExpectedMultiplierObject(multiplierObject, multiplierConfig) then
                foundAny = true

                local distance = getHorizontalDistance(fieldPosition, multiplierObject.getPosition())
                local resourceMatches = multiplierConfig.resource == params.resource
                local inRange = distance <= multiplierConfig.range

                print("Doppler " .. multiplierObject.getGUID() .. " (" .. multiplierConfig.name .. ")")
                print("Ressource Doppler: " .. tostring(multiplierConfig.resource))
                print("Ressource passt: " .. tostring(resourceMatches))
                print("Distanz: " .. tostring(distance))
                print("Range: " .. tostring(multiplierConfig.range))
                print("In Range: " .. tostring(inRange))
            end
        end

        if not foundAny then
            print("Doppler nicht gefunden: " .. tostring(multiplierConfig.name))
        end
    end
end

function getHorizontalDistance(a, b)
    local dx = a.x - b.x
    local dz = a.z - b.z

    return math.sqrt(dx * dx + dz * dz)
end

function isExpectedMultiplierObject(object, multiplierConfig)
    local name = object.getName()

    return name == multiplierConfig.name
end