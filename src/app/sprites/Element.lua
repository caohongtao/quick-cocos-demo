Element = class("Element",  function()
    return display.newSprite()
end)

function Element:ctor()
    self.m_row = 0
    self.m_col = 0
    
    self.m_type = ''
    self.m_mode = ''

    self.m_supported = true
    
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
        },

        callbacks = {
            onIDLE  = function(event)
                cc.Director:getInstance():getActionManager():removeAllActionsFromTarget(self)
--                self:matrixToPosition(curr.m_row,curr.m_col)
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
            
--            onchangestate = function(event) print(self.m_type.."("..self.m_row..","..self.m_col..") STATE: " .. event.from .. " to " .. event.to) end,
        },
    })
    
    self.fsm_:doEvent("start")
end

function Element:create(row, col)
    self.m_row = row
    self.m_col = col
    
    local eTypes = table.keys(res.elementTexture)
    local randomType = eTypes[math.random(1,table.maxn(eTypes))]
    
    self.m_type = randomType
    self.m_mode = 'normal'

    self:setSpriteFrame(res.elementTexture[randomType].normal)
    self:createFSM()
    return self; 
end

local shakeSpeed = 1
--方块摇动动画
function Element:shake()
    cc.Director:getInstance():getActionManager():removeAllActionsFromTarget(self)
    
    --shack
    self.shaked = true
    self.originX = self:getPositionX()
    if self.shakAction ~=nil then transition.removeAction(self.shakAction) end
    local arr = {}    
    
    table.insert(arr,cc.MoveBy:create( 0.05*shakeSpeed, cc.p(-3,0)))
    for i =1,5 do
        table.insert(arr,cc.MoveBy:create(0.1 *shakeSpeed, cc.p(6,0)))
        table.insert(arr,cc.MoveBy:create( 0.1*shakeSpeed, cc.p(-6,0)))
    end
    table.insert(arr,cc.MoveBy:create( 0.05*shakeSpeed, cc.p(3,0)))

    table.insert(arr,cc.CallFunc:create(function()
        self.shaked = false
    end))
    
    self.shakAction = cc.Sequence:create(arr)

    local shakeOverNotify = cc.CallFunc:create(function() self.fsm_:doEvent("shakeOver") end)
    
    self:runAction(cc.Sequence:create(self.shakAction, shakeOverNotify))
    
end

----停止摇动
--function Element:stopShake()
--    if self.shaked then
--        if self.shakAction ~= nil then transition.stopTarget(self) end
--        self.shaked = false
--        self:setPositionX(self.originX)
--        self:drop(self.dropStep)
--    end
--end

local dropSpeed = 0.4 --移动100像素所用时
function Element:drop()
    cc.Director:getInstance():getActionManager():removeAllActionsFromTarget(self)
    local arr = {}   
    table.insert(arr, cc.MoveBy:create(dropSpeed,cc.p(0,-100)))
    
    local function onComplete()
    	if not self.m_supported then
            self:drop(onComplete)
        end
    end
    --没有支撑，就继续往下掉
    table.insert(arr,cc.CallFunc:create(onComplete))
    
    self:runAction(cc.Sequence:create(arr))
end

function Element:load(dest)

    cc.Director:getInstance():getActionManager():removeAllActionsFromTarget(self)
--    self.shaked = false
--    
--    if not self.startDropPos or cc.pDistanceSQ(self.startDropPos,cc.p(self:getPosition())) < 50 then
--        self:setPosition(dest)
--        return 
--    end
    
    local goDest = transition.moveTo(self,{x = dest.x, y = dest.y, time = dropSpeed * math.abs(dest.y - self:getPositionY()) / 100})
    local bouceUp = transition.moveTo(self,{x = dest.x, y = dest.y+6, time = 0.1})
    local backDest = transition.newEasing(cc.MoveTo:create(0.1, dest), {easing = 'elasticOut'})
    local loadOverNotify = cc.CallFunc:create(function()
        self.fsm_:doEvent("loadOver", dest)
    end)
    
    transition.execute(self, transition.sequence({goDest, bouceUp, backDest, loadOverNotify}))
    
end

function Element:getState()
    return self.fsm_:getState()
end

function Element:isStable()
    return self.fsm_:getState() == "IDLE" or
--           self.fsm_:getState() == "SHAKE" or
           self.fsm_:getState() == "LOAD"
end