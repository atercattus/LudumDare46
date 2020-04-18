return function(scene)
    local display = display
    local W, H = display.contentWidth, display.contentHeight
    local self = scene

    function scene:setupLevelPlayer()

    end

    self.levelGroup = display.newGroup()
    self.levelGroup.x = 0
    self.levelGroup.y = 0
    self.view:insert(self.levelGroup)

    self:setupLevelPlayer()
end
