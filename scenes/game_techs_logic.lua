local M = {}

local const = require('scenes.game_constants')
local utils = require("libs.utils")

local hasCollidedSquareAndRect = utils.hasCollidedSquareAndRect

local w = 256
local h = 36

local options = {
    width = w,
    height = h,
    numFrames = 5,
}
local techsImageSheet = graphics.newImageSheet("data/panels.png", options)

local techs = {}

function M.newTech(parent, techType, active, removeCb)
    local tech = display.newRect(0, 0, w, h)
    tech.fill = { type = "image", sheet = techsImageSheet, frame = techType }
    tech.anchorX = 0.5
    tech.anchorY = 0.5
    tech.techType = techType
    tech.techDurability = const.TechDurabilities[techType]
    parent:insert(tech)

    local txt = display.newText({ text = '', fontSize = 20, align = 'center' })
    tech.anchorX = 0.5
    tech.anchorY = 0.5
    tech.txt = txt
    parent:insert(txt)

    if active then
        tech.removeCb = removeCb
        techs[#techs + 1] = tech
    end

    return tech
end

function M.markAllUncollided()
    for _, tech in next, techs do
        tech.txt.x = tech.x
        tech.txt.y = tech.y

        -- Для закупки рекламы дополнительно вывожу множитель закупки
        local txt = ''
        if tech.qpsScale ~= nil then
            txt = 'x' .. tech.qpsScale .. ' '
        end
        tech.txt.text = txt .. ' ' .. math.floor(tech.techDurability)

        tech.isCollided = false
        tech.rotation = 0
    end
end

function M.processCollided()
    for _, tech in next, techs do
        if tech.isCollided then
            tech.rotation = math.random(10) - 5
        end
    end
end

function M.processBuyAds(deltaTime)
    local toDelete = {}

    local cnt = 1 * deltaTime -- Показывает оставшееся время

    for i, tech in next, techs do
        if tech.techType == const.TechBuyAds then
            -- Покупка рекламы всегда в фоне приносит деньги
            tech.isCollided = true
            tech.techDurability = tech.techDurability - cnt
            if tech.techDurability <= 0 then
                toDelete[#toDelete + 1] = i
            end
        end
    end

    for i = #toDelete, 1, -1 do
        local idx = toDelete[i]
        local tech = techs[idx]

        if tech.removeCb ~= nil then
            tech.removeCb(tech)
        end

        utils.tableRemove(techs, idx)
        tech:removeSelf()
        tech.txt:removeSelf()
    end
end

function M.applyDamage(tech, cnt)
    tech.techDurability = tech.techDurability - cnt
    if tech.techDurability > 0 then
        return
    end

    if tech.removeCb ~= nil then
        tech.removeCb(tech)
    end

    for i, _ in next, techs do
        if techs[i] == tech then
            utils.tableRemove(techs, i)
            break
        end
    end

    tech:removeSelf()
    tech.txt:removeSelf()
end

function M.findCollision(req, ignore)
    for _, tech in next, techs do
        if tech == ignore then
            -- Этот пропускаем
        elseif tech.techType == const.TechBuyAds then
            -- Покупка рекламы просто висит, не взаимодействуя с запросами (она их нагоняет)
        elseif hasCollidedSquareAndRect(req, tech) then
            tech.isCollided = true
            return tech
        end
    end
    return nil
end

function M.getMinTargetY(tech)
    local x1, x2, y = tech.x, tech.x + tech.width, tech.y

    local maxY = const.TopPanelHeight + h / 2 + 100

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
