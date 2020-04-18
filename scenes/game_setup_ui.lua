return function(parent, scene)
    local display = display
    local fontName = fontName
    local W, H = display.contentWidth, display.contentHeight

    local const = require('scenes.game_constants')
    local panelsLogic = require('scenes.game_panels_logic')
    local utils = require("libs.utils")

    local colorAvail = { 1, 1, 0.4 }
    local colorUnavail = { 0.8, 0.8, 0.8 }

    local colorLAOk = { 0.2, 0.9, 0.2 }
    local colorLAWarn = { 0.7, 0.5, 0.2 }
    local colorLACrit = { 1.0, 0.2, 0.2 }

    local function setColor(obj, color)
        obj:setFillColor(color[1], color[2], color[3])
    end

    function scene:updateMoney()
        local money = scene.state.money

        local precision = 0
        if money < 10 then
            precision = 3
        elseif money < 50 then
            precision = 2
        elseif money < 100 then
            precision = 1
        end

        local newText = '$' .. utils.roundStr(scene.state.money, precision)
        if newText ~= scene.objs.txtMoney.text then
            scene.objs.txtMoney.text = newText
        end
    end


    function scene:updateLA()
        local la = scene.state.la
        scene.objs.txtLAValue.text = math.floor(la) .. '%'
        local color = colorLAOk
        if la < 60 then
        elseif la < 95 then
            color = colorLAWarn
        else
            color = colorLACrit
        end
        setColor(scene.objs.txtLAValue, color)
    end

    function scene:updateServersCount()
        scene.objs.txtSrvCnt.text = 'x' .. scene.state.serversCnt
    end

    local function setupUITopPanel()
        local bg = display.newRect(parent, 0, 0, W, const.TopPanelHeight)
        bg.anchorX = 0
        bg.anchorY = 0
        bg:setFillColor(0, 0, 0)

        local textParams = { width = 220, font = fontName, fontSize = fontSize, align = 'center' }

        local techXs = { 20, 240, 460, 680, W }

        for i = 1, #const.TechNames do
            local params = textParams
            params.text = i .. '.' .. const.TechNames[i] .. '\n$' .. const.TechCosts[i]
            local txt = display.newText(params)
            setColor(txt, colorAvail)
            txt.anchorX = 0
            txt.anchorY = 0
            txt.x = techXs[i]
            txt.y = 0
            parent:insert(txt)

            local panel = panelsLogic.newPanel(parent, i)
            panel.x = techXs[i] + (techXs[i + 1] - techXs[i]) / 2
            panel.y = const.TopPanelHeight - 5
            panel.anchorY = 1
            panel.xScale = 0.8
            panel.yScale = 0.8
        end
    end

    local function setupUIBottomPanelLoadAverage()
        local bg = display.newRect(parent, 0, 0, W, const.BottomPanelHeight)
        bg.y = H - bg.height
        bg.anchorX = 0
        bg.anchorY = 0
        bg:setFillColor(0, 0, 0)

        local params = { font = fontName, fontSize = 30, align = 'center' }

        params.text = 'Load\nAverage'
        params.width = 150
        params.align = 'right'
        local txtLA = display.newText(params)
        txtLA.anchorX = 0
        txtLA.anchorY = 0.5
        txtLA.x = 0
        txtLA.y = H - const.BottomPanelHeight / 2
        parent:insert(txtLA)

        params.text = ''
        params.width = 150
        params.align = 'center'
        params.fontSize = 50
        local txtLAValue = display.newText(params)
        --txtLAValue:setFillColor(0.89, 0.2, 0.2)
        --txtLAValue:setFillColor(0.2, 0.9, 0.2)
        txtLAValue.anchorX = 0
        txtLAValue.anchorY = 0.5
        txtLAValue.x = 150
        txtLAValue.y = H - const.BottomPanelHeight / 2
        parent:insert(txtLAValue)
        scene.objs.txtLAValue = txtLAValue
        scene:updateLA()
    end

    local function setupUIBottomPanelServersCnt()
        local w = 100
        local x = 350
        local srvImg = display.newRect(parent, 0, 0, w, w)
        srvImg.x = x
        srvImg.y = H - const.BottomPanelHeight / 2
        srvImg.anchorX = 0.5
        srvImg.anchorY = 0.5
        srvImg:setFillColor(0.5, 0.5, 0.5)
        parent:insert(srvImg)

        local txtSrvCnt = display.newText({ text = 'x1', width = 300, font = fontName, fontSize = 50, align = 'left' })
        txtSrvCnt.anchorX = 0
        txtSrvCnt.anchorY = 1
        txtSrvCnt.x = x + w / 2
        txtSrvCnt.y = srvImg.y
        txtSrvCnt:setFillColor(0.4, 0.4, 1.0)
        parent:insert(txtSrvCnt)
        scene.objs.txtSrvCnt = txtSrvCnt
        scene:updateServersCount()
    end

    local function setupUIBottomPanelMoney()
        local txtMoney = display.newText({ text = '$100500', width = W, font = fontName, fontSize = 50, align = 'right' })
        txtMoney.anchorX = 1
        txtMoney.anchorY = 1
        txtMoney.x = W - 10
        txtMoney.y = H - 10
        txtMoney:setFillColor(0.3, 1.0, 0.3)
        parent:insert(txtMoney)
        scene.objs.txtMoney = txtMoney
        scene:updateMoney()
    end

    local function setupUIBottomPanel()
        setupUIBottomPanelLoadAverage()
        setupUIBottomPanelServersCnt()
        setupUIBottomPanelMoney()
    end

    setupUITopPanel()
    setupUIBottomPanel()
end
