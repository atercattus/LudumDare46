return function(scene)
    local composer = require("composer")
    local utils = require("libs.utils")

    local function onEnterFrame(event)
        scene:onEnterFrame(event)
    end

    scene:addEventListener("create", scene)
    scene:addEventListener("show", function(event)
        composer.removeHidden() -- Выгружаю остальные сцены

        if (event.phase == "will") then
            Runtime:addEventListener("enterFrame", onEnterFrame)
        end
    end)

    scene:addEventListener("hide", function(event)
        --if (event.phase == "did") then
        Runtime:removeEventListener("enterFrame", onEnterFrame)
        --end
    end)

    function scene:onEnterFrame(event)
        local deltaTime = utils.getDeltaTime(event.time)
        if deltaTime > 0 then
            self:update(deltaTime)
        end
    end
end
