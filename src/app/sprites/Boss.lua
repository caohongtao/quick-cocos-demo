Boss = class("Boss",  function()
    return display.newSprite()
end)
function Boss:ctor(player, step)
    self.player = player
    self.step = step

    self.dizzy = false
    
    self:setAnchorPoint(0.5,0)
    self:setTexture('res/sprite/bingbing.png')
    self:setPosition(display.cx, display.cy + 2*self.step)
--    self.advanceTimer = self:getScheduler():scheduleScriptFunc(handler(self, self.advance), gamePara.bossMoveInterval, false)


    local beatBackListener = cc.EventListenerCustom:create("beat_back_boss", function (event) self:recede(event.stepCnt) end)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(beatBackListener, self)
    local shockDizzyListener = cc.EventListenerCustom:create("shock_dizzy_boss", function (event) self:shockDizzy(event.second) end)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(shockDizzyListener, self)
    
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
    if steps <= 6 then
    	advanceSteps = 1
    elseif steps <= 10 then
        advanceSteps = 2
    elseif steps <= 16 then
        advanceSteps = 3
    else
        advanceSteps = steps - 16
    end
    print(advanceSteps)
    
    local advanceAction = cc.Sequence:create(
                                cc.MoveBy:create(gamePara.bossMoveInterval,cc.p(0,-advanceSteps*self.step)),
                                cc.DelayTime:create(gamePara.bossMoveInterval),
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
        cc.DelayTime:create(second),
        cc.CallFunc:create(function()
            self.dizzy = false
            self:advance()
        end))
        
    self:runAction(self.dizzyAction)
end