--local gameName = gameName
--local fontName = fontName

local composer = require("composer")
local utils = require("libs.utils")
local pool = require('libs.pool')

local gameUI = require('scenes.game_ui')
local gameInternals = require('scenes.game_internals')

local display = display
local scene = composer.newScene()
local mathRandom = math.random
local W, H = display.contentWidth, display.contentHeight

--- UI ---
local TopPanelHeight = 100
local BottomPanelHeight = 150

local ReqWidth = 32
local ReqHeight = 32
local ReqRenderScale = 0.5

--- Requests ---
local ReqTypeFlood = 1
local ReqTypeLegal = 2
local ReqTypeUnknown = 3
local ReqColors = {
    [ReqTypeFlood] = { 0.7, 0.0, 0.0 },
    [ReqTypeLegal] = { 0, 0.7, 0 },
    [ReqTypeUnknown] = { 0.7, 0.7, 0.7 },
}

function scene:create(event)
    W, H = display.contentWidth, display.contentHeight

    scene.reqInFlight = {}

    gameUI(scene)
    scene:setupLevel()

    -- fake test requests
    for i = 1, 1000 do
        local reqType = ReqTypeLegal
        local rnd = mathRandom()
        if rnd < 0.05 then
            reqType = ReqTypeUnknown
        elseif rnd > 0.3 then
            reqType = ReqTypeFlood
        end
        scene:newReq(reqType)
    end
end

function scene:setupLevel()
    self.levelGroup = display.newGroup()
    self.levelGroup.x = 0
    self.levelGroup.y = 0
    self.view:insert(self.levelGroup)

    self:setupLevelPlayer()
end

function scene:setupLevelPlayer()

end

function scene:newReq(reqType)
    if self.poolRequests == nil then
        local sceneSelf = self
        self.poolRequests = pool:new(function()
            local req = display.newImageRect("data/circle.png", ReqWidth, ReqHeight)
            sceneSelf.levelGroup:insert(req)
            req.anchorX = 0.5
            req.anchorY = 0.5

            return req
        end)
    end

    local req = self.poolRequests:get()
    req.isVisible = true

    req.reqType = reqType
    req.x = mathRandom(W)
    req.y = mathRandom(-20, 20)
    req.speed = mathRandom(200, 500)
    req.xScale = ReqRenderScale
    req.yScale = ReqRenderScale

    local color = ReqColors[reqType]
    req:setFillColor(color[1], color[2], color[3])

    self.reqInFlight[#self.reqInFlight + 1] = req

    return req
end

function scene:update(deltaTime)
    for i = 1, #self.reqInFlight do
        local req = self.reqInFlight[i]

        req.y = req.y + req.speed * deltaTime
        if req.y > H - BottomPanelHeight then
            req.y = TopPanelHeight - ReqHeight * ReqRenderScale / 2
        end
    end
end

gameInternals(scene)

return scene
