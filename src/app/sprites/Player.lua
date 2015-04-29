Player = class("Player",  function()
    return display.newSprite()
end)
local BORN_HEIGHT = 8.5  --人物诞生时候的位置，BORN_HEIGHT个元素的高度。确保出生在某个元素位置。则移动，降落时都按照整行整列计算，就能保确保人物位置一直在某元素的位置。
local FART_DURATION, FART_FRAMES = 2, 10
local COLA_JET_DURATION, COLA_JET_FRAMES = 0.2, 6
local NUT_BUFF_DURATION, NUT_BUFF_FRAMES = 0.6, 6
function Player:ctor(size)
    self.moving = false
    self.dropping = false
    self.digging = false
    self.dead = false
    
    self.playerSize = size
    
    self.oxygenVol = DataManager.getCurrProperty('hp')
    self.deepth = 0
    self.score = 0
    self.boxes = 0
    self.coins = 0
    self.toys = 0
    self.rebirthTimes = 0
    self.skill1Times = 0
    self.skill2Times = 0
    self.skill3Times = 0
    self.digForce = DataManager.getCurrProperty('power')
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
    self:setSpriteFrame('yanshu0010.png')
    self:setScale(size.width/self:getContentSize().width)
    self:setAnchorPoint(0.5,0.5)
    self:setPosition(display.cx, size.height * BORN_HEIGHT)
    self:addAnimation()
    
    self.nut_buff_effect = display.newSprite('#nut_buff_0001.png',75,100):addTo(self)
    self.nut_buff_effect:setScale(4)
    self.nut_buff_effect:setOpacity(100)
    self.nut_buff_effect:setVisible(false)
    transition.playAnimationForever(self.nut_buff_effect,display.getAnimationCache("nut_buff"))
    
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
        if el.m_type.needDigTime > 0 then
            self:die()
        else
            local event = cc.EventCustom:new("remove_element")
            event.el = el
            cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
        end
    end
end

function Player:gainProp(el)
    audio.playSound('audio/getProp.wav')
    
    if el.m_type == elements.oxygen then
        print('oxygen')
        self.oxygenVol = self.oxygenVol + 10
        local topVol = DataManager.getCurrProperty('hp')
        self.oxygenVol = topVol < self.oxygenVol and topVol or self.oxygenVol
        local event = cc.EventCustom:new("update hub")
        event.type = 'oxygen'
        event.data = self.oxygenVol
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
    elseif el.m_type == elements.silverDrill then
        print('silverDrill')
        self.digForce = self.digForce * 2
        self:performWithDelay(function()
            self.digForce = self.digForce / 2
        end, 10)
    elseif el.m_type == elements.goldenDrill then
        print('goldenDrill')
        self.digForce = self.digForce * 4
        self:performWithDelay(function()
            self.digForce = self.digForce / 4
        end, 10)
    elseif el.m_type == elements.box then
        print('box')
        self.boxes = self.boxes + 1
    elseif el.m_type == elements.coin then
        print('coin')
        self.coins = self.coins + 1
        local event = cc.EventCustom:new("update hub")
        event.type = 'coin'
        event.data = self.coins
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
    elseif el.m_type == elements.gem then
        print('gem')
        DataManager.set(DataManager.POINT, DataManager.get(DataManager.POINT) + 1)
        local event = cc.EventCustom:new("update hub")
        event.type = 'gem'
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
    
end

function Player:reduceOxygen()
    if self.oxygenVol >= 1 then
        self.oxygenVol = self.oxygenVol - 1
    else
        self.oxygenVol = 0
        self:die()
    end
    
    if self.oxygenVol == 30 then
        local event = cc.EventCustom:new("alert oxygen")
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
    end
    
    local event = cc.EventCustom:new("update hub")
    event.type = 'oxygen'
    event.data = self.oxygenVol
    cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
end

function Player:drop()
    if not self.dropping then
--        self.dropping = true
        
        local event = cc.EventCustom:new("roll_map")
        event.playerPos = self:convertToWorldSpaceAR(cc.p(0,0))
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
    end
end

function Player:dig(target, dir)
    if not self.digThrough and self.digging then return end --self.digThrough == true时(复活或者放可乐救命时)，即使上个挖掘动作没玩，也立即挖掘，否则不能往上挖掘，不断死亡。

    --播放dig动画
    self.digging = true
    self:reduceOxygen()
    
    if 'down' == dir then
        transition.playAnimationOnce(self, display.getAnimationCache("player-dig"), false, function () self:setSpriteFrame('yanshu0010.png') end)
    elseif 'left' == dir then
        transition.playAnimationOnce(self, display.getAnimationCache("player-side"), false, function () self:setSpriteFrame('yanshu0010.png') end)
    elseif 'right' == dir then
        self:setFlippedX(true)
        transition.playAnimationOnce(self, display.getAnimationCache("player-side"), false, function () self:setSpriteFrame('yanshu0010.png') self:setFlippedX(false) end)
    end
    
    local duration = gamePara.baseDigDuration / DataManager.getCurrProperty('speed')
    self:runAction(cc.Sequence:create(
        cc.DelayTime:create(duration),
        cc.CallFunc:create(function() self.digging = false end)))
        

    local event = cc.EventCustom:new("dig_at")
    event.target = target
    event.playerPos = self:convertToWorldSpaceAR(cc.p(0,0))
    
    if self.digThrough then
        audio.playSound('audio/digThrough.mp3')
        event.effect = dir
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
    else
        audio.playSound('audio/dig.wav')
        target.m_needDigTime = target.m_needDigTime - self.digForce
        if target.m_needDigTime > 0 then
            target:runAction(cc.JumpBy:create(0.2,cc.p(0,0),3,3))
            return
        end

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
    else
        return  --不会有这种可能，防御代码。
    end
    self.moving = true
    
    if 'left' == dir then
--        transition.playAnimationOnce(self, display.getAnimationCache("player-side"), false, function () self:setSpriteFrame('yanshu0010.png') end)
        self:setSpriteFrame('yanshu0101.png')
    elseif 'right' == dir then
        self:setFlippedX(true)
--        transition.playAnimationOnce(self, display.getAnimationCache("player-side"), false, function () self:setSpriteFrame('yanshu0010.png') self:setFlippedX(false) end)
        self:setSpriteFrame('yanshu0101.png')
    end
    
    local duration = gamePara.baseMoveDuration / DataManager.getCurrProperty('speed')
    self:runAction(cc.Sequence:create(
        cc.MoveBy:create(duration,delta),
        cc.CallFunc:create(function()
            self.moving = false
            self:setSpriteFrame('yanshu0010.png')
            if 'right' == dir then self:setFlippedX(false) end
        end)))
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
                                        local getSettlementInfo = cc.EventCustom:new("get_settlement_info")
                                        cc.Director:getInstance():getEventDispatcher():dispatchEvent(getSettlementInfo)
                                        local settlement = {
                                            saves = 0,
                                            use1 = self.skill1Times,
                                            use2 = self.skill2Times,
                                            use3 = self.skill3Times,
                                            atkboss = getSettlementInfo.recedeTimes,
                                            dizzboss = getSettlementInfo.dizzyTimes,
                                            box = self.boxes,
                                            golds = self.coins,
                                            grounds = self.deepth,
--                                            points =  self.gems,
                                            relive = self.rebirthTimes,
                                        }
                                        
                                        local dieEvent = cc.EventCustom:new("player die")
                                        dieEvent.settlement = settlement
                                        cc.Director:getInstance():getEventDispatcher():dispatchEvent(dieEvent)
                                  end)))
end

function Player:rebirth()
    if not self.dead then return end
    
    self.dead = false
    self.oxygenVol = DataManager.getCurrProperty('hp')
    self.rebirthTimes = self.rebirthTimes + 1
    audio.resumeMusic()

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
    self.mapStage = 1
    local current = coroutine.running()
    
    local dropSpeed = gamePara.baseDropDuration / DataManager.getCurrProperty('speed')
    local perFloorDuration = dropSpeed / 100 * self.playerSize.height
    
    while true do
        self:performWithDelay(function()
            coroutine.resume(current)
        end, perFloorDuration)
        
        if self.dropping then
            self.deepth = self.deepth+1
            local event = cc.EventCustom:new("update hub")
            event.type = 'deepth'
            event.data = self.deepth
            cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)            
            if math.ceil(self.deepth / 200) > self.mapStage then
            	self.mapStage = self.mapStage + 1
                local event = cc.EventCustom:new("adjust map")
                event.stage = self.mapStage
                cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
            end
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
    if distance.y < 6 then
    	self:die()
    end
end

function Player:castSkill(event)
    if event.skillType == elements.mushroom then
        local skillCnt = DataManager.get(DataManager.ITEM_1)
        if skillCnt <= 0 then return end
        DataManager.set(DataManager.ITEM_1, skillCnt - 1)
        self.skill1Times = self.skill1Times + 1
        local e = cc.EventCustom:new("update hub")
        e.type = 'skillMushroom'
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(e)

        local fart = display.newSprite('#pi0001.png'):addTo(self)
        fart:setPosition(60,160)
        transition.playAnimationOnce(fart, display.getAnimationCache("player-fart"))
        fart:runAction(cc.Sequence:create(
            cc.Spawn:create(cc.MoveBy:create(FART_DURATION,cc.p(0,800)),cc.ScaleBy:create(FART_DURATION,10)),
            cc.CallFunc:create(function()
                local eShock = cc.EventCustom:new("shock_dizzy_boss")
                eShock.second = gamePara.bossDizzyTime
                cc.Director:getInstance():getEventDispatcher():dispatchEvent(eShock)
                fart:removeFromParent(true)
            end)))

    elseif event.skillType == elements.nut then
        if self.digThrough then return end

        local skillCnt = DataManager.get(DataManager.ITEM_2)
        if skillCnt <= 0 then return end
        DataManager.set(DataManager.ITEM_2, skillCnt - 1)
        self.skill2Times = self.skill2Times + 1
        local e = cc.EventCustom:new("update hub")
        e.type = 'skillNut'
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(e)

        self.digThrough = true
        self.nut_buff_effect:setVisible(true)
        self:performWithDelay(function()
            self.digThrough = false
            self.nut_buff_effect:setVisible(false)
        end, gamePara.propDuration)
    elseif event.skillType == elements.cola then
        local skillCnt = DataManager.get(DataManager.ITEM_3)
        if skillCnt <= 0 then return end
        DataManager.set(DataManager.ITEM_3, skillCnt - 1)
        self.skill3Times = self.skill3Times + 1
        local e = cc.EventCustom:new("update hub")
        e.type = 'skillCola'
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(e)
        
        local cola = display.newSprite('ui/jineng3.png',40,40)
        cola:setScale(4)
        cola:addTo(self)
        local jet = display.newSprite('#cola_jet_0001.png',20,-200):addTo(cola)
        jet:setRotation(90)
        jet:setScale(1.6,0.6)
        transition.playAnimationForever(jet,display.getAnimationCache("cola_jet"))
        
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
    local animationNames = {"dig","side"}
    local animationFrameNum = {10,10}
    local duration = gamePara.baseDigDuration / DataManager.getCurrProperty('speed')
    local animationDelay = {duration / animationFrameNum[1], duration / animationFrameNum[2]}

    --鼹鼠
    for i = 1, #animationNames do
        local frames = display.newFrames("yanshu0"..(i-1).."%02d.png", 1, animationFrameNum[i])
        local animation = display.newAnimation(frames, animationDelay[i])
        display.setAnimationCache("player-" .. animationNames[i], animation)
    end
    
    --屁
    local frames = display.newFrames("pi%04d.png", 1, 10)
    local animation = display.newAnimation(frames, FART_DURATION / FART_FRAMES)
    display.setAnimationCache("player-fart", animation)

    --cola jet
    frames = display.newFrames("cola_jet_%04d.png", 1, COLA_JET_FRAMES)
    animation = display.newAnimation(frames, COLA_JET_DURATION / COLA_JET_FRAMES)
    display.setAnimationCache("cola_jet", animation)
    
    --power buff
    frames = display.newFrames("nut_buff_%04d.png", 1, NUT_BUFF_FRAMES)
    animation = display.newAnimation(frames, NUT_BUFF_DURATION / NUT_BUFF_FRAMES)
    display.setAnimationCache("nut_buff", animation)
end