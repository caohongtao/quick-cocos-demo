Element = class("Element",  function()
    return display.newSprite()
end)

function Element:ctor()
    self.m_row = 0
    self.m_col = 0
    
    self.m_type = ''
    self.m_mode = ''
    
    self.m_isNeedRemove = false
    self.m_ignoreCheck = false

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

function Element:getElementSize()
	ElementSize = nil
    if (nil == ElementSize) then
        local sprite = display.newSprite('#'..res.elementTexture.fire.normal)
        ElementSize = sprite:getContentSize()
    end
    return ElementSize;
end

function Element:setMode(mode)
    self.m_mode = mode
    local textureName = '#'..self.m_type..'_'..mode..'.png'
    textureName = res.elementTexture[self.m_type][self.m_mode]
    print("Element:setDisplayMode,"..textureName)
    local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(textureName)
	self:setSpriteFrame(frame)
end