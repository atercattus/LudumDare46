return function(scene)
    local composer = require("composer")
    local utils = require("libs.utils")

    scene.mousePos = { x = -1, y = -1 }
    scene.updates = {} -- (scene, deltaTime)

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
        --local W, H = display.contentWidth, display.contentHeight
        scene.mousePos.x = event.x
        scene.mousePos.y = event.y
        --self.pressedKeys.mouseLeft = event.isPrimaryButtonDown
    end

    scene:addEventListener("create", scene)
    scene:addEventListener("show", function(event)
        composer.removeHidden() -- Выгружаю остальные сцены

        if (event.phase == "will") then
            Runtime:addEventListener("enterFrame", onEnterFrame)
            Runtime:addEventListener("mouse", onMouseEvent)
        end
    end)

    scene:addEventListener("hide", function(event)
        --if (event.phase == "did") then
        Runtime:removeEventListener("enterFrame", onEnterFrame)
        Runtime:removeEventListener("mouse", onMouseEvent)
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
