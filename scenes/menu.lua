local gameName = gameName
local fontName = fontName

local composer = require("composer")
local utils = require("libs.utils")

local display = display
local scene = composer.newScene()
local W, H = display.contentWidth, display.contentHeight

function scene:create(event)
    W, H = display.contentWidth, display.contentHeight
    local sceneGroup = self.view

    local bg = display.newRect(sceneGroup, 0, 0, W, H)
    bg.anchorX = 0
    bg.anchorY = 0
    bg:setFillColor(0, 0, 0)

    local titleText = display.newText({ text = gameName, width = W, font = fontName, fontSize = 90, align = 'center' })
    sceneGroup:insert(titleText)
    titleText:setFillColor(1, 1, 0.4)
    titleText.anchorX = 0.5
    titleText.anchorY = 0.5
    titleText.x = W / 2
    titleText.y = H / 2

    bg:addEventListener("touch", function(ev)
        if ev.phase == 'began' then
            composer.gotoScene('scenes.game')
        end
        return true
    end)
end

function scene:update(deltaTime)
    -- ...
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
