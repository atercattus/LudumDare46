--local gameName = gameName
--local fontName = fontName

local composer = require("composer")
local utils = require("libs.utils")

local display = display
local scene = composer.newScene()
local mathRandom = math.random
local W, H = display.contentWidth, display.contentHeight

function scene:create(event)
    W, H = display.contentWidth, display.contentHeight
    local sceneGroup = self.view

    local bg = display.newRect(sceneGroup, 0, 0, W, H)
    bg.anchorX = 0
    bg.anchorY = 0
    bg:setFillColor(0, 0, 0)

    local circle = display.newImageRect("data/circle.png", 32, 32)
    scene.circle = circle
    sceneGroup:insert(circle)
    circle.x = mathRandom(W)
    circle.y = 0
    circle.anchorX = 0.5
    circle.anchorY = 0.5
end

function scene:update(deltaTime)
    scene.circle.y = scene.circle.y + 500 * deltaTime
    if scene.circle.y > H then
        scene.circle.y = 0
    end
end

local function onEnterFrame(event)
    scene:onEnterFrame(event)
end

scene:addEventListener("create", scene)
scene:addEventListener("show", function(event)
    composer.removeHidden() -- Выгружаю остальные сцены

    if (event.phase == "will") then
        Runtime:addEventListener("enterFrame", onEnterFrame)
    end
end)

scene:addEventListener("hide", function(event)
    --if (event.phase == "did") then
    Runtime:removeEventListener("enterFrame", onEnterFrame)
    --end
end)

function scene:onEnterFrame(event)
    local deltaTime = utils.getDeltaTime(event.time)
    if deltaTime > 0 then
        self:update(deltaTime)
    end
end

return scene
