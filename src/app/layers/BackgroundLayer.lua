BackgroundLayer = class("BackgroundLayer",  function()
    return display.newLayer("BackgroundLayer")
end)
local FAR_SPEED     = 80
local MIDDLE_SPEED  = 120
function BackgroundLayer:ctor()
    self.needScroll = false
        
    self.farBgs = {}
    self.middleBgs = {}

    self:createBackgrounds()

    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, handler(self, self.scrollBackgrounds))
    self:scheduleUpdate()
    
    local scrollListener = cc.EventListenerCustom:create("Dropping", function(event) self.needScroll = event.active end)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(scrollListener, self)
end

function BackgroundLayer:createBackgrounds()
    local farBg1 = display.newSprite("ui/background_far.png")
        :align(display.BOTTOM_LEFT, display.left , display.bottom)
        :addTo(self)
    local farBg2 = display.newSprite("ui/background_far.png")
        :align(display.TOP_LEFT, display.left , display.bottom - farBg1:getContentSize().height)
        :addTo(self)
    farBg2:setScaleY(-1)
        
    local middleBg1 = display.newSprite("ui/background_middle.png")
        :align(display.BOTTOM_LEFT, display.left , display.bottom)
        :addTo(self)
    local middleBg2 = display.newSprite("ui/background_middle.png")
        :align(display.TOP_LEFT, display.left , display.bottom - middleBg1:getContentSize().height)
        :addTo(self)
    middleBg2:setScaleY(-1)

    table.insert(self.farBgs, farBg1)
    table.insert(self.farBgs, farBg2)
    table.insert(self.middleBgs, middleBg1)
    table.insert(self.middleBgs, middleBg2)

end

function BackgroundLayer:scrollBackgrounds(dt)
    if not self.needScroll then return end

    local function ajustBgs(bgs, distance)
        if bgs[2]:getPositionY() >= 0 then
            bgs[1]:setPositionY(bgs[2]:getPositionY() - bgs[2]:getContentSize().height)
            bgs[1], bgs[2] = bgs[2], bgs[1]
        end

        bgs[1]:setPositionY(bgs[1]:getPositionY() + distance)
        bgs[2]:setPositionY(bgs[2]:getPositionY() + distance)
    end
    ajustBgs(self.farBgs, FAR_SPEED*dt)
    ajustBgs(self.middleBgs, MIDDLE_SPEED*dt)
end