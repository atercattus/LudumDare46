return function(scene)
    function scene:setupUI()
        local bg = display.newRect(self.view, 0, 0, W, H)
        bg.anchorX = 0
        bg.anchorY = 0
        bg:setFillColor(0, 0, 0)

        self:setupUITopPanel()
        self:setupUIBottomPanel()
    end

    function scene:setupUITopPanel()

    end

    function scene:setupUIBottomPanel()

    end
end
