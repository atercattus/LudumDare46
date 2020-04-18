local mathSqrt = math.sqrt
local mathDeg = math.deg
local mathRad = math.rad
local mathAtan = math.atan
local mathSin = math.sin
local mathCos = math.cos
local mathRound = math.round
local tonumber = tonumber
local stringFormat = string.format
local pairs = pairs
local systemGetTimer = system.getTimer

local M = {}

function M.sqr(v)
    return v * v
end

function M.sign(v)
    return v < 0 and -1 or 1
end

function M.vector(fromX, fromY, toX, toY)
    return { x = toX - fromX, y = toY - fromY }
end

function M.vectorToAngle(vec)
    if vec.y == 0 then
        return 0
    end

    local angle = mathDeg(mathAtan(vec.x / vec.y))
    if vec.y < 0 then
        angle = angle + 180
    elseif vec.x < 0 then
        angle = angle + 360
    end

    return angle
end

function M.vectorLen(vec)
    return mathSqrt(vec.x * vec.x + vec.y * vec.y)
end

function M.distanceBetween(obj1, obj2)
    local dX = obj1.x - obj2.x
    local dY = obj1.y - obj2.y

    return mathSqrt(dX * dX + dY * dY)
end

function M.hasCollidedCircle(obj1, obj2)
    local minimalDistance = (obj2.contentWidth / 2) + (obj1.contentWidth / 2)
    return M.distanceBetween(obj1, obj2) < minimalDistance
end

function M.hasCollidedSquareAndRect(squareObj, rectObj)
    -- Не учитывает scale объектов

    local cS = squareObj.width
    local cX = squareObj.x - cS * squareObj.anchorX
    local cY = squareObj.y - cS * squareObj.anchorY

    local x, y, w, h = rectObj.x, rectObj.y, rectObj.width, rectObj.height
    local dx, dy = rectObj.width * rectObj.anchorX, rectObj.height * rectObj.anchorY

    local rX1, rY1, rX2, rY2 = x - dx, y - dy, x + w - dx, y + h - dy

    -- Выше или ниже
    if (cY + cS < rY1) or (cY > rY2) then
        return false
    end

    -- Левее или правее
    if (cX + cS < rX1) or (cX > rX2) then
        return false
    end

    return true
end

function M.sinCos(angleDeg)
    if M.sinCosDegTable == nil then
        M.sinCosDegTable = {}
        for angle = 0, 359 do
            local rad = mathRad(angle)
            M.sinCosDegTable[angle] = { mathSin(rad), mathCos(rad) }
        end
    end

    angleDeg = mathRound(angleDeg)

    if angleDeg < 0 then
        angleDeg = 360 - ((-angleDeg) % 360)
    end

    if angleDeg >= 360 then
        angleDeg = angleDeg % 360
    end

    -- ToDo: возвращается не копия. так что было бы неплохо защищить от изменения через __newindex
    return M.sinCosDegTable[angleDeg]
end

function M.copyPlain(src)
    local dst = {}
    for k, v in pairs(src) do
        dst[k] = v
    end
    return dst
end

function M.round(num, numDecimalPlaces)
    return tonumber(stringFormat("%." .. (numDecimalPlaces or 0) .. "f", num))
end

function M.getDeltaTime(now)
    if (not M._lastEnterFrameTime) or (M._lastEnterFrameTime == 0) then
        M._lastEnterFrameTime = systemGetTimer()
        return 0
    end
    local deltaTime = (now - M._lastEnterFrameTime) / 1000
    M._lastEnterFrameTime = now
    if deltaTime <= 0 then
        return 0
    end
    return deltaTime
end

return M
