return function(parent, scene)
    local display = display
    local W, H = display.contentWidth, display.contentHeight

    local const = require('scenes.game_constants')
    local panelsLogic = require('scenes.game_panels_logic')

    local function setupLevelPlayer()
        local panelThrottling = panelsLogic.newPanel(parent, const.TechFirewall)
        panelThrottling.x = 150
        panelThrottling.y = H/2
        scene.objs.panelThrottling = panelThrottling

        local panel = panelsLogic.newPanel(parent, const.TechFirewall)
        panel.x = -1
        panel.y = H - const.BottomPanelHeight - 100 -- - panel.height*1.5
        scene.objs.player = panel

        local panelBuild =  panelsLogic.newPanel(parent, const.TechBuild)
        panelBuild.x = -1
        panelBuild.y = const.TopPanelHeight + 100
        scene.objs.panelBuild = panelBuild
    end

    local bg = display.newRect(parent, 0, const.TopPanelHeight, W, H - const.TopPanelHeight - const.BottomPanelHeight)
    bg.anchorX = 0
    bg.anchorY = 0
    bg:setFillColor(0.03, 0.03, 0.03)

    setupLevelPlayer()
end
