local M = {}

function M.init(scene)
    local composer = require("composer")
    local utils = require("libs.utils")

    scene.mousePos = { x = -1, y = -1 }
    scene.updates = {} -- (scene, deltaTime)

    scene.pressedKeys = {}

    scene.timers = {}

    function scene:addTimer(timerId)
        scene.timers[#scene.timers + 1] = timerId
    end

    function scene:onEnterFrame(event)
        local deltaTime = utils.getDeltaTime(event.time)
        if deltaTime > 0 then
            self:update(deltaTime)
        end
    end

    local function onEnterFrame(event)
        scene:onEnterFrame(event)
    end

    local function onMouseEvent(event)
        scene.mousePos.x = event.x
        scene.mousePos.y = event.y
        --self.pressedKeys.mouseLeft = event.isPrimaryButtonDown
    end

    local function onKey(event)
        if scene.onKey ~= nil then
            scene:onKey(event)
        end
    end

    scene:addEventListener("create", scene)
    scene:addEventListener("show", function(event)
        composer.removeHidden(true) -- Выгружаю остальные сцены

        if (event.phase == "will") then
            Runtime:addEventListener("enterFrame", onEnterFrame)
            Runtime:addEventListener("mouse", onMouseEvent)
            Runtime:addEventListener("key", onKey)
        end
    end)

    scene:addEventListener("hide", function(event)
        for _, t in next, scene.timers do
            timer.cancel(t)
        end
        scene.timers = {}

        --if (event.phase == "did") then
        Runtime:removeEventListener("enterFrame", onEnterFrame)
        Runtime:removeEventListener("mouse", onMouseEvent)
        Runtime:removeEventListener("key", onKey)
        --end
    end)

    function scene:addUpdate(cb)
        scene.updates[#scene.updates + 1] = cb
    end

    function scene:update(deltaTime)
        for i = 1, #scene.updates do
            scene.updates[i](scene, deltaTime)
        end
    end
end

return M
