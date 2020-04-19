local composer = require("composer")
local utils = require("libs.utils")
local flowNew = require('libs.flow').new

local gameSetupUI = require('scenes.game_setup_ui')
local gameSetupLevel = require('scenes.game_setup_level')
local sceneInternals = require('scenes.scene_internals')

local const = require('scenes.game_constants')
local techsLogic = require('scenes.game_techs_logic')

local scene = composer.newScene()
local mathRandom = math.random
local W, H = display.contentWidth, display.contentHeight

--- UI ---

local ReqWidth = 64
local ReqHeight = 64
local ReqSteps = 12

local UIReqMaxSprites = 200 -- Можно сделать настройкой "качество графики" XD
local UIReqMaxSpeed = 600
local UIReqSpeedupPerSecond = 1.1

local LegalQpsSpeedupPerSecond = 1.2
local FloodQpsSpeedupPerSecond = 0.5

local TimeToFirstWave = mathRandom(10, 20)
local WaveDuration = { 10, 30 }
local IntervalBetweenWaves = { 20, 30 }
local WaveDensity = { 40, 95 }
local WaveFloodQpsIncrease = { 20, 100 } -- % от максимальной возможности системы

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
        --legalQps = 1, -- QPS пользовательских запросов (влияет на money)
        legalQpsSpeedup = 1, -- Прирост self.flowLegal.emitQps в секунду
        floodQpsSpeedup = 0.2, -- Прирост self.flowFlood.emitQps в секунду
        unknownQpsSpeedup = 0.2, -- Прирост self.unknownFlood.emitQps в секунду
        baseReqSpeed = 300, -- Базовая скорость нового запроса

        serverQueries = 0, -- Сколько запросов долетело до серверов в последний интервал времени
        serverQps = 0, -- Какой QPS достигает серверов
    }

    local options = {
        width = ReqWidth,
        height = ReqHeight,
        numFrames = ReqSteps,
    }
    self.circleImageSheet = graphics.newImageSheet("data/circle.png", options)

    self:createFlowLegal()
    self:createFlowFlood()
    self:createFlowUnknown()

    self.levelGroup = display.newGroup()
    self.levelGroup.x = 0
    self.levelGroup.y = 0
    self.view:insert(self.levelGroup)

    gameSetupUI(self.view, self)

    gameSetupLevel(self.view, self)

    self:addUpdate(function(_, deltaTime)
        techsLogic:moveToTargetPositions(deltaTime)
        techsLogic:markAllUncollided()

        --self.flowLegal:update(deltaTime)
        self.flowFlood:update(deltaTime)
        --self.flowUnknown:update(deltaTime)

        techsLogic.processCollided()
    end)

    self:addUpdate(self.updatePlayer)

    -- Мигание лампочек на сервере
    timer.performWithDelay(100, function()
        utils.setNextFrame(self.objs.srvImg, self.objs.srvImg.fillFrameCnt)
    end, -1)

    timer.performWithDelay(300, function()
        scene:updateMoney()
    end, -1)

    timer.performWithDelay(1000, self.updateLoadAverage, -1)

    -- Запуск волн
    scene:startWaveGenerator()
end

function scene.flowNew()
    local req = display.newRect(0, 0, ReqWidth, ReqHeight)
    req.fill = { type = "image", sheet = scene.circleImageSheet, frame = 1 }
    scene.levelGroup:insert(req)
    req.anchorX = 0.5
    req.anchorY = 0.5

    return req
end

function scene.deleteFinished(reqType, reqs)
    local cnt = 0
    for _, req in next, reqs do
        cnt = cnt + req.reqCnt -- Подсчет реального количества запросов, а не числа спрайтов
    end

    local state = scene.state

    state.serverQueries = state.serverQueries + cnt

    if reqType == const.ReqTypeUnknown then
        reqType = mathRandom() < 0.4 and const.ReqTypeLegal or const.ReqTypeFlood
    end

    if reqType == const.ReqTypeLegal then
        state.money = state.money + state.CPC * (cnt / 1000.0) -- CPC читаю за тысячу
    else
        -- просто нагрузка на сервера
    end
end

function scene:startWaveGenerator()
    self.waveX = 0
    self.waveDensity = 0
    self.waveWidth = W / 8

    self.waveFloodQpsBak = 0

    local makeWave
    makeWave = function(after)
        timer.performWithDelay(after, function()
            local waveDuration = mathRandom(WaveDuration[1], WaveDuration[2])

            self.waveDensity = mathRandom(WaveDensity[1], WaveDensity[2]) / 100
            self.waveX = mathRandom(W - self.waveWidth) + self.waveWidth / 2

            -- Забиваем
            local waveBandUsage = mathRandom(WaveFloodQpsIncrease[1], WaveFloodQpsIncrease[2]) / 100
            local waveQpsIncrease = self.state.serversCnt * (self.state.serverMaxQps * waveBandUsage)
            print('WAVE', (100 * waveBandUsage) .. '%', waveQpsIncrease)

            self.waveFloodQpsBak = self.flowFlood.emitQps
            self.flowFlood.emitQps = waveQpsIncrease

            timer.performWithDelay(waveDuration * 1000, function()
                self.waveDensity = 0

                self.flowFlood.emitQps = self.waveFloodQpsBak

                -- Готовлю следующую волну
                makeWave(mathRandom(IntervalBetweenWaves[1], IntervalBetweenWaves[2]) * 1000)
            end, 1)
        end, 1)
    end

    makeWave(TimeToFirstWave * 1000)
end

function scene.flowResetFunc(reqType)
    return function(req, visualCnt, realCnt)
        req.reqCnt = realCnt -- Сохраняю реальное количество запросов, которое обозначает этот спрайт
        if visualCnt > ReqSteps then
            visualCnt = ReqSteps
        end
        req.fill.frame = visualCnt
        req.rotation = mathRandom(360)

        req.reqType = reqType

        req.y = const.TopPanelHeight + -mathRandom(ReqWidth * 10) / 10.0
        req.x = mathRandom(W - ReqWidth) + ReqWidth / 2

        if (reqType == const.ReqTypeFlood) and (mathRandom() < scene.waveDensity) then
            req.x = scene.waveX + (mathRandom(scene.waveWidth) - scene.waveWidth / 2)
        end

        req.speed = scene.state.baseReqSpeed + mathRandom(100)

        local color = const.ReqColors[reqType]
        req:setFillColor(color[1], color[2], color[3])
    end
end

function scene:updateLoadAverage(deltaTime)
    local self = scene
    local state = self.state

    local qps = state.serverQueries
    state.serverQueries = 0

    state.la = math.min(146, 100 * qps / (state.serverMaxQps * state.serversCnt))
    self:updateLA()

    if self.state.la >= 100 then
        print(qps, state.serverMaxQps * state.serversCnt)
        self:serversOverloaded()
    end
end

function scene:serversOverloaded(deltaTime)
    --local state = scene.state
    --state.serversCnt = state.serversCnt + 1 -- тестирую :)
    --self:updateServersCount()
end

function scene:createFlowLegal()
    self.flowLegal = flowNew({
        emitQps = 1,
        maxInFly = UIReqMaxSprites,
        reqSteps = ReqSteps,

        new = scene.flowNew,

        reset = scene.flowResetFunc(const.ReqTypeLegal),

        deleteFinished = function(reqs)
            self.deleteFinished(const.ReqTypeLegal, reqs)
        end,

        update = function(deltaTime)
            local state = scene.state

            self.flowLegal.emitQps = self.flowLegal.emitQps + state.legalQpsSpeedup * deltaTime
            state.legalQpsSpeedup = state.legalQpsSpeedup + deltaTime * LegalQpsSpeedupPerSecond

            state.baseReqSpeed = math.min(UIReqMaxSpeed, state.baseReqSpeed + UIReqSpeedupPerSecond * deltaTime)
        end,

        collision = function(req, tech)
            local techType = tech.techType
            if techType == const.TechThrottling then
                return mathRandom() < const.TechFiltering.Legal_Throttling
            elseif techType == const.TechFilter then
                return mathRandom() < const.TechFiltering.Legal_Filter
            end
            return false
        end,
    })
end

function scene:createFlowFlood()
    self.flowFlood = flowNew({
        emitQps = 0.5,
        maxInFly = 500, --UIReqMaxSprites,
        reqSteps = ReqSteps,

        new = scene.flowNew,

        reset = scene.flowResetFunc(const.ReqTypeFlood),

        deleteFinished = function(reqs)
            self.deleteFinished(const.ReqTypeFlood, reqs)
        end,

        update = function(deltaTime)
            local state = scene.state
            self.flowFlood.emitQps = self.flowFlood.emitQps + state.floodQpsSpeedup * deltaTime
        end,

        collision = function(req, tech)
            local techType = tech.techType
            if techType == const.TechFirewall then
                return true
            elseif techType == const.TechThrottling then
                return mathRandom() < const.TechFiltering.Flood_Throttling
            elseif techType == const.TechFilter then
                return mathRandom() < const.TechFiltering.Flood_Filter
            end
            return false
        end,
    })
end

function scene:createFlowUnknown()
    self.flowUnknown = flowNew({
        emitQps = 2,
        maxInFly = UIReqMaxSprites,
        reqSteps = ReqSteps,

        new = scene.flowNew,

        reset = scene.flowResetFunc(const.ReqTypeUnknown),

        deleteFinished = function(reqs)
            self.deleteFinished(const.ReqTypeUnknown, reqs)
        end,

        update = function(deltaTime)
            self.flowUnknown.emitQps = self.flowUnknown.emitQps + 1.2 * deltaTime
        end,

        collision = function(req, tech)
            local techType = tech.techType
            if techType == const.TechFirewall then
                return true
            elseif techType == const.TechThrottling then
                return mathRandom() < const.TechFiltering.Unknown_Throttling
            elseif techType == const.TechFilter then
                return mathRandom() < const.TechFiltering.Unknown_Filter
            elseif techType == const.TechMLDPI then
                return true -- Нужно заменять на реальный тип, но пока так
            end
            return false
        end,
    })
end

function scene:tryBuildTech(techType)
    local player = scene.objs.player

    local tech = techsLogic.newTech(self.view, techType, true)
    tech.x = player.x
    tech.y = player.y
    tech.speedY = -H / 2

    return true
end

function scene:tryBuildAnyTech()
    local money = scene.state.money + 10000 -- ToDo: тест

    local now = system.getTimer()
    if scene.lastCreatedTech == nil then
        scene.lastCreatedTech = 0
    end

    for techType, techCost in ipairs(const.TechCosts) do
        if money < techCost then
        elseif not scene.pressedKeys[techType] then
        elseif (now - scene.lastCreatedTech) < 300 then
            return
        elseif scene:tryBuildTech(techType) then
            scene.lastCreatedTech = now
            break
        end
    end
end

function scene:updatePlayer(deltaTime)
    local x = scene.mousePos.x
    local w = scene.objs.player.width

    x = math.max(w / 2, math.min(W - w / 2, x))

    scene.objs.player.x = x

    scene:tryBuildAnyTech()
end

function scene:onKey(event)
    if "1" <= event.keyName and event.keyName <= "4" then
        local num = tonumber(event.keyName)
        scene.pressedKeys[num] = event.phase == 'down'
    end
    return true
end

sceneInternals(scene)

return scene
