Player = class("Player",  function()
    return display.newSprite()
end)
local BORN_HEIGHT = 5.5  --人物诞生时候的位置，BORN_HEIGHT个元素的高度。确保出生在某个元素位置。则移动，降落时都按照整行整列计算，就能保确保人物位置一直在某元素的位置。
function Player:ctor(size)
    self.moving = false
    self.dropping = false
    self.digging = false
    self.dead = false
    self.playerSize = size
    
    self:initTouchListener()
    
    local scheduler = cc.Director:getInstance():getScheduler()
    scheduler:scheduleScriptFunc(handler(self, self.update), 1.0 / 60.0, false)
    
    local moveListener = cc.EventListenerCustom:create("Dropping", function(event) self.dropping = event.active end)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(moveListener, self)
    
    self:setTexture('res/sprite/bingbing.png')
    self:setScale(size.width/self:getContentSize().width)
    self:setAnchorPoint(0.5,0.5)
    self:setPosition(display.cx, size.height * BORN_HEIGHT)
    
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
    if env.down == nil then self:drop() end
    if env.center ~= nil then self:die() end
end

function Player:drop()
    if not self.dropping then
        self.dropping = true
        local event = cc.EventCustom:new("roll_map")
        event.playerPos = self:convertToWorldSpaceAR(cc.p(0,0))
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
    end
end

function Player:dig(target)
    if self.digging then return end
    
    local event = cc.EventCustom:new("dig_at")
--    event.playerPos = self:convertToWorldSpaceAR(cc.p(0,0))
    event.target = target
    cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
    
    self.digging = true
    self:runAction(cc.Sequence:create(
        cc.JumpBy:create(0.2, cc.p(0,0), 12, 6),
        cc.CallFunc:create(function() self.digging = false end)))
end

function Player:move()
    assert(not self.moving,'player should\'nt moving')
    
    local delta
    local playerWidth = self.playerSize.width
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
    if self.dead then return end
    
    print('die')
    self.dead = true
    cc.Director:getInstance():getEventDispatcher():removeEventListener(self.touchListener)
    
    self:runAction(cc.Spawn:create(
                        cc.ScaleTo:create(0.1,1,0.1),
                        cc.JumpBy:create(0.1,cc.p(0,-35),16,6)
                        ))
    self:showSettlement()
end

function Player:rebirth()
    if not self.dead then return end
    
    print('rebirth')
    self.dead = false
--    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(self.touchListener, self)
    self:initTouchListener()

    local env = self:detectMap()
    if env.center then self:dig(env.center) end

    self:runAction(cc.Spawn:create(
        cc.ScaleTo:create(0.1,1,self.playerSize.height/self:getContentSize().height),
        cc.JumpBy:create(0.3,cc.p(0,35),16,6)
    ))

end

function Player:showSettlement()
    if not self.restartBtn then

        local function btnCallback(node, type)
            if type == cc.CONTROL_EVENTTYPE_TOUCH_DOWN then
                print('HideSettlement')
                node:setEnabled(false)
                self.restartBtn:runAction(cc.Sequence:create(cc.EaseBounceIn:create(cc.MoveBy:create(1,cc.p(0,600))),
                                                            cc.CallFunc:create(function()
                                                                self:rebirth()
                                                            end)))
            end
        end

        local btn = cc.ControlButton:create("RESTART","Times New Roman",60)
        btn:setPosition(display.cx,display.cy+600)
        self:getParent():addChild(btn)
        self.restartBtn = btn

        -- 按钮事件回调
        btn:registerControlEventHandler(btnCallback,cc.CONTROL_EVENTTYPE_TOUCH_DOWN)
        btn:registerControlEventHandler(btnCallback,cc.CONTROL_EVENTTYPE_DRAG_INSIDE)
        btn:registerControlEventHandler(btnCallback,cc.CONTROL_EVENTTYPE_TOUCH_UP_INSIDE)
    end

--    self.restartBtn:runAction(cc.Sequence:create(cc.EaseOut:create(cc.MoveBy:create(1,cc.p(0,-600)),1),
--        cc.CallFunc:create(function()
--            self:rebirth()
--        end)))
        
    print('showSettlement')
    self.restartBtn:setEnabled(true)
    self.restartBtn:runAction(cc.EaseBounceOut:create(cc.MoveBy:create(1,cc.p(0,-600))))
--    var actionTo = cc.MoveTo.create(2, cc.p(winsize.width-200, winsize.height-220)).easing(cc.easeElasticOut());
end

function Player:handleTouch()
    if self.moving or self.dropping or self.digging
    then
        return
    end
    
    local env = self:detectMap()
    if 'left' == self.touchDir then
        if env.left == nil then self:move()
        else self:dig(env.left)
        end
    elseif 'right' == self.touchDir then
        if env.right == nil then self:move()
        else self:dig(env.right) end
    elseif 'down' == self.touchDir then
        self:dig(env.down)
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
    self.touchListener = touchListener
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