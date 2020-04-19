local M = {}

local const = require('scenes.game_constants')
local utils = require("libs.utils")

local hasCollidedSquareAndRect = utils.hasCollidedSquareAndRect

local w = 256
local h = 32

local options = {
    width = w,
    height = h,
    numFrames = 5,
}
local techsImageSheet = graphics.newImageSheet("data/panels.png", options)

local techs = {}

function M.newTech(parent, techType, collidable)
    local tech = display.newRect(0, 0, w, h)
    tech.fill = { type = "image", sheet = techsImageSheet, frame = techType }
    tech.anchorX = 0.5
    tech.anchorY = 0.5
    tech.techType = techType
    parent:insert(tech)

    if collidable then
        techs[#techs + 1] = tech
    end

    return tech
end

function M.findCollision(req, ignore)
    for _, tech in next, techs do
        if tech == ignore then
        elseif hasCollidedSquareAndRect(req, tech) then
            return tech
        end
    end
    return nil
end

function M.getMinTargetY(tech)
    local x1, x2, y = tech.x, tech.x + tech.width, tech.y

    local maxY = const.TopPanelHeight + h / 2 + 50

    for _, otherTech in next, techs do
        if otherTech == tech then
            -- Это мы же
        elseif otherTech.y > y then
            -- Ниже
        elseif otherTech.x > x2 then
            -- Правее
        elseif otherTech.x + otherTech.width < x1 then
            -- Левее
        else
            maxY = math.max(maxY, otherTech.y + h * 1.5)
        end
    end

    return maxY
end

function M.moveToTargetPositions(_, deltaTime)
    for _, tech in next, techs do
        if tech.speedY ~= 0 then
            local minY = M.getMinTargetY(tech)

            tech.y = tech.y + tech.speedY * deltaTime
            if tech.y <= minY then
                tech.y = minY
                tech.speedY = 0
            end
        end
    end
end

return M
