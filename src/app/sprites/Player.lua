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
    
    self.oxygenVol = s_data.level[DataManager.get(DataManager.HPLV) + 1].hp
    self.deepth = 0
    self.score = 0
    self.coins = 0
    self.gems = 0
    self.digForce = s_data.level[DataManager.get(DataManager.POWERLV) + 1].power
    self.digThrough = false --是否具有贯穿特效，吃了栗子后，一次凿一整行整列

--    self:initTouchListener()
    
    local moveListener = cc.EventListenerCustom:create("Dropping", function(event) self.dropping = event.active end)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(moveListener, self)
    local pauseListener = cc.EventListenerCustom:create("pause game", handler(self,self.disableTouchListener))
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(pauseListener, self)
    local resumeListener = cc.EventListenerCustom:create("resume game", handler(self,self.initTouchListener))
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(resumeListener, self)
    local checkBossListener = cc.EventListenerCustom:create("boss_advance", handler(self,self.checkBossCapture))
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(checkBossListener, self)
    local castSkillListener = cc.EventListenerCustom:create("cast_skill", handler(self,self.castSkill))
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(castSkillListener, self)
    local castSkillListener = cc.EventListenerCustom:create("gain_prop", function (event) self:gainProp(event.element) end)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(castSkillListener, self)
    
    
    self:setTexture('res/sprite/bingbing.png')
    self:setScale(size.width/self:getContentSize().width)
    self:setAnchorPoint(0.5,0.5)
    self:setPosition(display.cx, size.height * BORN_HEIGHT)
    
    self.reduceOxygenTimer = self:getScheduler():scheduleScriptFunc(handler(self, self.reduceOxygen), 1, false)
    self:scheduleUpdateWithPriorityLua(handler(self, self.update), 0)

    coroutine.resume(coroutine.create(handler(self,self.increaseDeepth)))
end

function Player:unscheduleAllTimers()
    self:unscheduleUpdate()
    self:getScheduler():unscheduleScriptEntry(self.reduceOxygenTimer)
end

function Player:detectMap(dir)
    local event = cc.EventCustom:new("detect_map")
    event.playerPos = self:convertToWorldSpaceAR(cc.p(0,0))
    event.direction = dir
    cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
    
    return event.result, event.element
end

function Player:update()
    
    --是否需要掉落
    local down, el = self:detectMap('down')
    if down == 'empty' or (down == 'element' and el.m_needDigTime == 0) then self:drop() end
    
    --是否获取到道具或者被砖块砸到
    local center, el = self:detectMap('center')
    if center == 'element' then
        if el.m_type.isBrick then
            self:die()
        else
            self:gainProp(el)
        end
    end
end

function Player:gainProp(el)
    if el.m_type == elements.oxygen then
        print('oxygen')
        self.oxygenVol = self.oxygenVol + 10
        local topVol = s_data.level[DataManager.get(DataManager.HPLV) + 1].hp
        self.oxygenVol = topVol < self.oxygenVol and topVol or self.oxygenVol
        local event = cc.EventCustom:new("update hub")
        event.type = 'oxygen'
        event.data = self.oxygenVol
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
    elseif el.m_type == elements.silverDrill then
        print('silverDrill')
        self.digForce = self.digForce * 2
        self:performWithDelay(function() self.digForce = self.digForce / 2 end, 10)
    elseif el.m_type == elements.goldenDrill then
        print('goldenDrill')
        self.digForce = self.digForce * 4
        self:performWithDelay(function() self.digForce = self.digForce / 4 end, 10)
    elseif el.m_type == elements.box then
        print('box')
        local fakeBox = Element.new():create(el.m_row, el.m_col, elements.box)
        fakeBox.fsm_:doEvent("destroy")
        
        local types = {elements.coin, elements.gem, elements.goldenDrill, elements.oxygen, elements.punish}
        el.m_type = types[math.random(1,#types)]
        el:setSpriteFrame(el.m_type.texture)
        self:gainProp(el)

        return
    elseif el.m_type == elements.coin then
        print('coin')
        self.coins = self.coins + 1
        local event = cc.EventCustom:new("update hub")
        event.type = 'coin'
        event.data = self.coins
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
    elseif el.m_type == elements.gem then
        print('gem')
        self.gems = self.gems + 1
        local event = cc.EventCustom:new("update hub")
        event.type = 'gem'
        event.data = self.gems
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
    elseif el.m_type == elements.bomb then
        cc.BezierTo:create(t,points)
    elseif el.m_type == elements.timebomb then
    
    elseif el.m_type == elements.mushroom then
        DataManager.set(DataManager.ITEM_1, DataManager.get(DataManager.ITEM_1) + 1)
        local event = cc.EventCustom:new("update hub")
        event.type = 'skillMushroom'
        event.data = DataManager.get(DataManager.ITEM_1)
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
    elseif el.m_type == elements.nut then
        DataManager.set(DataManager.ITEM_2, DataManager.get(DataManager.ITEM_2) + 1)
        local event = cc.EventCustom:new("update hub")
        event.type = 'skillNut'
        event.data = DataManager.get(DataManager.ITEM_2)
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
    elseif el.m_type == elements.cola then
        DataManager.set(DataManager.ITEM_3, DataManager.get(DataManager.ITEM_3) + 1)
        local event = cc.EventCustom:new("update hub")
        event.type = 'skillCola'
        event.data = DataManager.get(DataManager.ITEM_3)
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
    elseif el.m_type == elements.toy then
    
    end
    
    local event = cc.EventCustom:new("remove_element")
    event.el = el
    cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
    
end

function Player:reduceOxygen()
    
    if self.oxygenVol >= 1 then
        self.oxygenVol = self.oxygenVol - 1
    else
        self.oxygenVol = 0
        self:die()
    end
    
    local event = cc.EventCustom:new("update hub")
    event.type = 'oxygen'
    event.data = self.oxygenVol
    cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
end


function Player:drop()
    if not self.dropping then
        self.dropping = true
        local event = cc.EventCustom:new("roll_map")
        event.playerPos = self:convertToWorldSpaceAR(cc.p(0,0))
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
    end
end

function Player:dig(target, dir)
    if self.digging then return end

    --播放dig动画
    self.digging = true
    self:runAction(cc.Sequence:create(
        cc.JumpBy:create(0.2, cc.p(0,0), 12, 6),
        cc.CallFunc:create(function() self.digging = false end)))
        

    local event = cc.EventCustom:new("dig_at")
    event.target = target
    event.playerPos = self:convertToWorldSpaceAR(cc.p(0,0))
    
    if self.digThrough then
        event.effect = dir
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
    else
        target.m_needDigTime = target.m_needDigTime - self.digForce
        if target.m_needDigTime > 0 then return end

        cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
    end
end

function Player:move(dir)
    assert(not self.moving,'player should\'nt moving')
    
    local delta
    local playerWidth = self.playerSize.width
    if 'left' == dir then
        delta = cc.p(-playerWidth,0)
    elseif 'right' == dir then
        delta = cc.p(playerWidth,0)
    end
    self.moving = true
    self:runAction(cc.Sequence:create(
        cc.MoveBy:create(0.4,delta),
        cc.CallFunc:create(function() self.moving = false end)))
end

function Player:die()
    if self.dead then return end
    
    print('die')
    self.dead = true
    self:disableTouchListener()
    
    self:runAction(cc.Spawn:create(
                        cc.ScaleTo:create(0.1,self.playerSize.width/self:getContentSize().width,0.1),
                        cc.JumpBy:create(0.1,cc.p(0,-35),16,6)
                        ))
    self:showSettlement()
end

function Player:rebirth()
    if not self.dead then return end
    
    print('rebirth')
    self.dead = false
    self.oxygenVol = s_data.level[DataManager.get(DataManager.HPLV) + 1].hp
    
    --激活触摸
    self:initTouchListener()

    --向上挖掘
    local temp = self.digThrough
    self.digThrough = true
    self:dig(nil, 'up')
    self.digThrough = temp

    --击退boss
    local event = cc.EventCustom:new("beat_back_boss")
    event.stepCnt = 6
    cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)

    --复活动画
    self:runAction(cc.Spawn:create(
        cc.ScaleTo:create(0.1,self.playerSize.width/self:getContentSize().width,self.playerSize.height/self:getContentSize().height),
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

    print('showSettlement')
    DataManager.set(DataManager.GOLD, DataManager.get(DataManager.GOLD) + self.coins)
    DataManager.set(DataManager.POINT, DataManager.get(DataManager.POINT) + self.gems)
    DataManager.set(DataManager.TOPGROUD, DataManager.get(DataManager.TOPGROUD) > self.score and DataManager.get(DataManager.TOPGROUD) or self.deepth)
    DataManager.set(DataManager.TOP_SCORE, DataManager.get(DataManager.TOP_SCORE) > self.score and DataManager.get(DataManager.TOP_SCORE) or self.score)
    
    self.restartBtn:setEnabled(true)
    self.restartBtn:runAction(cc.EaseBounceOut:create(cc.MoveBy:create(1,cc.p(0,-600))))
end

function Player:increaseDeepth()
    local current = coroutine.running()
    local perFloorDuration = gamePara.dropSpeed / 100 * self.playerSize.height
    
    while true do
        self:performWithDelay(function()
            coroutine.resume(current)
        end, perFloorDuration)
        
        if self.dropping then
            self.deepth = self.deepth+1
            self.score = self.score+10
            local event = cc.EventCustom:new("update hub")
            event.type = 'score'
            event.data = self.score
            cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
            local event = cc.EventCustom:new("update hub")
            event.type = 'deepth'
            event.data = self.deepth
            cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
        end
        
        coroutine.yield()
    end
end

function Player:handleTouch()
    if self.moving or self.dropping or self.digging
    then
        return
    end
    
    local type, element = self:detectMap(self.touchDir)
    if self.digThrough then
        self:dig(element, self.touchDir)
    elseif type == 'empty' then
        self:move(self.touchDir)
    elseif type == 'element' then
        if element.m_needDigTime == 0 then
            self:move(self.touchDir)
        else
        	self:dig(element, self.touchDir)
        end
    end
end

function Player:disableTouchListener()
    print('disableTouchListener')
    cc.Director:getInstance():getEventDispatcher():removeEventListener(self.touchListener)
end

function Player:initTouchListener()
    print('initTouchListener')
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

function Player:checkBossCapture(event)
    local bossPos = event.bossPos
    local distance = self:convertToNodeSpaceAR(bossPos)
    if distance.y < 0 then
    	self:die()
    end
end

function Player:castSkill(event)
    if event.skillType == elements.mushroom then
        if self.digThrough then return end
        
        local skillCnt = DataManager.get(DataManager.ITEM_1)
        if skillCnt <= 0 then return end
        DataManager.set(DataManager.ITEM_1, skillCnt - 1)
        local e = cc.EventCustom:new("update hub")
        e.type = 'skillMushroom'
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(e)
        
        self.digThrough = true
        self:performWithDelay(function() self.digThrough = false end, gamePara.propDuration)
    elseif event.skillType == elements.nut then
        local skillCnt = DataManager.get(DataManager.ITEM_2)
        if skillCnt <= 0 then return end
        DataManager.set(DataManager.ITEM_2, skillCnt - 1)
        local e = cc.EventCustom:new("update hub")
        e.type = 'skillNut'
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(e)
        
        local eShock = cc.EventCustom:new("shock_dizzy_boss")
        eShock.second = 5
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(eShock)
    elseif event.skillType == elements.cola then
        local skillCnt = DataManager.get(DataManager.ITEM_3)
        if skillCnt <= 0 then return end
        DataManager.set(DataManager.ITEM_3, skillCnt - 1)
        local e = cc.EventCustom:new("update hub")
        e.type = 'skillCola'
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(e)
        
    end

end