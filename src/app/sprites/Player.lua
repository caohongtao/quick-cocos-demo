Player = class("Player",  function()
    return display.newSprite()
end)

function Player:ctor(size)
    self.moving = false
    self.dropping = false
    self.digging = false
    
    self:initTouchListener()
    
    local scheduler = cc.Director:getInstance():getScheduler()
    scheduler:scheduleScriptFunc(handler(self, self.update), 1.0 / 60.0, false)
    
    local moveListener = cc.EventListenerCustom:create("Dropping", function(event) self.dropping = event.active end)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(moveListener, self)
    
    self:setTexture('res/sprite/bingbing.png')
    self:setScale(size.width/self:getContentSize().width)
    self:setAnchorPoint(0.5,0.5)
    self:setPosition(display.cx, display.cy)
    
    scheduler:scheduleScriptFunc(handler(self, self.update), 1.0 / 60.0, false)
--    self:test()
end

function Player:detectMap()
    local event = cc.EventCustom:new("detect_map")
    event.playerPos = self:convertToWorldSpaceAR(cc.p(0,0))
    cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
    
    return event.env
end

function Player:update()
    local env = self:detectMap()
    if env.down == 'empty' then self:drop() end
    if env.center == 'element' then self:die() end
     
end

function Player:drop()
    if not self.dropping then
        self.dropping = true
        local event = cc.EventCustom:new("roll_map")
        event.playerPos = self:convertToWorldSpaceAR(cc.p(0,0))
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
    end
end

function Player:dig()
    assert(not self.digging,'player should\'nt digging')
    
    local event = cc.EventCustom:new("dig_at")
    event.playerPos = self:convertToWorldSpaceAR(cc.p(0,0))
    event.digDir = self.touchDir
    cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
    
    self.digging = true
    self:runAction(cc.Sequence:create(
        cc.JumpBy:create(0.2, cc.p(0,0), 12, 6),
        cc.CallFunc:create(function() self.digging = false end)))
end

function Player:move()
    assert(not self.moving,'player should\'nt moving')
    
    local delta
    local playerWidth = self:getContentSize().width*self:getScale()
    if 'left' == self.touchDir then
        delta = cc.p(-playerWidth,0)
    elseif 'right' == self.touchDir then
        delta = cc.p(playerWidth,0)
    end
    self.moving = true
    self:runAction(cc.Sequence:create(
        cc.MoveBy:create(0.2,delta),
        cc.CallFunc:create(function() self.moving = false end)))
end

function Player:die()
    print("dead")
end

function Player:handleTouch()
    if self.moving or self.dropping or self.digging
    then
        return
    end
    
    local env = self:detectMap()
    if 'left' == self.touchDir then
        if env.left == "element" then
        	self:dig()
        elseif env.left == "empty" then
            self:move()
        end
    elseif 'right' == self.touchDir then
        if env.right == "element" then
            self:dig()
        elseif env.right == "empty" then
            self:move()
        end
    elseif 'down' == self.touchDir then
        self:dig()
    end 
    
    
    
--    local event = cc.EventCustom:new("dig_at")
--    event.playerPos = self:convertToWorldSpaceAR(cc.p(0,0))
--    event.digDir = self.touchDir
--    cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
    
--    if 'empty' == event.result then
--        local delta
--        local playerWidth = self:getContentSize().width*self:getScale()
--        if 'left' == self.touchDir then
--            delta = cc.p(-playerWidth,0)
--        elseif 'right' == self.touchDir then
--            delta = cc.p(playerWidth,0)
----        elseif 'down' == self.touchDir then
----            delta = cc.p(0,-12)
--        end
--        self.moving = true
--        self:runAction(cc.Sequence:create(
--            cc.MoveBy:create(0.2,delta),
--            cc.CallFunc:create(function()
--                self.moving = false
----            
----                local event = cc.EventCustom:new("roll_map")
----                event.playerPos = self:convertToWorldSpaceAR(cc.p(0,0))
----                cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
--            end)))
--        
--    elseif 'element' == event.result then
--        --播放动画
--        self.digging = true
--        self:runAction(cc.Sequence:create(
--            cc.JumpBy:create(0.2, cc.p(0,0), 12, 6),
--            cc.CallFunc:create(function() self.digging = false end)))
--    elseif 'wall' == event.result then
--        
--    end
end

function Player:initTouchListener()

    --------------------------------------------
    local function onTouchBegan(touch, event)
--        self.moving = true
        
        local touchPos = cc.p(touch:getLocation())
        local playerPos = self:convertToWorldSpaceAR(cc.p(0,0))

        if touchPos.y < playerPos.y - 60 then self.touchDir = 'down'
        elseif touchPos.x < playerPos.x then self.touchDir = 'left'
        else self.touchDir = 'right'
        end
        
        self:handleTouch()
        return true
    end

    --------------------------------------------
    local function onTouchMoved(touch, event)
--        local touchPos = cc.p(touch:getLocation())
--        local playerPos = self:convertToWorldSpaceAR(cc.p(0,0))
--
--        if touchPos.y < playerPos.y - 180 then self.touchDir = 'down'
--        elseif touchPos.x < playerPos.x then self.touchDir = 'left'
--        else self.touchDir = 'right'
--        end
        return true
    end

    --------------------------------------------
    local function onTouchEnded(touch, event)
--        self.moving = false
        return
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