local M = {}

local const = require('scenes.game_constants')

local options = {
    width = 256,
    height = 32,
    numFrames = 5,
}
local panelsImageSheet = graphics.newImageSheet("data/panels.png", options)

function M.newPanel(parent, techType)
    local panel = display.newRect(0, 0, 256, 32)
    panel.fill = { type = "image", sheet = panelsImageSheet, frame = techType }
    panel.anchorX = 0.5
    panel.anchorY = 0.5
    parent:insert(panel)

    return panel
end

function M.collideReqWithPanel(req, panel)
    if req.reqType ~= const.ReqTypeLegal then
        req.isVisible = false
    end
end

return M