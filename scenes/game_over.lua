local gameName = gameName
local fontName = fontName

local composer = require("composer")
local sceneInternals = require('scenes.scene_internals')

local display = display
local scene = composer.newScene()
local W, H = display.contentWidth, display.contentHeight

local phrases = {
    'Try again',
    'F5',
    'Busted',
    'I Never Asked For This',
    'What a shame',
    'Directed by\nRobert B. Weide',
    'The right man in the wrong place',
}

function scene:create(event)
    W, H = display.contentWidth, display.contentHeight
    local sceneGroup = self.view

    local bg = display.newRect(sceneGroup, 0, 0, W, H)
    bg.anchorX = 0
    bg.anchorY = 0
    bg:setFillColor(0, 0, 0)

    local titleText = display.newText({ text = 'GAME OVER', width = W, font = fontName, fontSize = 90, align = 'center' })
    sceneGroup:insert(titleText)
    titleText:setFillColor(1, 1, 0.4)
    titleText.anchorX = 0.5
    titleText.anchorY = 0.5
    titleText.x = W / 2
    titleText.y = H / 2

    local phrase = phrases[math.random(#phrases)]
    local phraseText = display.newText({ text = '"' .. phrase .. '"', width = W, font = fontName, fontSize = 40, align = 'center' })
    sceneGroup:insert(phraseText)
    phraseText:setFillColor(1, 1, 1)
    phraseText.anchorX = 0.5
    phraseText.anchorY = 0
    phraseText.x = W / 2
    phraseText.y = H / 2 + titleText.height + 20

    bg:addEventListener("touch", function(ev)
        if ev.phase == 'began' then
            composer.gotoScene('scenes.menu')
        end
        return true
    end)
end

function scene:update(deltaTime)
end

sceneInternals.init(scene)

return scene
