--local gameName = gameName
--local fontName = fontName

local display = display

local composer = require("composer")

local scene = composer.newScene()

-- ===========================================================================================

function scene:create(event)
    local W, H = display.contentWidth, display.contentHeight
    local sceneGroup = self.view

    local bg = display.newRect(sceneGroup, 0, 0, W, H)
    bg.anchorX = 0
    bg.anchorY = 0
    bg:setFillColor(0, 0, 0)

end

scene:addEventListener("create", scene)
scene:addEventListener("show", function()
    composer.removeHidden() -- Выгружаю остальные сцены
end)

return scene
