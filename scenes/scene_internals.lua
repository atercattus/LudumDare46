return function(scene)
    local composer = require("composer")
    local utils = require("libs.utils")

    scene.mousePos = {x=-1, y=-1}
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
        scene.mousePos.x = event.x -- - W / 2
        scene.mousePos.y = event.y -- - H / 2
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
        scene.updates[#scene.updates+1] = cb
    end

    function scene:update(deltaTime)
        for i = 1, #scene.updates do
            scene.updates[i](scene, deltaTime)
        end
        --for i = 1, #self.reqInFlight do
        --    local req = self.reqInFlight[i]
        --
        --    req.y = req.y + req.speed * deltaTime
        --    if req.y > H - const.BottomPanelHeight then
        --        req.y = const.TopPanelHeight - ReqHeight * ReqRenderScale / 2
        --    end
        --end
        --
        --for i = 1, #self.updates do
        --    self.updates[i](scene, deltaTime)
        --end
        --
        --local x = scene.mousePos.x
        --if x < 0 then
        --    x = W/2
        --end
        --scene.objs.player.x = x
    end


end
