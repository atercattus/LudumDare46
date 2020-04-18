local gameName = gameName
local fontName = fontName

local composer = require("composer")
local sceneInternals = require('scenes.scene_internals')

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

sceneInternals(scene)

return scene
