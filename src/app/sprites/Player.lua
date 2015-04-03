Player = class("Player",  function()
    return display.newSprite()
end)

function Player:ctor()
    self.digEnabled = true
    
    self:initTouchListener()
    
    local scheduler = cc.Director:getInstance():getScheduler()
    scheduler:scheduleScriptFunc(handler(self, self.update), 1.0 / 60.0, false)
    
    local moveListener = cc.EventListenerCustom:create("enable_dig", function() self.digEnabled = true end)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(moveListener, self)
    
    self:setTexture('res/sprite/bingbing.png')
    self:setPosition(display.cx, display.cy)
--    self:test()
end

function Player:update()
	
end

function Player:initTouchListener()

    --------------------------------------------
    local function onTouchBegan(touch, event)
        local location = cc.p(touch:getLocation())
        
        --TODO:还有人物的移动呢，不只是dig
        local playerPos
        local digDir
        
        local event = cc.EventCustom:new("dig_at")
        event.playerPos = playerPos
        event.digDir = digDir
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
        self.digEnabled = false
        return true
    end

    --------------------------------------------
    local function onTouchMoved(touch, event)
    end

    --------------------------------------------
    local function onTouchEnded(touch, event)
    end 

    --------------------------------------------
    local touchListener = cc.EventListenerTouchOneByOne:create()
    touchListener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
    touchListener:registerScriptHandler(onTouchMoved, cc.Handler.EVENT_TOUCH_MOVED)
    touchListener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
    local dispatcher = cc.Director:getInstance():getEventDispatcher()
    dispatcher:addEventListenerWithSceneGraphPriority(touchListener, self)
end

function Player:test()

    self:runAction(cc.Sequence:create(

            cc.DelayTime:create(2),
            cc.CallFunc:create(function()
                local eventDispatcher = cc.Director:getInstance():getEventDispatcher()

                local event = cc.EventCustom:new("move_map_up")
                event.dest = cc.p(0,200)
                eventDispatcher:dispatchEvent(event)
                
                local event = cc.EventCustom:new("add_line")
                event.cnt = 3
                eventDispatcher:dispatchEvent(event) 
            end)
    ))
end