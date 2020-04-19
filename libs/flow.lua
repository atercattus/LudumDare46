local M = {}

local poolNew = require('libs.pool').new
local const = require('scenes.game_constants')
local utils = require("libs.utils")

local tableRemove = utils.tableRemove

function M.new(options)
    local F = {}

    local UIReqMaxNewPerCall = 4

    local cbNew = options.new -- Создание нового объекта
    local cbReset = options.reset -- Перемещение объекта в начальную позицию (может вызываться многократно после одного new)
    local cbDeleteFinished = options.deleteFinished -- Событие при удалении пачки объектов, достигнувших низа
    local cbUpdate = options.update -- На случай, есть внешнему коду нужно выполнить обработку после отрисовки кадра
    local cbCollision = options.collision -- Обработка столкновения
    local ReqSteps = options.reqSteps -- Сколько всего размеров в тайлмапе (специфика это игрушки)

    F.maxInFly = options.maxInFly or 10000 -- Максимальное число спрайтов
    F.emitQps = options.emitQps or 0 -- QPS на создание новых объектов

    local inFly = {}
    local pool = poolNew(cbNew)

    function F:initNew(visualCnt, realCnt)
        local obj = pool:get()
        cbReset(obj, visualCnt, realCnt)
        obj.isVisible = true
        obj.lastCollisionWith = nil
        inFly[#inFly + 1] = obj
        return obj
    end

    function F:getInFly()
        return inFly
    end

    function F:update(deltaTime)
        F:updatePositions(deltaTime)
        F:updateCreateNew(deltaTime)

        if cbUpdate ~= nil then
            cbUpdate(deltaTime)
        end
    end

    function F:updatePositions(deltaTime)
        local W, H = display.contentWidth, display.contentHeight

        local toDelete = {}
        local toDeleteObjs = {}

        local finishedRealCnt = 0

        for i, obj in next, inFly do
            if (math.random() < 0.5) and (cbCollision ~= nil) then
                local collision = techsLogic.findCollision(obj, obj.lastCollisionWith)
                if (collision ~= nil) then
                    obj.lastCollisionWith = collision
                    if cbCollision(obj, collision) then
                        toDelete[#toDelete + 1] = i
                        toDeleteObjs[#toDeleteObjs + 1] = obj

                        local cnt = obj.reqCnt or 1
                        techsLogic.applyDamage(collision, cnt)
                    end
                end
            end

            obj.y = obj.y + obj.speed * deltaTime
            if obj.y > H - const.BottomPanelHeight then
                toDelete[#toDelete + 1] = i
                toDeleteObjs[#toDeleteObjs + 1] = obj

                if obj.reqCnt then
                    finishedRealCnt = finishedRealCnt + obj.reqCnt
                end
            end
        end

        if #toDelete > 0 then
            for i = #toDelete, 1, -1 do
                local obj = inFly[toDelete[i]]
                tableRemove(inFly, toDelete[i])
                pool:put(obj)
                obj.isVisible = false
            end

            if finishedRealCnt > 0 and cbDeleteFinished ~= nil then
                cbDeleteFinished(finishedRealCnt)
            end
        end
    end

    function F:updateCreateNew(deltaTime)
        if F.newReqsAccum == nil then
            -- Для очень низкого QPS позволяет создавать запросы раз в несколько вызовов, накапливая дробный счетчик
            F.newReqsAccum = 0
        end

        if #inFly > F.maxInFly then
            -- Ограничение на число отрисовываемых спрайтов
            return
        end

        local cntFloat = F.newReqsAccum + (F.emitQps * deltaTime)
        local cnt = math.floor(cntFloat)
        F.newReqsAccum = cntFloat - cnt
        if cnt <= 0 then
            return
        end

        local realCnt = cnt

        cnt = math.min(cnt, UIReqMaxNewPerCall)
        for _ = 1, cnt do
            local thisReqRealCnt = realCnt / cnt
            local step = math.min(ReqSteps, math.max(1, math.round(thisReqRealCnt / 10)))
            F:initNew(step, thisReqRealCnt)
        end
    end

    return F
end

return M
