local gameName = gameName
local fontName = fontName

local composer = require("composer")
local sceneInternals = require('scenes.scene_internals')
local const = require('scenes.game_constants')
local utils = require("libs.utils")

local display = display
local scene = composer.newScene()
local W, H = display.contentWidth, display.contentHeight

function scene:setupUITopPanel()
    local parent = self.view

    local bg = display.newRect(parent, 0, 0, W, const.TopPanelHeight)
    bg.anchorX = 0
    bg.anchorY = 0
    bg:setFillColor(0, 0, 0)

    --==================================================================================================================

    local TOP = 150

    local options = {
        width = ReqWidth,
        height = ReqHeight,
        numFrames = ReqSteps,
    }
    local circleImageSheet = graphics.newImageSheet("data/circle.png", options)
    local reqLegal = display.newRect(0, 0, ReqWidth, ReqHeight)
    reqLegal.fill = { type = "image", sheet = circleImageSheet, frame = 1 }
    parent:insert(reqLegal)
    reqLegal.anchorX = 0.5
    reqLegal.anchorY = 0.5
    reqLegal.x = 80
    reqLegal.y = TOP
    local color = const.ReqColors[const.ReqTypeLegal]
    reqLegal:setFillColor(color[1], color[2], color[3])
    local txt = display.newText({ text = "Request from legal user\nYou'll get money for this", width = W, font = fontName, fontSize = 30, align = 'left' })
    txt.anchorX = 0
    txt.anchorY = 0.5
    txt.x = reqLegal.x
    txt.y = reqLegal.y - 20
    parent:insert(txt)

    local reqFlood = display.newRect(0, 0, ReqWidth, ReqHeight)
    reqFlood.fill = { type = "image", sheet = circleImageSheet, frame = 1 }
    parent:insert(reqFlood)
    reqFlood.anchorX = 0.5
    reqFlood.anchorY = 0.5
    reqFlood.x = 80
    reqFlood.y = TOP+90
    local color = const.ReqColors[const.ReqTypeFlood]
    reqFlood:setFillColor(color[1], color[2], color[3])
    local txt = display.newText({ text = "Request from malicious user\nCreates a load on your servers", width = W, font = fontName, fontSize = 30, align = 'left' })
    txt.anchorX = 0
    txt.anchorY = 0.5
    txt.x = reqFlood.x
    txt.y = reqFlood.y - 20
    parent:insert(txt)

    --==================================================================================================================

    local TOP = 400

    local textParams = { width = 220, font = fontName, fontSize = 30, align = 'center' }
    local techXs = { 20, 240, 460, 680, W }
    for i = 1, #const.TechNames do
        local params = textParams
        params.text = i .. '\n' .. const.TechNames[i]
        local txt = display.newText(params)
        --setColor(txt, colorAvail)
        txt.anchorX = 0
        txt.anchorY = 0
        txt.x = techXs[i]
        txt.y = TOP
        parent:insert(txt)

        local panel = techsLogic.newTech(parent, i, false)
        panel.x = techXs[i] + (techXs[i + 1] - techXs[i]) / 2
        panel.y = const.TopPanelHeight + TOP
        panel.anchorY = 1
        panel.xScale = 0.8
        panel.yScale = 0.8
    end

    --==================================================================================================================

    local TOP = 500

    local texts = {
        const.TechNames[const.TechThrottling] .. ' blocks every second request any type',
        const.TechNames[const.TechFilter] .. ' blocks most flood requests but also a little legal',
        const.TechNames[const.TechFirewall] .. ' almost completely blocks flood requests',
        const.TechNames[const.TechBuyAds] .. ' to temporarily increase the flow of requests. But be careful!',
    }

    local step = H / 14
    for i, text in next, texts do
        local txt = display.newText({ text = text, width = W - 60, font = fontName, fontSize = 35, align = 'left' })
        parent:insert(txt)
        txt:setFillColor(1, 1, 1)
        txt.anchorX = 0
        txt.anchorY = 0
        txt.x = 30
        txt.y = TOP + step * i
    end

    --==================================================================================================================

    local TOP = 1200

    local w = 100
    local frameCnt = 4
    local options = {
        width = 64,
        height = 64,
        numFrames = frameCnt,
    }
    local serverImageSheet = graphics.newImageSheet("data/server.png", options)
    local srvImg = display.newRect(parent, 0, 0, w, w)
    srvImg.fill = { type = "image", sheet = serverImageSheet, frame = 1 }
    srvImg.fillFrameCnt = frameCnt
    srvImg.x = 100
    srvImg.y = TOP
    scene:addTimer(timer.performWithDelay(100, function()
        utils.setNextFrame(srvImg, srvImg.fillFrameCnt)
    end, -1))
    local txt = display.newText({ text = 'You should buy more servers to withstand more requests', width = W - 200, font = fontName, fontSize = 35, align = 'left' })
    parent:insert(txt)
    txt:setFillColor(1, 1, 1)
    txt.anchorX = 0
    txt.anchorY = 0.5
    txt.x = 200
    txt.y = TOP

    --==================================================================================================================

    local txtNext = display.newText({ text = 'Click to continue', width = W, font = fontName, fontSize = 40, align = 'center' })
    parent:insert(txtNext)
    txtNext:setFillColor(0.7, 0.7, 0.7)
    txtNext.anchorX = 0.5
    txtNext.anchorY = 1
    txtNext.x = W / 2
    txtNext.y = H
end

function scene:create(event)
    W, H = display.contentWidth, display.contentHeight
    local sceneGroup = self.view

    local bg = display.newRect(sceneGroup, 0, 0, W, H)
    bg.anchorX = 0
    bg.anchorY = 0
    bg:setFillColor(0, 0, 0)

    scene:setupUITopPanel()

    bg:addEventListener("touch", function(ev)
        if ev.phase == 'began' then
            composer.gotoScene('scenes.game')
        end
        return true
    end)
end

function scene:update(deltaTime)
    -- ...
end

sceneInternals.init(scene)

return scene
