Element = class("Element",  function()
    return display.newSprite()
end)
local CRUSH_DURATION, CRUSH_FRAMES = 1, 10
local EXPLODE_DURATION, EXPLODE_CENTER_FRAMES, EXPLODE_SPREAD_FRAMES = 0.6, 4, 4

function Element:ctor()
    self.m_row = 0
    self.m_col = 0

    self.m_type = ''
    self.m_needDigTime = 0

    self.needCheckRemove = false    --drop到load后，需要检查此，标志，看是否需要消除。
end

function Element:createFSM()

    -- create Finite State Machine
    self.fsm_ = {}
    cc.GameObject.extend(self.fsm_)
        :addComponent("components.behavior.StateMachine")
        :exportMethods()

    self.fsm_:setupState({
        events = {
            {name = "start",        from = "none",      to = "IDLE" },
            {name = "unSupport",    from = "IDLE",      to = "SHAKE"},
            {name = "shakeOver",    from = "SHAKE",     to = "DROP" },
            {name = "push",         from = "SHAKE",     to = "DROP" },
            {name = "support",      from = "SHAKE",     to = "IDLE" },
            {name = "support",      from = "DROP",      to = "LOAD" },
            {name = "loadOver",     from = "LOAD",      to = "IDLE" },
            {name = "unSupport",    from = "LOAD",      to = "SHAKE"},
            {name = "destroy",      from = "IDLE",      to = "DIE"  },  --dig
            {name = "destroy",      from = "LOAD",      to = "DIE"  },  --着陆后消除
            {name = "destroy",      from = "SHAKE",     to = "DIE"  },  --1.removeElement不好处理，出现的特殊情况。    2.掉落到正在摇晃的元素后，往下挖
            {name = "destroy",      from = "DROP",      to = "DIE"  },  --挖侧面的正在掉落的元素
        },

        callbacks = {
            onIDLE  = function(event)
                cc.Director:getInstance():getActionManager():removeAllActionsFromTarget(self)
                if event.args[1] then
                    self:setPosition(event.args[1])
                end
            end,

            onSHAKE = function(event)
                self:shake()
            end,

            onDROP  = function(event)
                self:drop()
            end,

            onLOAD  = function(event)
                self:load(event.args[1])
            end,
            
            onDIE   = function(event)
                self:die()
            end,

--            onchangestate = function(event) print("("..self.m_row..","..self.m_col..") STATE: " .. event.from .. " to " .. event.to) end,
        },
    })

    self.fsm_:doEvent("start")
end

function Element:create(row, col ,type)
    self.m_row = row
    self.m_col = col
    
    local eType = type ~= nil and type or self:getTypeAccordProbability()

    self.m_type = eType
    self.m_needDigTime = eType.needDigTime
    local texture = eType.isBrick and string.sub(eType.texture,1,-5)..math.random(1,3)..'.png' or eType.texture
    self:setSpriteFrame(texture)
    self:createFSM()
    return self; 
end

function Element:getTypeAccordProbability()
	
    local random = math.random(0,mapStrategys.totalProbability)
    for _, element in pairs(elements) do
        if random <= element.IntervalEnd then
        	return element
        end
    end
    
    return elements[#elements] --不可能执行到这里，以防万一
end

local ElementShakeSpeed = 1
local ElementDropSpeed = 0.4
--方块摇动动画
function Element:shake()
    cc.Director:getInstance():getActionManager():removeAllActionsFromTarget(self)

    --shack
    self.shaked = true
    self.originX = self:getPositionX()
    if self.shakAction ~=nil then transition.removeAction(self.shakAction) end
    local arr = {}    

    table.insert(arr,cc.MoveBy:create( 0.05*ElementShakeSpeed, cc.p(-3,0)))
    for i =1,5 do
        table.insert(arr,cc.MoveBy:create(0.1 *ElementShakeSpeed, cc.p(6,0)))
        table.insert(arr,cc.MoveBy:create( 0.1*ElementShakeSpeed, cc.p(-6,0)))
    end
    table.insert(arr,cc.MoveBy:create( 0.05*ElementShakeSpeed, cc.p(3,0)))

    table.insert(arr,cc.CallFunc:create(function()
        self.shaked = false
    end))

    self.shakAction = cc.Sequence:create(arr)

    local shakeOverNotify = cc.CallFunc:create(function() self.fsm_:doEvent("shakeOver") end)

    self:runAction(cc.Sequence:create(self.shakAction, shakeOverNotify))

end

function Element:drop()
    cc.Director:getInstance():getActionManager():removeAllActionsFromTarget(self)
    local arr = {}   
    table.insert(arr, cc.MoveBy:create(ElementDropSpeed,cc.p(0,-100)))

    local function onComplete()
        if self:getState() == 'DROP' then
            self:drop(onComplete)
        end
    end
    --没有支撑，就继续往下掉
    table.insert(arr,cc.CallFunc:create(onComplete))

    self:runAction(cc.Sequence:create(arr))
end

function Element:load(dest)

    cc.Director:getInstance():getActionManager():removeAllActionsFromTarget(self)

    self.needCheckRemove = true --刚刚着陆的需要检查是否消除

    local goDest = transition.moveTo(self,{x = dest.x, y = dest.y, time = ElementDropSpeed * math.abs(dest.y - self:getPositionY()) / 100})
    local bouceUp = transition.moveTo(self,{x = dest.x, y = dest.y+6, time = 0.1})
    local backDest = transition.newEasing(cc.MoveTo:create(0.1, dest), {easing = 'elasticOut'})
    local loadOverNotify = cc.CallFunc:create(function()
        self.fsm_:doEvent("loadOver", dest)
    end)

    transition.execute(self, transition.sequence({goDest, bouceUp, backDest, loadOverNotify}))

end

function Element:die()
    cc.Director:getInstance():getActionManager():removeAllActionsFromTarget(self)
    
    local function gainProp()
        local event = cc.EventCustom:new("gain_prop")
        event.element = self
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
    end
    
    local function createFakeAndMoveTo(dest)
        local fake = display.newSprite('#'..self.m_type.texture)

        local curPos = self:convertToWorldSpaceAR(cc.p(0,0))
        fake:setPosition(curPos.x,curPos.y)
        fake:setScale(self:getScaleX(),self:getScaleY())
        fake:addTo(cc.Director:getInstance():getRunningScene())

        fake:runAction(cc.Sequence:create(
            cc.Spawn:create(cc.EaseIn:create(cc.MoveTo:create(1,dest), 0.5),cc.ScaleTo:create(1,0.3)),
            cc.CallFunc:create(function()
                fake:removeFromParent(true)
            end)))
        self:removeFromParent(true)
    end
    
    if self.m_type.isBrick then
        local curPos = self:convertToWorldSpaceAR(cc.p(0,0))
        local crush = display.newSprite('#crush_0001.png',curPos.x,curPos.y):addTo(self:getParent())
        crush:setAnchorPoint(cc.p(0.5,0.5))
        crush:setPosition(self:getPosition())
        crush:setScale(0.4)
--        crush:setColor(cc.c3b(unpack(self.m_type.color)))
        transition.playAnimationOnce(crush, display.getAnimationCache("brick-crush"))
        crush:runAction(cc.Sequence:create(
            cc.DelayTime:create(CRUSH_DURATION),
            cc.CallFunc:create(function()
                crush:removeFromParent(true)
            end)))
        self:removeFromParent(true)
    elseif self.m_type == elements.coin then
        gainProp()
        createFakeAndMoveTo(cc.p(display.right-90, display.top-30))
    elseif self.m_type == elements.gem then
        gainProp()
        createFakeAndMoveTo(cc.p(display.right-100,display.bottom+40))
    elseif self.m_type == elements.mushroom then
        gainProp()
        createFakeAndMoveTo(cc.p(140,display.bottom+50))
    elseif self.m_type == elements.nut then
        gainProp()
        createFakeAndMoveTo(cc.p(210,display.bottom+50))
    elseif self.m_type == elements.cola then
        gainProp()
        createFakeAndMoveTo(cc.p(280,display.bottom+50))
    elseif self.m_type == elements.timebomb then
        self:setLocalZOrder(1)
        self:runAction(cc.Sequence:create(cc.TintTo:create(2,255,0,0),
                            cc.CallFunc:create(function()
                                local explosion_center = display.newSprite('#explode_center_0001.png'):addTo(self:getParent())
                                explosion_center:setPosition(self:getPosition())
                                explosion_center:setLocalZOrder(10)
                                transition.playAnimationOnce(explosion_center, display.getAnimationCache("bomb-explode-center"))
                                explosion_center:performWithDelay(function() explosion_center:removeFromParent(true) end, EXPLODE_DURATION)
                                
                                local explosion_spread = display.newSprite('#explode_spread_0001.png'):addTo(self:getParent())
                                explosion_spread:setScale(2,4)
                                explosion_spread:setPosition(self:getPosition())
                                explosion_spread:setLocalZOrder(10)
                                transition.playAnimationOnce(explosion_spread, display.getAnimationCache("bomb-explode-spread"))
                                explosion_spread:performWithDelay(function() explosion_spread:removeFromParent(true) end, EXPLODE_DURATION)
                            end),
                            cc.DelayTime:create(EXPLODE_DURATION/2),
                            cc.CallFunc:create(function()
                                audio.playSound('audio/explosion.mp3')
                                local event = cc.EventCustom:new("bomb_explode")
                                event.el = self
                                cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
                                self:removeFromParent(true)
                            end)))
    elseif self.m_type == elements.box then
        --开出随机道具，并直接拾取
        local types = {elements.coin, elements.gem, elements.goldenDrill, elements.oxygen,}-- elements.punish}
        local randomType = types[math.random(1,#types)]
        local randomProp = Element.new():create(self.m_row, self.m_col, randomType)
        randomProp:addTo(self:getParent())
        randomProp:setPosition(self:getPosition())
        randomProp.fsm_:doEvent("destroy")
        
        --拾取箱子本身，需要统计宝箱数量
        gainProp()
        self:runAction(cc.Sequence:create(cc.FadeOut:create(0.6),
            cc.CallFunc:create(function()
                self:removeFromParent(true)
            end)))
    else
        gainProp()
        self:runAction(cc.Sequence:create(cc.FadeOut:create(0.6),
        cc.CallFunc:create(function()
            self:removeFromParent(true)
        end)))
    end
end

function Element:getState()
    return self.fsm_:getState()
end

function Element:isStable()
    return self.fsm_:getState() == "IDLE" or
        --           self.fsm_:getState() == "SHAKE" or
        self.fsm_:getState() == "LOAD"
end

function Element:addAnimation()
    --brick crush
    local frames = display.newFrames("crush_%04d.png", 1, CRUSH_FRAMES)
    local animation = display.newAnimation(frames, CRUSH_DURATION / CRUSH_FRAMES)
    display.setAnimationCache("brick-crush", animation)
    
    --bomb explode
    frames = display.newFrames("explode_center_%04d.png", 1, EXPLODE_CENTER_FRAMES)
    animation = display.newAnimation(frames, EXPLODE_DURATION / EXPLODE_CENTER_FRAMES)
    display.setAnimationCache("bomb-explode-center", animation)
    
    frames = display.newFrames("explode_spread_%04d.png", 1, EXPLODE_SPREAD_FRAMES)
    animation = display.newAnimation(frames, EXPLODE_DURATION / EXPLODE_SPREAD_FRAMES)
    display.setAnimationCache("bomb-explode-spread", animation)
end