Boss = class("Boss",  function()
    return display.newSprite()
end)
function Boss:ctor(step)
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

function Player:unscheduleAllTimers()
    self:unscheduleUpdate()
--    self:getScheduler():unscheduleScriptEntry(self.advanceTimer)
end

local ADVANCE_ACTION_TAG = 3838
function Boss:advance()
    if self.dizzy then return end

    local advanceAction = cc.Sequence:create(
                                cc.MoveBy:create(gamePara.bossMoveInterval,cc.p(0,-self.step)),
                                cc.DelayTime:create(gamePara.bossMoveInterval),
                                cc.CallFunc:create(function()
                                    local event = cc.EventCustom:new("boss_advance")
                                    event.bossPos = self:convertToWorldSpaceAR(cc.p(0,0))
                                    cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
                                end))
    self.advanceAction = cc.RepeatForever:create(advanceAction)
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