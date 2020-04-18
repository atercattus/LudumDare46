return function(parent, scene)
    local display = display
    local graphics = graphics
    local W, H = display.contentWidth, display.contentHeight

    local const = require('scenes.game_constants')

    local function setupLevelPlayer()
        local options = {
            width = 256,
            height = 32,
            numFrames = 5,
        }
        scene.objs.panelsImageSheet = graphics.newImageSheet("data/panels.png", options)

        local panelThrottling = display.newRect(0, 0, 256, 32)
        panelThrottling.fill = { type = "image", sheet = scene.objs.panelsImageSheet, frame = 3 }
        panelThrottling.x = 150
        panelThrottling.y = H/2
        panelThrottling.anchorX = 0.5
        panelThrottling.anchorY = 0.5

        scene.objs.panelThrottling = panelThrottling

        local panel = display.newRect(0, 0, 256, 32)
        panel.fill = { type = "image", sheet = scene.objs.panelsImageSheet, frame = 3 }
        panel.x = -1
        panel.y = H - const.BottomPanelHeight - 100 -- - panel.height*1.5
        panel.anchorX = 0.5
        panel.anchorY = 0.5

        scene.objs.player = panel

        local panelBuild = display.newRect(0, 0, 256, 32)
        panelBuild.fill = { type = "image", sheet = scene.objs.panelsImageSheet, frame = 5 }
        panelBuild.x = -1
        panelBuild.y = const.TopPanelHeight + 100
        panelBuild.anchorX = 0.5
        panelBuild.anchorY = 0.5
        scene.objs.panelBuild = panelBuild
    end

    local bg = display.newRect(parent, 0, const.TopPanelHeight, W, H - const.TopPanelHeight - const.BottomPanelHeight)
    bg.anchorX = 0
    bg.anchorY = 0
    bg:setFillColor(0.03, 0.03, 0.03)

    setupLevelPlayer()
end
