return function(parent)
    local display = display
    local fontName = fontName
    local W, H = display.contentWidth, display.contentHeight

    local const = require('scenes.game_constants')

    local colorAvail = { 1, 1, 0.4 }
    local colorUnavail = { 0.8, 0.8, 0.8 }

    local function setColor(obj, color)
        obj:setFillColor(color[1], color[2], color[3])
    end

    local function setupUITopPanel()
        local params = { width = 220, font = fontName, fontSize = fontSize, align = 'center' }

        params.text = '1.Throttling\n$' .. const.TechCosts[const.TechThrottling]
        local txtThrottling = display.newText(params)
        setColor(txtThrottling, colorAvail)
        txtThrottling.anchorX = 0
        txtThrottling.anchorY = 0
        txtThrottling.x = 20
        txtThrottling.y = 0
        parent:insert(txtThrottling)

        params.text = '2.Filter\n$' .. const.TechCosts[const.TechFilter]
        local txtFloodFilter = display.newText(params)
        setColor(txtFloodFilter, colorAvail)
        txtFloodFilter.anchorX = 0
        txtFloodFilter.anchorY = 0
        txtFloodFilter.x = 280
        txtFloodFilter.y = 0
        parent:insert(txtFloodFilter)

        params.text = '3.Firewall\n$' .. const.TechCosts[const.TechFirewall]
        local txtFirewall = display.newText(params)
        setColor(txtFirewall, colorUnavail)
        txtFirewall.anchorX = 0
        txtFirewall.anchorY = 0
        txtFirewall.x = 500
        txtFirewall.y = 0
        parent:insert(txtFirewall)

        params.text = '4.ML DPI\n$' .. const.TechCosts[const.TechMLDPI]
        local txtMLDPI = display.newText(params)
        setColor(txtMLDPI, colorUnavail)
        txtMLDPI.anchorX = 0
        txtMLDPI.anchorY = 0
        txtMLDPI.x = 700
        txtMLDPI.y = 0
        parent:insert(txtMLDPI)
    end

    local function setupUIBottomPanel()

    end

    local bg = display.newRect(parent, 0, 0, W, H)
    bg.anchorX = 0
    bg.anchorY = 0
    bg:setFillColor(0, 0, 0)

    setupUITopPanel()
    setupUIBottomPanel()
end
