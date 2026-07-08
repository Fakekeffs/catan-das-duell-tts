local productionDieGuid = "5c2f94"

local resourceFieldGuids = {}

local multiplierCards = {
    {
        guid = "8f4c3d",
        resource = "Weizen",
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
            handleProductionRoll(object.getValue())
        end,
        function()
            return object.resting
        end
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
        local multiplierObject = getObjectFromGUID(multiplierConfig.guid)

        if multiplierObject ~= nil then
            if multiplierConfig.resource == params.resource then
                local distance = getHorizontalDistance(fieldPosition, multiplierObject.getPosition())

                if distance <= multiplierConfig.range then
                    bestMultiplier = math.max(bestMultiplier, multiplierConfig.multiplier)
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
        local multiplierObject = getObjectFromGUID(multiplierConfig.guid)

        if multiplierObject == nil then
            print("Doppler nicht gefunden: " .. multiplierConfig.guid)
        else
            local distance = getHorizontalDistance(fieldPosition, multiplierObject.getPosition())
            local resourceMatches = multiplierConfig.resource == params.resource
            local inRange = distance <= multiplierConfig.range

            print("Doppler " .. multiplierConfig.guid)
            print("Ressource Doppler: " .. tostring(multiplierConfig.resource))
            print("Ressource passt: " .. tostring(resourceMatches))
            print("Distanz: " .. tostring(distance))
            print("Range: " .. tostring(multiplierConfig.range))
            print("In Range: " .. tostring(inRange))
        end
    end
end

function getHorizontalDistance(a, b)
    local dx = a.x - b.x
    local dz = a.z - b.z

    return math.sqrt(dx * dx + dz * dz)
end