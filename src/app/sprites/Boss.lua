Boss = class("Boss",  function()
    return display.newSprite()
end)
function Boss:ctor(player)
    self.player = player
    self.step = gamePara.bossMoveStep

    self.dizzy = false
    
    self.dizzyTimes = 0
    self.recedeTimes = 0
    
    cc.SpriteFrameCache:getInstance():addSpriteFrames('sprite/boss.plist', 'sprite/boss.png')
    self:setAnchorPoint(0.5,0)

    self:setPosition(display.cx, display.cy + 20*self.step)
    self:addAnimation()
    
    self.dizzyEffect = cc.Node:create():addTo(self)
    self.dizzyEffect:setPosition(80,75)
    local dizzyEffectLeft = display.newSprite('#dizzy_effect.png',-22,0):addTo(self.dizzyEffect)
    dizzyEffectLeft:runAction(cc.RepeatForever:create(cc.RotateBy:create(1,360)))
    local dizzyEffectRight = display.newSprite('#dizzy_effect.png',22,0):addTo(self.dizzyEffect)
    dizzyEffectRight:runAction(cc.RepeatForever:create(cc.RotateBy:create(1,360)))
    self.dizzyEffect:setVisible(false)
end

function Boss:init()
    self:setSpriteFrame('she0001.png')
    
    self.animateAction = transition.playAnimationForever(self, display.getAnimationCache("boss-advance"))
    
    local beatBackListener = cc.EventListenerCustom:create("beat_back_boss", function (event) self:recede(event.stepCnt) end)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(beatBackListener, self)
    local shockDizzyListener = cc.EventListenerCustom:create("shock_dizzy_boss", function (event) self:shockDizzy(event.second) end)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(shockDizzyListener, self)
    local explode_Listener = cc.EventListenerCustom:create("bomb_explode", handler(self,self.bombExplode))
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(explode_Listener, self)
    local settlementListener = cc.EventListenerCustom:create("get_settlement_info", handler(self,self.getSettlementInfo))
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(settlementListener, self)
    
    self:advance()
end

function Boss:unscheduleAllTimers()
    self:unscheduleUpdate()
--    self:getScheduler():unscheduleScriptEntry(self.advanceTimer)
end

local ADVANCE_ACTION_TAG = 3838
function Boss:advance()
    if self.dizzy then return end
    if self.advanceAction then self:stopAction(self.advanceAction) end

    local playerPos = self.player:convertToWorldSpaceAR(cc.p(0,0))
    local bossPos = self:convertToWorldSpaceAR(cc.p(0,0))
    local steps = math.ceil((bossPos.y - playerPos.y)/self.step)
    local advanceSteps = 1
    if steps <= gamePara.bossSlowDownDistance then
    	advanceSteps = 1
    elseif steps <= 2*gamePara.bossSlowDownDistance then
        advanceSteps = 2
    elseif steps <= 3*gamePara.bossSlowDownDistance then
        advanceSteps = 3
--    elseif steps <= 4*gamePara.bossSlowDownDistance then
--        advanceSteps = 4
    else
        advanceSteps = steps-3*gamePara.bossSlowDownDistance
    end
    
--    transition.playAnimationOnce(self, display.getAnimationCache("boss-advance"))
    local advanceAction = cc.Sequence:create(
                                cc.MoveBy:create(gamePara.bossMoveInterval,cc.p(0,-advanceSteps*self.step)),
--                                cc.DelayTime:create(gamePara.bossMoveInterval),
                                cc.CallFunc:create(function()
                                    local event = cc.EventCustom:new("boss_advance")
                                    event.bossPos = self:convertToWorldSpaceAR(cc.p(0,0))
                                    cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
                                    
                                    self:advance()
                                end))
    self.advanceAction = advanceAction--cc.RepeatForever:create(advanceAction)
    self:runAction(self.advanceAction)
end

function Boss:recede(stepCnt)
    self.recedeTimes = self.recedeTimes + 1
    local recedeAction = cc.Sequence:create(
                                cc.CallFunc:create(function()
                                    if self.advanceAction then
                                        self:stopAction(self.advanceAction)
                                    end
                                end),
                                cc.MoveBy:create(0.3,cc.p(0,stepCnt * self.step)),
                                cc.CallFunc:create(function() self:advance() end))
    self:runAction(recedeAction)
end

function Boss:shockDizzy(second)
    self.dizzy = true
    self.dizzyTimes = self.dizzyTimes + 1
    
    if self.dizzyAction then self:stopAction(self.dizzyAction) end  --防止连续被击晕，回调中提前讲self.dizzy ＝ false
    
    if self.advanceAction then self:stopAction(self.advanceAction) end
    
    if self.animateAction then
        self:stopAction(self.animateAction)
        self.animateAction = nil
        self:setSpriteFrame('she0002.png')
    end
    
    self.dizzyEffect:setVisible(true)
    self.dizzyAction = cc.Sequence:create(
        cc.JumpBy:create(second,cc.p(0,0),30,20),
        cc.CallFunc:create(function()
            self.dizzy = false
            self.dizzyEffect:setVisible(false)
            self.animateAction = transition.playAnimationForever(self, display.getAnimationCache("boss-advance"))
            self:advance()
        end))
        
    self:runAction(self.dizzyAction)
end

function Boss:addAnimation()
    local animationNames = {"advance",}-- "dead"}
    local animationFrameNum = {5,0}
--    local animationDelay = {gamePara.bossMoveInterval / animationFrameNum[1], 0.2}
    local animationDelay = {0.2, 0.2}

    for i = 1, #animationNames do
        local frames = display.newFrames("she%04d.png", 1, animationFrameNum[i])
        local animation = display.newAnimation(frames, animationDelay[i])
        display.setAnimationCache("boss-" .. animationNames[i], animation)
    end
end

function Boss:bombExplode(event)
    local bomb = event.el
    local bombPos = bomb:convertToWorldSpaceAR(cc.p(0,0))
    local bossPos = self:convertToWorldSpaceAR(cc.p(0,0))
    
    --    if math.abs(bombPos.y - bossPos.y) < 100 then
    if bossPos.y < bombPos.y then
        self:shockDizzy(gamePara.bossDizzyTime)
    end
end

function Boss:getSettlementInfo(event)
    event. dizzyTimes = self.dizzyTimes
    event. recedeTimes = self.recedeTimes
end
