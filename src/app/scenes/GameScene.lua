require("app.sprites.Element")
require("app.layers.PlayLayer")

local GameScene = class("GameScene", function()
    return display.newScene("GameScene")
end)

function GameScene:ctor()
    self:addChild(PlayLayer.new())
end

function GameScene:onEnter()
end

function GameScene:onExit()
end

return GameScene
