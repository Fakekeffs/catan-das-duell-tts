local config = {
    production = 6,
    resource = "Weizen",
    owner = "rot",
    maxValue = 3
}

local baseY = nil

function onLoad()
    self.setName("Weizenfeld 6")
    self.addContextMenuItem("+1 Ressource", addResource)
    self.addContextMenuItem("-1 Ressource", removeResource)
    self.addContextMenuItem("Setze aktuelle Rotation als 1", setCurrentRotationAsOne)
    self.addContextMenuItem("Debug Status", debugStatus)
    self.addContextMenuItem("Debug Doppler", debugDoppler)

    baseY = normalizeAngle(self.getRotation().y)

    Global.call("registerResourceField", {
        guid = self.getGUID()
    })
end

function produce(params)
    if params.roll ~= config.production then
        return
    end

    addResource()
end

function addResource(playerColor)
    local current = getResourceCountFromRotation()

    if current >= config.maxValue then
        return false
    end

    local amount = getProductionAmount()
    local nextValue = math.min(current + amount, config.maxValue)

    setResourceCount(nextValue)

    return true
end

function getProductionAmount()
    return Global.call("getAdjacentProductionMultiplier", {
        fieldGuid = self.getGUID(),
        resource = config.resource
    })
end

function removeResource(playerColor)
    local current = getResourceCountFromRotation()

    if current <= 0 then
        return false
    end

    local nextValue = current - 1
    setResourceCount(nextValue)

    return true
end

function setResourceCount(value)
    local rotation = self.getRotation()
    local stepsFromOne = value - 1

    if value == 0 then
        stepsFromOne = 3
    end

    rotation.y = normalizeAngle(baseY - stepsFromOne * 90)
    self.setRotation(rotation)
end

function getResourceCountFromRotation()
    local currentY = normalizeAngle(self.getRotation().y)
    local diff = normalizeAngle(baseY - currentY)
    local steps = math.floor((diff + 45) / 90) % 4

    if steps == 0 then
        return 1
    end

    if steps == 1 then
        return 2
    end

    if steps == 2 then
        return 3
    end

    return 0
end

function setCurrentRotationAsOne(playerColor)
    baseY = normalizeAngle(self.getRotation().y)
    print(self.getName() .. ": aktuelle Rotation ist jetzt 1 Ressource")
end

function debugStatus(playerColor)
    local rotation = self.getRotation()
    local current = getResourceCountFromRotation()
    local amount = getProductionAmount()

    print(self.getName() .. ": Besitzer=" .. tostring(config.owner))
    print("Ressource=" .. tostring(config.resource) .. " Produktion=" .. tostring(config.production))
    print("Ressourcen laut Rotation=" .. tostring(current))
    print("Produktionsmenge aktuell=" .. tostring(amount))
    print("baseY=" .. tostring(baseY))
    print("Rotation: x=" .. rotation.x .. " y=" .. rotation.y .. " z=" .. rotation.z)
end

function debugDoppler(playerColor)
    Global.call("debugMultipliers", {
        fieldGuid = self.getGUID(),
        resource = config.resource
    })
end

function normalizeAngle(angle)
    angle = angle % 360

    if angle < 0 then
        angle = angle + 360
    end

    return angle
end
