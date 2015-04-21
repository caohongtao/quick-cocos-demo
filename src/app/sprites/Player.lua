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
    self.toys = 0
    self.digForce = s_data.level[DataManager.get(DataManager.POWERLV) + 1].power
    self.digThrough = false --是否具有贯穿特效，吃了栗子后，一次凿一整行整列

    local moveListener = cc.EventListenerCustom:create("Dropping", function(event) self.dropping = event.active end)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(moveListener, self)
    local checkBossListener = cc.EventListenerCustom:create("boss_advance", handler(self,self.checkBossCapture))
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(checkBossListener, self)
    local castSkillListener = cc.EventListenerCustom:create("cast_skill", handler(self,self.castSkill))
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(castSkillListener, self)
    local castSkillListener = cc.EventListenerCustom:create("gain_prop", function (event) self:gainProp(event.element) end)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(castSkillListener, self)
    local handleTouchListener = cc.EventListenerCustom:create("handle_touch", function (event) self:handleTouch(event.touchDir) end)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(handleTouchListener, self)
    local rebirthListener = cc.EventListenerCustom:create("player rebirth", handler(self,self.rebirth))
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(rebirthListener, self)
    
    
    cc.SpriteFrameCache:getInstance():addSpriteFrames('sprite/player.plist', 'sprite/player.png')
    self:setSpriteFrame('yanshu0001.png')
    self:setScale(size.width/self:getContentSize().width)
    self:setAnchorPoint(0.5,0.5)
    self:setPosition(display.cx, size.height * BORN_HEIGHT)
    self:addAnimation()
    
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
--        cc.BezierTo:create(t,points)
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
        self.toys = self.toys + 1
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

local DIG_DURATION = 0.3
function Player:dig(target, dir)
    if not self.digThrough and self.digging then return end --self.digThrough == true时(复活或者放可乐救命时)，即使上个挖掘动作没玩，也立即挖掘，否则不能往上挖掘，不断死亡。

    --播放dig动画
    self.digging = true
    transition.playAnimationOnce(self, display.getAnimationCache("player-dig"))
    self:runAction(cc.Sequence:create(
        cc.DelayTime:create(DIG_DURATION),
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
    self.dead = true
    
    self:runAction(cc.Sequence:create(cc.Spawn:create(
--                                        cc.ScaleTo:create(0.1,self.playerSize.width/self:getContentSize().width,0.1),
                                        cc.ScaleBy:create(0.2,0.01),
                                        cc.RotateBy:create(0.2,360)
--                                        cc.JumpBy:create(0.1,cc.p(0,-0),16,6)
                                        ),
                                  cc.CallFunc:create(function()
                                        local dieEvent = cc.EventCustom:new("player die")
                                        cc.Director:getInstance():getEventDispatcher():dispatchEvent(dieEvent)
                                  end)))
end

function Player:rebirth()
    if not self.dead then return end
    
    self.dead = false
    self.oxygenVol = s_data.level[DataManager.get(DataManager.HPLV) + 1].hp

    --向上挖掘
    local temp = self.digThrough
    self.digThrough = true
    self:dig(nil, 'up')
    self.digThrough = temp

    --击退boss
    local event = cc.EventCustom:new("beat_back_boss")
    event.stepCnt = 3*gamePara.bossRecedeSteps
    cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)

    --复活动画
    self:runAction(cc.Spawn:create(
--        cc.ScaleTo:create(0.1,self.playerSize.width/self:getContentSize().width,self.playerSize.height/self:getContentSize().height),
        cc.ScaleBy:create(0.2,100,100),
        cc.RotateBy:create(0.2,-360)
--        cc.JumpBy:create(0.3,cc.p(0,0),16,6)
    ))

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

function Player:handleTouch(touchDir)
    if self.moving or self.dropping or self.digging
    then
        return
    end
    
    local type, element = self:detectMap(touchDir)
    if self.digThrough then
        self:dig(element, touchDir)
    elseif type == 'empty' then
        self:move(touchDir)
    elseif type == 'element' then
        if element.m_needDigTime == 0 then
            self:move(touchDir)
        else
        	self:dig(element, touchDir)
        end
    end
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
        local skillCnt = DataManager.get(DataManager.ITEM_1)
        if skillCnt <= 0 then return end
        DataManager.set(DataManager.ITEM_1, skillCnt - 1)
        local e = cc.EventCustom:new("update hub")
        e.type = 'skillMushroom'
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(e)

        local fart = cc.ParticleSmoke:create()
        fart:setPosition(60,200)
        self:addChild(fart,10)
        fart:runAction(cc.Sequence:create(
            cc.ScaleBy:create(1, 10, 20),
            cc.CallFunc:create(function()
                local eShock = cc.EventCustom:new("shock_dizzy_boss")
                eShock.second = gamePara.bossDizzyTime
                cc.Director:getInstance():getEventDispatcher():dispatchEvent(eShock)
            end),
            cc.FadeOut:create(1),
            cc.CallFunc:create(function()
                fart:removeFromParent(true)
            end)))

    elseif event.skillType == elements.nut then
        if self.digThrough then return end

        local skillCnt = DataManager.get(DataManager.ITEM_2)
        if skillCnt <= 0 then return end
        DataManager.set(DataManager.ITEM_2, skillCnt - 1)
        local e = cc.EventCustom:new("update hub")
        e.type = 'skillNut'
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(e)

        self.digThrough = true
        if not self.digThroughEffect then
            self.digThroughEffect = cc.ParticleFlower:create()
            self.digThroughEffect:setPosition(80,60)
            self:addChild(self.digThroughEffect)
        end
        self.digThroughEffect:setVisible(true)
        self:performWithDelay(function()
            self.digThrough = false
            self.digThroughEffect:setVisible(false)
        end, gamePara.propDuration)
    elseif event.skillType == elements.cola then
        local skillCnt = DataManager.get(DataManager.ITEM_3)
        if skillCnt <= 0 then return end
        DataManager.set(DataManager.ITEM_3, skillCnt - 1)
        local e = cc.EventCustom:new("update hub")
        e.type = 'skillCola'
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(e)
        
        local cola = display.newSprite('#cola.png',40,40)
        cola:setScale(3)
        cola:addTo(self)
        local paticle = cc.ParticleSun:create()
        paticle:setPosition(40,40)
        paticle:addTo(cola)
        
        --向上挖掘得立即释放，救命。
        local temp = self.digThrough
        self.digThrough = true
        self:dig(nil, 'up')
        self.digThrough = temp
        cola:runAction(cc.Sequence:create(
                            cc.EaseBackIn:create(cc.MoveBy:create(0.6,cc.p(0,display.height*2))),
                            cc.CallFunc:create(function()
                                cola:removeFromParent(true)
                                --击退boss
                                local event = cc.EventCustom:new("beat_back_boss")
                                event.stepCnt = 3*gamePara.bossRecedeSteps
                                cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
                            end)))
    end

end

function Player:addAnimation()
    local animationNames = {"dig",}-- "dead"}
    local animationFrameNum = {20,0}
    local animationDelay = {DIG_DURATION / animationFrameNum[1], 0.2}

    for i = 1, #animationNames do
        local frames = display.newFrames("yanshu%04d.png", 1, animationFrameNum[i])
        local animation = display.newAnimation(frames, animationDelay[i])
        display.setAnimationCache("player-" .. animationNames[i], animation)
    end
end