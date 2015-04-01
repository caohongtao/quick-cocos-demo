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

function Element:create(row, col)
    self.m_row = row
    self.m_col = col
    
    local eTypes = table.keys(res.elementTexture)
    local randomType = eTypes[math.random(1,table.maxn(eTypes))]
    
    self.m_type = randomType
    self.m_mode = 'normal'

    self:setSpriteFrame(res.elementTexture[randomType].normal)
    
    return self; 
end

local shakeSpeed = 1
local dropSpeed = 0.2
--方块摇动动画
function Element:shakeAndDrop(step)

    --shack
    self.shaked = true
    self.dropStep = step
    if self.shakAction ~=nil then transition.removeAction(self.shakAction) end
    local arr = {}    
    
    table.insert(arr,cc.RotateTo:create( 0.05*shakeSpeed, -10))
    for i =1,5 do
        table.insert(arr,cc.RotateTo:create(0.1 *shakeSpeed, 10))
        table.insert(arr,cc.RotateTo:create( 0.1*shakeSpeed, -10))
    end
    table.insert(arr,cc.RotateTo:create( 0.05*shakeSpeed, 0))

    table.insert(arr,cc.CallFunc:create(function()
        self.shaked = false
    end))
    
    self.shakAction = cc.Sequence:create(arr)

    local dropAction = cc.CallFunc:create(function() self:drop(step) end)
    
    self:runAction(cc.Sequence:create(self.shakAction, dropAction))
end

--停止摇动
function Element:stopShake()
    if self.shaked then
        if self.shakAction ~= nil then transition.stopTarget(self) end
        self.shaked = false
        self:runAction(cc.RotateTo:create(0, 0))
        self:drop(self.dropStep)
    end
end

function Element:drop(step)
    local arr = {}   
    table.insert(arr, cc.MoveBy:create(dropSpeed,step))
    
    local function onComplete()
    	if not self.m_supported then
            self:drop(step, onComplete)
        end
    end
    --没有支撑，就继续往下掉
    table.insert(arr,cc.CallFunc:create(onComplete))
    
    self:runAction(cc.Sequence:create(arr))
end