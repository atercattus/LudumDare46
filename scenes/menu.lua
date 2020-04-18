local gameName = gameName
local fontName = fontName
local display = display
local composer = require("composer")
local scene = composer.newScene()

function scene:create(event)
    local W, H = display.contentWidth, display.contentHeight
    local sceneGroup = self.view

    local bg = display.newRect(sceneGroup, 0, 0, W, H)
    bg.anchorX = 0
    bg.anchorY = 0
    bg:setFillColor(0, 0, 0)

    local titleText = display.newText({ text = gameName, width = W, font = fontName, fontSize = 90, align = 'center' })
    sceneGroup:insert(titleText)
    titleText:setFillColor(1, 1, 0.4)
    titleText.anchorX = 0.5
    titleText.anchorY = 0
    titleText.x = W / 2
    titleText.y = 10

    --local controls = display.newImageRect("data/controls.png", 512, 512)
    --sceneGroup:insert(controls)
    --controls.x = W / 2
    --controls.y = H
    --controls.anchorX = 0.5
    --controls.anchorY = 1
    --controls.xScale = 1
    --controls.yScale = 1
    --
    --local startGameScaleFunc
    --startGameScaleFunc = function()
    --    transition.scaleTo(controls, {
    --        time = 2500,
    --        xScale = 1.07,
    --        yScale = 1.07,
    --        onComplete = function()
    --            transition.scaleTo(controls, { time = 2500, xScale = 1, yScale = 1, onComplete = startGameScaleFunc })
    --        end
    --    })
    --end
    --startGameScaleFunc()

    --bg:addEventListener("touch", function(event)
    --    if event.phase == 'began' then
    --        composer.gotoScene('scenes.game')
    --    end
    --    return true
    --end)
end

scene:addEventListener("create", scene)
scene:addEventListener("show", function()
    composer.removeHidden() -- Выгружаю остальные сцены
end)

return scene
