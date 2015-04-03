require("app.layers.PlayLayer")
require("app.sprites.Element")
require("app.sprites.Player")

local GameScene = class("GameScene", function()
    return display.newScene("GameScene")
end)

function GameScene:ctor()
    local playLayer = PlayLayer.new()
    local player = Player.new()
    self:addChild(playLayer)
    self:addChild(player)
end

function GameScene:onEnter()
end

function GameScene:onExit()
end

return GameScene
