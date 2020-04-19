local gameName = gameName
local fontName = fontName

local composer = require("composer")
local sceneInternals = require('scenes.scene_internals')

local display = display
local scene = composer.newScene()
local W, H = display.contentWidth, display.contentHeight

function scene:create(event)
    techsLogic = require('scenes.game_techs_logic').new()

    W, H = display.contentWidth, display.contentHeight
    local sceneGroup = self.view

    local bg = display.newRect(sceneGroup, 0, 0, W, H)
    bg.anchorX = 0
    bg.anchorY = 0
    bg:setFillColor(0, 0, 0)

    local texts = { 'Keep', 'yoursite.com', 'alive', 'under DDoS' }

    local txtNext = display.newText({ text = 'Click to continue', width = W, font = fontName, fontSize = 40, align = 'center' })
    sceneGroup:insert(txtNext)
    txtNext:setFillColor(0.7, 0.7, 0.7)
    txtNext.anchorX = 0.5
    txtNext.anchorY = 1
    txtNext.x = W / 2
    txtNext.y = H
    txtNext.isVisible = false

    local txtAbout = display.newText({ text = 'LudumDare 46', width = W, font = fontName, fontSize = 30, align = 'center' })
    sceneGroup:insert(txtAbout)
    txtAbout:setFillColor(0.7, 0.7, 0.7)
    txtAbout.anchorX = 0.5
    txtAbout.anchorY = 0
    txtAbout.x = W / 2
    txtAbout.y = 0
    txtAbout.isVisible = false

    local step = H / 8
    for i, text in next, texts do
        local isLast = i == #texts
        local txt = display.newText({ text = text, width = W, font = fontName, fontSize = 90, align = 'center' })
        sceneGroup:insert(txt)
        txt:setFillColor(1, 1, 0.4)
        txt.anchorX = 0.5
        txt.anchorY = 0.5
        txt.x = W / 2
        txt.y = step * (i + 1)

        txt.isVisible = false

        local timeout = 400 * i
        if isLast then
            txt:setFillColor(1, 1, 1)
            timeout = 600 * i

            timer.performWithDelay(timeout, function()
                txtNext.isVisible = true
                txtAbout.isVisible = true
            end, 1)
        end

        timer.performWithDelay(timeout, function()
            txt.isVisible = true
        end, 1)
    end

    bg:addEventListener("touch", function(ev)
        if ev.phase == 'began' then
            composer.gotoScene('scenes.tutorial')
        end
        return true
    end)
end

function scene:update(deltaTime)
    -- ...
end

sceneInternals.init(scene)

return scene
