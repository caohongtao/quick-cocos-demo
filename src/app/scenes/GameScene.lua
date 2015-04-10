require("app.layers.PlayLayer")
require("app.layers.BackgroundLayer")
require("app.layers.HubLayer")
require("app.sprites.Element")
require("app.sprites.Player")

local GameScene = class("GameScene", function()
    return display.newScene("GameScene")
end)

function GameScene:ctor()
    local backgroudLayer = BackgroundLayer.new()
    backgroudLayer:setPosition(display.left,display.bottom)
    backgroudLayer:setAnchorPoint(0,0)
    self:addChild(backgroudLayer)
    
--    local playLayer = PlayLayer.new()
--    self:addChild(playLayer)
    
    local hubLayer = HubLayer.new()
    self:addChild(hubLayer)
end

function GameScene:onEnter()
end

function GameScene:onExit()
end

return GameScene
