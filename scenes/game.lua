--local gameName = gameName
--local fontName = fontName

local composer = require("composer")
local utils = require("libs.utils")
local pool = require('libs.pool')

local gameSetupUI = require('scenes.game_setup_ui')
local gameSetupLevel = require('scenes.game_setup_level')
local sceneInternals = require('scenes.scene_internals')
local panelsLogic = require('scenes.game_panels_logic')

local const = require('scenes.game_constants')

local display = display
local scene = composer.newScene()
local mathRandom = math.random
local W, H = display.contentWidth, display.contentHeight

--- UI ---

local ReqWidth = 16
local ReqHeight = 16

function scene:create(event)
    W, H = display.contentWidth, display.contentHeight

    self.reqInFlight = {}
    self.objs = {}

    self.levelGroup = display.newGroup()
    self.levelGroup.x = 0
    self.levelGroup.y = 0
    self.view:insert(self.levelGroup)
    gameSetupLevel(self.levelGroup, self)

    gameSetupUI(self.view, self)

    -- fake test requests
    for i = 1, 1000 do
        local reqType = const.ReqTypeLegal
        local rnd = mathRandom()
        if rnd < 0.05 then
            reqType = const.ReqTypeUnknown
        elseif rnd > 0.3 then
            reqType = const.ReqTypeFlood
        end
        self:newReq(reqType)
    end

    self:addUpdate(self.updateRequests)
    self:addUpdate(self.updatePlayer)
end

function scene:updateRequests(deltaTime)
    local self = scene
    for i = 1, #self.reqInFlight do
        local req = self.reqInFlight[i]

        if req.isVisible then
            if utils.hasCollidedSquareAndRect(req, self.objs.player) then
                panelsLogic.collideReqWithPanel(req, self.objs.player)
            elseif utils.hasCollidedSquareAndRect(req, self.objs.panelThrottling) then
                panelsLogic.collideReqWithPanel(req, self.objs.panelThrottling)
            end
        end

        req.y = req.y + req.speed * deltaTime
        if req.y > H - const.BottomPanelHeight then
            req.y = const.TopPanelHeight - ReqHeight
            req.isVisible = true
        end
    end
end

function scene:updatePlayer(deltaTime)
    local x = scene.mousePos.x
    if x < 0 then
        x = W / 2
    end
    scene.objs.player.x = x
    scene.objs.panelBuild.x = x
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

    local color = const.ReqColors[reqType]
    req:setFillColor(color[1], color[2], color[3])

    self.reqInFlight[#self.reqInFlight + 1] = req

    return req
end

sceneInternals(scene)

return scene
