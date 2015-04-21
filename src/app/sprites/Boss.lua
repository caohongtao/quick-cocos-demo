Boss = class("Boss",  function()
    return display.newSprite()
end)
function Boss:ctor(player, step)
    self.player = player
    self.step = gamePara.bossMoveStep

    self.dizzy = false
    
    cc.SpriteFrameCache:getInstance():addSpriteFrames('sprite/boss.plist', 'sprite/boss.png')
    self:setAnchorPoint(0.5,0)
    self:setSpriteFrame('she0001.png')
    self:setPosition(display.cx, display.cy + 2*self.step)
    self:addAnimation()
    transition.playAnimationForever(self, display.getAnimationCache("boss-advance"))
    
--    self.advanceTimer = self:getScheduler():scheduleScriptFunc(handler(self, self.advance), gamePara.bossMoveInterval, false)
    local beatBackListener = cc.EventListenerCustom:create("beat_back_boss", function (event) self:recede(event.stepCnt) end)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(beatBackListener, self)
    local shockDizzyListener = cc.EventListenerCustom:create("shock_dizzy_boss", function (event) self:shockDizzy(event.second) end)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(shockDizzyListener, self)
    local explode_Listener = cc.EventListenerCustom:create("bomb_explode", handler(self,self.bombExplode))
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(explode_Listener, self)
    
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
    if self.dizzyAction then self:stopAction(self.dizzyAction) end  --防止连续被击晕，回调中提前讲self.dizzy ＝ false
    
    if self.advanceAction then self:stopAction(self.advanceAction) end
    
    self.dizzyAction = cc.Sequence:create(
        cc.JumpBy:create(second,cc.p(0,0),30,20),
        cc.CallFunc:create(function()
            self.dizzy = false
            self:advance()
        end))
        
    self:runAction(self.dizzyAction)
end

function Boss:addAnimation()
    local animationNames = {"advance",}-- "dead"}
    local animationFrameNum = {5,0}
--    local animationDelay = {gamePara.bossMoveInterval / animationFrameNum[1], 0.2}
    local animationDelay = {0.3, 0.2}

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