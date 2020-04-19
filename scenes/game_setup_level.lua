return function(parent, scene)
    local display = display
    local W, H = display.contentWidth, display.contentHeight

    local const = require('scenes.game_constants')
    local panelsLogic = require('scenes.game_techs_logic')

    local function setupLevelPlayer()
        local playerTech = panelsLogic.newTech(parent, const.TechBuild, false)
        playerTech.x = -1
        playerTech.y = H - const.BottomPanelHeight - playerTech.height * 1.5
        scene.objs.player = playerTech
    end

    setupLevelPlayer()
end
