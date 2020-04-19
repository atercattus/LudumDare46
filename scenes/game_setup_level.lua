return function(parent, scene)
    local display = display
    local W, H = display.contentWidth, display.contentHeight

    local const = require('scenes.game_constants')
    local panelsLogic = require('scenes.game_techs_logic')

    local function setupLevelPlayer()
        local playerTech = panelsLogic.newTech(parent, const.TechFirewall, true)
        playerTech.x = -1
        playerTech.y = H - const.BottomPanelHeight - playerTech.height * 5 -- 1.5
        scene.objs.player = playerTech

        local techBuild = panelsLogic.newTech(parent, const.TechBuild, false)
        techBuild.x = -1
        techBuild.y = const.TopPanelHeight + 100
        scene.objs.playerBuild = techBuild

        -- Тесты:

        for i = 1, 4 do
            local techThrottling = panelsLogic.newTech(parent, const.TechThrottling, true)
            techThrottling.x = 150 + (i - 1) * 50
            techThrottling.y = H / 2 - (i - 1) * 100
        end

        local techFilter = panelsLogic.newTech(parent, const.TechFilter, true)
        techFilter.x = W / 2 + 100
        techFilter.y = H / 2 + 50

        local techMLDPI = panelsLogic.newTech(parent, const.TechMLDPI, true)
        techMLDPI.x = W - techMLDPI.width / 2
        techMLDPI.y = H / 3
    end

    setupLevelPlayer()
end
