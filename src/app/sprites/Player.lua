Player = class("Player",  function()
    return display.newSprite()
end)

function Player:ctor(size)
    self.digEnabled = true
    
    self:initTouchListener()
    
    local scheduler = cc.Director:getInstance():getScheduler()
    scheduler:scheduleScriptFunc(handler(self, self.update), 1.0 / 60.0, false)
    
    local moveListener = cc.EventListenerCustom:create("enable_dig", function() self.digEnabled = true end)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(moveListener, self)
    
    self:setTexture('res/sprite/bingbing.png')
    self:setScale(size.width/self:getContentSize().width)
    self:setAnchorPoint(0.5,0.5)
    self:setPosition(display.cx, display.cy)
--    self:test()
end

function Player:update()
	
end

function Player:initTouchListener()

    --------------------------------------------
    local function onTouchBegan(touch, event)
        if not self.digEnabled then return end
        
        local touchPos = cc.p(touch:getLocation())
        
        --TODO:还有人物的移动呢，不只是dig
        local playerPos = self:convertToWorldSpaceAR(cc.p(0,0))
        local digDir
        if touchPos.y < playerPos.y - 180 then digDir = 'down'
        elseif touchPos.x < playerPos.x then digDir = 'left'
        else digDir = 'right'
        end
        
        local event = cc.EventCustom:new("dig_at")
        event.playerPos = playerPos
        event.digDir = digDir
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
        
        print(event.answer)
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