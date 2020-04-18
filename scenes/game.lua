local composer = require("composer")
local utils = require("libs.utils")
local flowNew = require('libs.flow').new

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

local ReqWidth = 64
local ReqHeight = 64
local ReqSteps = 12

local UIReqMaxSprites = 700 -- Можно сделать настройкой "качество графики" XD
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

    local options = {
        width = ReqWidth,
        height = ReqHeight,
        numFrames = ReqSteps,
    }
    local circleImageSheet = graphics.newImageSheet("data/circle.png", options)

    self:createFlowLegal(circleImageSheet)

    self.levelGroup = display.newGroup()
    self.levelGroup.x = 0
    self.levelGroup.y = 0
    self.view:insert(self.levelGroup)

    gameSetupUI(self.view, self)

    gameSetupLevel(self.view, self)

    self:addUpdate(self.flowLegal.update)
    self:addUpdate(self.updatePlayer)
end

function scene:createFlowLegal(circleImageSheet)
    self.flowLegal = flowNew({
        emitQps = 1,
        maxInFly = UIReqMaxSprites,
        reqSteps = ReqSteps,

        new = function()
            local req = display.newRect(0, 0, ReqWidth, ReqHeight)
            req.fill = { type = "image", sheet = circleImageSheet, frame = 1 }
            scene.levelGroup:insert(req)
            req.anchorX = 0.5
            req.anchorY = 0.5

            return req
        end,

        reset = function(req, cnt, cntCoeff)
            req.reqCnt = math.round(cnt * cntCoeff) -- Сохраняю реальное количество запросов, которое обозначает этот спрайт
            if cnt > ReqSteps then
                cnt = ReqSteps
            end
            req.fill.frame = cnt
            req.rotation = mathRandom(360)

            req.reqType = const.ReqTypeLegal
            req.x = mathRandom(W - ReqWidth) + ReqWidth / 2
            req.y = const.TopPanelHeight + -mathRandom(ReqWidth * 10) / 10.0
            req.speed = self.state.baseReqSpeed + mathRandom(100)

            local color = const.ReqColors[const.ReqTypeLegal]
            req:setFillColor(color[1], color[2], color[3])
        end,

        deleteFinished = function(reqs)
            local toDeleteReqCnt = 0
            for _, req in next, reqs do
                toDeleteReqCnt = toDeleteReqCnt + req.reqCnt -- Подсчет реального количества запросов, а не числа спрайтов
            end
            local state = scene.state

            state.money = state.money + state.CPC * (toDeleteReqCnt / 1000.0) -- CPC читаю за тысячу
            scene:updateMoney()

            scene.state.la = math.min(146, 100 * state.legalQps / (state.serverMaxQps * state.serversCnt))
            scene:updateLA()

            if scene.state.la >= 100 then
                state.serversCnt = state.serversCnt + 1 -- тестирую :)
                scene:updateServersCount()
            end
        end,

        update = function(deltaTime)
            -- ToDo: self:checkPanelsForReq(req)
            local state = scene.state

            state.legalQps = state.legalQps + state.legalQpsSpeedup * deltaTime
            state.legalQpsSpeedup = state.legalQpsSpeedup + deltaTime * LegalQpsSpeedupPerSecond

            state.baseReqSpeed = math.min(UIReqMaxSpeed, state.baseReqSpeed + UIReqSpeedupPerSecond * deltaTime)

            self.flowLegal.emitQps = state.legalQps
        end,
    })
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

sceneInternals(scene)

return scene
