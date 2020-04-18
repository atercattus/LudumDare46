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
local tableRemove = utils.tableRemove
local W, H = display.contentWidth, display.contentHeight

--- UI ---

local ReqWidth = 64
local ReqHeight = 64
local ReqSteps = 12

local UIReqMaxSprites = 700 -- Можно сделать настройкой "качество графики" XD
local UIReqMaxNewPerCall = 200
local UIReqMaxSpeed = 600
local UIReqSpeedupPerSecond = 1.1

local LegalQpsSpeedupPerSecond = 2

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
        baseReqSpeed = 300, -- Базовая скорость нового запроса
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
    local toDeleteReqCnt = 0
    for i, req in next, self.reqInFlight do
        self:checkPanelsForReq(req)

        req.y = req.y + req.speed * deltaTime
        if req.y > H - const.BottomPanelHeight then
            toDelete[#toDelete + 1] = i
            toDeleteReqCnt = toDeleteReqCnt + req.reqCnt -- Подсчет реального количества запросов, а не числа спрайтов
        end
    end

    local state = scene.state

    if #toDelete > 0 then
        state.money = state.money + state.CPC * (toDeleteReqCnt / 1000.0) -- CPC читаю за тысячу
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

    state.legalQps = state.legalQps + state.legalQpsSpeedup * deltaTime
    state.legalQpsSpeedup = state.legalQpsSpeedup + deltaTime * LegalQpsSpeedupPerSecond

    state.baseReqSpeed = math.min(UIReqMaxSpeed, state.baseReqSpeed + UIReqSpeedupPerSecond * deltaTime)
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

    if #self.reqInFlight > UIReqMaxSprites then
        -- Ограничение на число отрисовываемых спрайтов
        return
    end

    local cntFloat = scene.newReqsAccum + (scene.state.legalQps * deltaTime)
    local cnt = math.floor(cntFloat)
    scene.newReqsAccum = cntFloat - cnt
    if cnt > 0 then
        local cntCoeff = 1
        if cnt > UIReqMaxNewPerCall then
            cntCoeff = cnt / UIReqMaxNewPerCall
            cnt = UIReqMaxNewPerCall
        end
        local maxStep = math.min(ReqSteps, math.max(1, cnt / 10))
        for step = maxStep, 1, -1 do
            while (cnt >= step) and (#self.reqInFlight < UIReqMaxSprites) do
                if cnt > 1 then
                    -- Даже при большом потоке даю шанс выпасть мелкой картинке, чтобы в целом поток выглядил равномернее
                    local rnd = mathRandom(step) / step
                    cntCoeff = cntCoeff / rnd
                    step = math.max(1, step * rnd)
                end
                scene:newReq(const.ReqTypeLegal, step, cntCoeff)
                cnt = cnt - step
            end
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
    for j = 1, #self.panels do
        local panel = self.panels[i]
        if utils.hasCollidedSquareAndRect(req, panel) then
            panelsLogic.collideReqWithPanel(req, panel)
        end
    end
end

function scene:newReq(reqType, cnt, cntCoeff)
    if self.poolRequests == nil then
        local sceneSelf = self

        local options = {
            width = ReqWidth,
            height = ReqHeight,
            numFrames = ReqSteps,
        }
        local circleImageSheet = graphics.newImageSheet("data/circle.png", options)

        self.poolRequests = pool:new(function()
            local req = display.newRect(0, 0, ReqWidth, ReqHeight)
            req.fill = { type = "image", sheet = circleImageSheet, frame = 1 }
            sceneSelf.levelGroup:insert(req)
            req.anchorX = 0.5
            req.anchorY = 0.5

            return req
        end)
    end

    local req = self.poolRequests:get()
    req.reqCnt = math.round(cnt * cntCoeff) -- Сохраняю реальное количество запросов, которое обозначает этот спрайт
    if cnt > ReqSteps then
        cnt = ReqSteps
    end
    req.fill.frame = cnt
    req.rotation = mathRandom(360)

    req.isVisible = true

    req.reqType = reqType
    req.x = mathRandom(W - ReqWidth) + ReqWidth / 2
    req.y = const.TopPanelHeight + -mathRandom(ReqWidth * 10) / 10.0
    req.speed = self.state.baseReqSpeed + mathRandom(100)

    local color = const.ReqColors[reqType]
    req:setFillColor(color[1], color[2], color[3])

    self.reqInFlight[#self.reqInFlight + 1] = req

    return req
end

sceneInternals(scene)

return scene
