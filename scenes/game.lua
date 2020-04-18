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
local tableRemove = table.remove
local W, H = display.contentWidth, display.contentHeight

--- UI ---

local ReqWidth = 16
local ReqHeight = 16

function scene:create(event)
    W, H = display.contentWidth, display.contentHeight

    self.reqInFlight = {}
    self.panels = {}
    self.objs = {}
    self.state = {
        startedAt = system.getTimer() / 1000, -- Время начала (сек)
        money = 0, -- Денег на счету (нужны для покупки серверов и средств защиты от DDoS)
        CPC = 2, -- Стоимость каждой 1000 легальных запросов, долетевших до сервера
        la = 0, -- Суммарная нагрузка на все сервера (зависит от суммарного qps, долетающего до серверов)
        serversCnt = 1, -- Общее количество работающих серверов (влияет на LA)
        serverMaxQps = 5000, -- Максимальный QPS, который может обработать один сервер
        legalQps = 1, -- QPS пользовательских запросов (влияет на money)
        legalQpsSpeedup = 1, -- Прирост legalQps в секунду
    }

    self.levelGroup = display.newGroup()
    self.levelGroup.x = 0
    self.levelGroup.y = 0
    self.view:insert(self.levelGroup)

    gameSetupUI(self.view, self)

    gameSetupLevel(self.view, self)

    self:addUpdate(self.updateRequests)
    self:addUpdate(self.updatePlayer)
end

function scene:updateRequests(deltaTime)
    local self = scene

    local toDelete = {}
    for i = 1, #self.reqInFlight do
        local req = self.reqInFlight[i]

        self:checkPanelsForReq(req)

        req.y = req.y + req.speed * deltaTime
        if req.y > H - const.BottomPanelHeight then
            toDelete[#toDelete + 1] = i
        end
    end

    if #toDelete > 0 then
        local state = scene.state

        state.money = state.money + state.CPC * (#toDelete / 1000.0) -- CPC читаю за тысячу
        scene:updateMoney()

        scene.state.la = math.min(146, 100 * state.legalQps / (state.serverMaxQps * state.serversCnt))
        scene:updateLA()

        if scene.state.la >= 100 then
            state.serversCnt = state.serversCnt + 1 -- тестирую :)
            scene:updateServersCount()
        end

        scene:deleteReqsByIds(toDelete)
    end

    scene:updateRequestsGenNews(deltaTime)

    scene.state.legalQps = scene.state.legalQps + scene.state.legalQpsSpeedup * deltaTime
    scene.state.legalQpsSpeedup = scene.state.legalQpsSpeedup + deltaTime * 2
end

function scene:deleteReqsByIds(ids)
    for i = #ids, 1, -1 do
        local req = self.reqInFlight[ids[i]]
        tableRemove(self.reqInFlight, ids[i])
        self.poolRequests:put(req)
        req.isVisible = false
    end
end

function scene:updateRequestsGenNews(deltaTime)
    if scene.newReqsAccum == nil then
        scene.newReqsAccum = 0
    end

    if #self.reqInFlight > 1000 then
        -- Тут уже нужно использовать картинки с несколькими запросами
        return
    end

    local cntFloat = scene.newReqsAccum + (scene.state.legalQps * deltaTime)
    local cnt = math.floor(cntFloat)
    if cnt > 10 then
        cnt = 10
    end
    scene.newReqsAccum = cntFloat - cnt
    if cnt > 0 then
        for i = 1, cnt do
            scene:newReq(const.ReqTypeLegal)
        end
    end
end

function scene:updatePlayer(deltaTime)
    local x = scene.mousePos.x
    local w = scene.objs.player.width
    if x < w / 2 then
        x = w / 2
    elseif x > W - w / 2 then
        x = W - w / 2
    end
    scene.objs.player.x = x
    scene.objs.playerBuild.x = x
end

function scene:checkPanelsForReq(req)
    -- ToDo: нужно предварительно грубо отфильтовывать по Y
    for j = 1, #self.panels do
        local panel = self.panels[i]
        if utils.hasCollidedSquareAndRect(req, panel) then
            panelsLogic.collideReqWithPanel(req, panel)
        end
    end
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
    req.x = mathRandom(W - 2 * ReqWidth) + ReqWidth
    req.y = const.TopPanelHeight + -mathRandom(ReqWidth * 10) / 10.0
    req.speed = 350 + mathRandom(100)

    local color = const.ReqColors[reqType]
    req:setFillColor(color[1], color[2], color[3])

    self.reqInFlight[#self.reqInFlight + 1] = req

    return req
end

sceneInternals(scene)

return scene
