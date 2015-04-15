require("app.layers.PlayLayer")
require("app.layers.BackgroundLayer")
require("app.layers.PauseLayer")
require("app.layers.HubLayer")
require("app.sprites.Element")
require("app.sprites.Player")
require("app.sprites.Boss")

local GameLayer = class("GameLayer", function()
    return display.newLayer("GameLayer")
end)

function GameLayer:ctor()
    local backgroudLayer = BackgroundLayer.new()
    backgroudLayer:setPosition(display.left,display.bottom)
    backgroudLayer:setAnchorPoint(0,0)
    self:addChild(backgroudLayer)
    
    local playLayer = PlayLayer.new()
    self:addChild(playLayer)
    
    local hubLayer = HubLayer.new()
    self:addChild(hubLayer)
    
    self.pauseLayer = PauseLayer.new()
    self:addChild(self.pauseLayer)
    self.pauseLayer:setVisible(false)
    
    local pauseListener = cc.EventListenerCustom:create("pause game", handler(self,self.pauseGame))
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(pauseListener, self)
end

function GameLayer:pauseGame()
    local queue = {self}
    while #queue > 0 do
        local nodes = queue[1]:getChildren()
    	for _, node in ipairs(nodes) do
            if node == self.pauseLayer then
                node:setVisible(true)
            else
                table.insert(queue,node)
            end
    	end
        queue[1]:pause()
    	table.remove(queue,1)
    end
end

return GameLayer
