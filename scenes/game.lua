local composer = require("composer")
local utils = require("libs.utils")
local flowNew = require('libs.flow').new

local gameSetupUI = require('scenes.game_setup_ui')
local gameSetupLevel = require('scenes.game_setup_level')
local sceneInternals = require('scenes.scene_internals')

local const = require('scenes.game_constants')

local scene = composer.newScene()
local mathRandom = math.random
local W, H = display.contentWidth, display.contentHeight

--- UI ---

local UIReqMaxLegalSprites = 300 -- Можно сделать настройкой "качество графики" XD
local UIReqMaxFoodSprites = 500 -- Можно сделать настройкой "качество графики" XD
local UIReqMaxSpeed = 600
local UIReqSpeedupPerSecond = 1.1

local LegalQpsSpeedupPerSecond = 1.3
--local FloodQpsSpeedupPerSecond = 0.5

local TimeToFirstWave = mathRandom(10, 20)
local WaveDuration = { 10, 30 }
local IntervalBetweenWaves = { 20, 30 }
local WaveDensity = { 40, 95 }
local WaveFloodQpsIncrease = { 20, 100 } -- % от максимальной возможности системы

local OverheatDuration = 5 -- Через сколько секунд перегрева сгорит очередной сервер

function scene:create(event)
    W, H = display.contentWidth, display.contentHeight

    self.reqInFlight = {}
    self.panels = {}
    self.objs = {}
    self.state = {
        startedAt = utils.now(), -- Время начала (сек)
        money = const.StartMoney, -- Денег на счету (нужны для покупки серверов и средств защиты от DDoS)
        CPC = 4, -- Стоимость каждой 1000 легальных запросов, долетевших до сервера
        la = 0, -- Суммарная нагрузка на все сервера (зависит от суммарного qps, долетающего до серверов)
        serversCnt = 1, -- Общее количество работающих серверов (влияет на LA)
        serverMaxQps = 5000, -- Максимальный QPS, который может обработать один сервер
        legalQpsSpeedup = 1, -- Прирост self.flowLegal.emitQps в секунду
        floodQpsSpeedup = 0.2, -- Прирост self.flowFlood.emitQps в секунду
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

    self.levelGroup = display.newGroup()
    self.levelGroup.x = 0
    self.levelGroup.y = 0
    self.view:insert(self.levelGroup)

    gameSetupUI.init(self.view, self)

    gameSetupLevel.init(self.view, self)

    self:addUpdate(function(_, deltaTime)
        techsLogic:moveToTargetPositions(deltaTime)
        techsLogic:markAllUncollided()

        self.flowLegal:update(deltaTime)
        self.flowFlood:update(deltaTime)

        techsLogic.processBuyAds(deltaTime)
        techsLogic.processCollided()
    end)

    self:addUpdate(self.updatePlayer)

    -- Мигание лампочек на сервере
    scene:addTimer(timer.performWithDelay(100, function()
        utils.setNextFrame(self.objs.srvImg, self.objs.srvImg.fillFrameCnt)
    end, -1))

    -- Пожар
    scene:addTimer(timer.performWithDelay(150, function()
        utils.setNextFrame(self.objs.srvFireImg, self.objs.srvFireImg.fillFrameCnt)
    end, -1))

    scene:addTimer(timer.performWithDelay(300, function()
        scene:updateMoney()
    end, -1))

    scene:addTimer(timer.performWithDelay(500, self.updateLoadAverage, -1))

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

function scene.deleteFinished(reqType, cnt)
    local state = scene.state

    state.serverQueries = state.serverQueries + cnt

    if reqType == const.ReqTypeLegal then
        state.money = state.money + state.CPC * (cnt / 1000.0) -- CPC читаю за тысячу
    else
        -- просто паразитная нагрузка на сервера
    end
end

function scene:startWaveGenerator()
    self.waveX = 0
    self.waveDensity = 0
    self.waveWidth = W / 8

    self.waveFloodQpsBak = 0

    local makeWave
    makeWave = function(after)
        local t = timer.performWithDelay(after, function()
            local waveDuration = mathRandom(WaveDuration[1], WaveDuration[2])

            self.waveDensity = mathRandom(WaveDensity[1], WaveDensity[2]) / 100
            self.waveX = mathRandom(W - self.waveWidth) + self.waveWidth / 2

            -- Забиваем % канала
            local waveBandUsage = mathRandom(WaveFloodQpsIncrease[1], WaveFloodQpsIncrease[2]) / 100

            -- На первых этапах упрощаю жизнь, на поздних усложняю
            local waveMode = 'norm'
            local gameTime = utils.now()
            if gameTime < 60 then
                waveMode = 'easy'
                waveDuration = math.min(10, waveDuration)
                waveBandUsage = math.min(0.30, waveBandUsage)
            elseif gameTime > 5 * 60 then
                waveMode = 'hard'
                waveDuration = math.max(10, waveDuration)
                waveBandUsage = math.max(0.40, waveBandUsage) + 0.2 -- Может сделать > 100%
            end

            local waveQpsIncrease = self.state.serversCnt * (self.state.serverMaxQps * waveBandUsage)

            print('WAVE [' .. waveMode .. '] band:' .. (100 * waveBandUsage) .. '% density:' .. (100 * self.waveDensity) .. '%')

            self.waveFloodQpsBak = self.flowFlood.emitQps
            self.flowFlood.emitQps = waveQpsIncrease

            local t = timer.performWithDelay(waveDuration * 1000, function()
                self.waveDensity = 0

                self.flowFlood.emitQps = self.waveFloodQpsBak

                -- Готовлю следующую волну
                makeWave(mathRandom(IntervalBetweenWaves[1], IntervalBetweenWaves[2]) * 1000)
            end, 1)
            scene:addTimer(t)
        end, 1)
        scene:addTimer(t)
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

function scene:updateLoadAverage()
    local self = scene
    local state = self.state

    if self.updateLoadAverageLastCall == nil then
        self.updateLoadAverageLastCall = utils.now()
        return
    end
    local now = utils.now()
    local deltaTime = now - self.updateLoadAverageLastCall
    self.updateLoadAverageLastCall = now

    local qps = state.serverQueries / deltaTime
    state.serverQueries = 0

    state.la = math.min(146, 100 * qps / (state.serverMaxQps * state.serversCnt))
    self:updateLA()

    self.objs.srvFireImg.isVisible = (self.state.la >= 100)

    if self.state.la >= 100 then
        if self.overloadFrom == nil then
            self.overloadFrom = now
        end
        if now - self.overloadFrom > OverheatDuration then
            self.overloadFrom = now
            self:serversOverloaded()
        end
    else
        self.overloadFrom = nil
    end
end

function scene:serversOverloaded()
    local state = scene.state
    state.serversCnt = math.min(state.serversCnt - 1, math.floor(state.serversCnt * 0.8)) -- Сгорел на работе
    self:updateServersCount()

    if state.serversCnt <= 0 then
        composer.gotoScene('scenes.game_over')
    end
end

function scene:createFlowLegal()
    self.flowLegal = flowNew({
        emitQps = 1,
        maxInFly = UIReqMaxLegalSprites,
        reqSteps = ReqSteps,

        new = scene.flowNew,

        reset = scene.flowResetFunc(const.ReqTypeLegal),

        deleteFinished = function(cnt)
            self.deleteFinished(const.ReqTypeLegal, cnt)
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
        maxInFly = UIReqMaxFoodSprites,
        reqSteps = ReqSteps,

        new = scene.flowNew,

        reset = scene.flowResetFunc(const.ReqTypeFlood),

        deleteFinished = function(cnt)
            self.deleteFinished(const.ReqTypeFlood, cnt)
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

function scene:tryBuildTech(techType)
    if techType ~= const.TechBuyAds then
        local player = scene.objs.player

        local tech = techsLogic.newTech(self.view, techType, true)
        tech.x = player.x
        tech.y = player.y
        tech.speedY = -H / 2
        -- ToDo: tech.techDurability умножать на текущую ситуацию, чтобы становилось сильнее со временем

    elseif scene.objs.adsTech == nil then
        -- Немного рандома в эту жизнь
        local qpsScale
        if mathRandom() >= 0.95 then
            qpsScale = 10 -- Может повезло, а может и нет :)
        else
            qpsScale = mathRandom(2, 8)
        end

        local tech = techsLogic.newTech(self.view, techType, true, function(t)
            scene.objs.adsTech = nil
            scene.flowLegal.emitQps = scene.flowLegal.emitQps / qpsScale
        end)

        tech.x = W / 2
        tech.y = const.TopPanelHeight + tech.height / 2
        tech.speedY = 0
        tech.qpsScale = qpsScale
        scene.objs.adsTech = tech

        scene.flowLegal.emitQps = scene.flowLegal.emitQps * qpsScale
    else
        return false
    end

    return true
end

function scene:tryBuildAnyTech()
    local money = scene.state.money

    local now = system.getTimer()
    if scene.lastCreatedTech == nil then
        scene.lastCreatedTech = 0
    end

    local buyCooldown = 250

    for techType, techCost in ipairs(const.TechCosts) do
        if money < techCost then
        elseif not scene.pressedKeys[techType] then
        elseif (now - scene.lastCreatedTech) < buyCooldown then
            return
        elseif scene:tryBuildTech(techType) then
            scene.lastCreatedTech = now

            scene.state.money = scene.state.money - techCost
            return
        end
    end

    if scene.pressedKeys.space and (money >= const.NewServerCost) then
        if (now - scene.lastCreatedTech) > buyCooldown then
            scene.lastCreatedTech = now
            scene.state.money = scene.state.money - const.NewServerCost
            scene.state.serversCnt = scene.state.serversCnt + 1
            scene:updateServersCount()
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
    if event.keyName == 'space' then
        scene.pressedKeys.space = event.phase == 'down'
    end
    return true
end

sceneInternals.init(scene)

return scene
