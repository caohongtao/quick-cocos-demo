PlayLayer = class("PlayLayer",  function()
    return display.newScene("PlayLayer")
end)

function PlayLayer:ctor()
    self.mapSize = cc.p(0,0)
    self.mapOriginPoint = cc.p(0,0)
    
    self.m_elements = {}
	self:init()
end

function PlayLayer:init()

    cc.SpriteFrameCache:getInstance():addSpriteFrames('sprite/elements.plist', 'sprite/elements.png')

    self:initMap()    
    self:initTouchListener()
end

function PlayLayer:initMap()
    self.mapSize.x = math.floor(display.width / Element:getElementSize().width)
    self.mapSize.y = math.floor(display.height / Element:getElementSize().height)
    self.mapOriginPoint.x = (display.width - Element:getElementSize().width * self.mapSize.x) / 2
    self.mapOriginPoint.y = (display.height - Element:getElementSize().height * self.mapSize.y) / 2
    
    for row=1, self.mapSize.y do
        self.m_elements[row] = {}
	    for col=1, self.mapSize.x do
            local el = Element:new():create(row, col)
            el:setPosition(self:positionOfElement(row,col))
            el:addTo(self)
            self.m_elements[row][col] = el
	    end
    end
end

function PlayLayer:initTouchListener()
    
    --------------------------------------------
    local function onTouchBegan(touch, event)
        local location = touch:getLocation()
        local el = self:ElementOfposition(location)
        self:removeElement(el)
        return true
    end
    
    --------------------------------------------
    local function onTouchMoved(touch, event)
    end

    --------------------------------------------
    local function onTouchEnded(touch, event)
    end 
    
    --------------------------------------------
    local touchListener = cc.EventListenerTouchOneByOne:create()
    touchListener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
    touchListener:registerScriptHandler(onTouchMoved, cc.Handler.EVENT_TOUCH_MOVED)
    touchListener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
    local dispatcher = cc.Director:getInstance():getEventDispatcher()
    dispatcher:addEventListenerWithSceneGraphPriority(touchListener, self)
end

function PlayLayer:removeElement(el)
    for _, element in ipairs(self:getBlock(el)) do
    	print("("..element.m_row..','..element.m_col..")")

        self.m_elements[element.m_row][element.m_col] = nil
        element:removeFromParent(true)
    end
end

function PlayLayer:getBlock(el)
    for row=1, self.mapSize.y do
        for col=1, self.mapSize.x do
            if self.m_elements[row][col] then
                self.m_elements[row][col].touched = false
            end
        end
    end
    
    local queue = {el}
    el.touched = true
    local index = 1
    
    while queue[index] do
        local curr = queue[index]
        
        local neighbours = self:getNeighbours(curr)
        for _, neighbour in ipairs(neighbours) do
            if not neighbour.touched then
                table.insert(queue,neighbour)
                neighbour.touched = true
            end
        end

        index = index + 1
    end
    
    return queue
end

function PlayLayer:getNeighbours(el)
    local neighbours = {}
    
    if el.m_col > 1 then
        local left  = self.m_elements[el.m_row][el.m_col-1]
        if left and left.m_type == el.m_type then
        	table.insert(neighbours,left)
        end
    end
    
    if el.m_col < self.mapSize.x then
        local right = self.m_elements[el.m_row][el.m_col+1]
        if right and right.m_type == el.m_type then
            table.insert(neighbours,right)
        end
    end
    
    if el.m_row < self.mapSize.y then
        local up    = self.m_elements[el.m_row+1][el.m_col]
        if up and up.m_type == el.m_type then
            table.insert(neighbours,up)
        end
    end
    
    if el.m_row > 1 then
        local down  = self.m_elements[el.m_row-1][el.m_col]
        if down and down.m_type == el.m_type then
            table.insert(neighbours,down)
        end
    end
    return neighbours
end

function PlayLayer:positionOfElement(row, col)
    local x = self.mapOriginPoint.x + Element:getElementSize().width * (col - 1 + 0.5)
    local y = self.mapOriginPoint.y + Element:getElementSize().height * (row - 1 + 0.5)
    return cc.p(x, y)
end

function PlayLayer:ElementOfposition(x, y)
    local rect = cc.rect(0,0,0,0)
    for _, row in pairs(self.m_elements) do
        for _, el in pairs(row) do
            if el then
                rect.x = el:getPositionX() - Element:getElementSize().width / 2
                rect.y = el:getPositionY() - Element:getElementSize().height / 2
                rect.width = Element:getElementSize().width
                rect.height = Element:getElementSize().height
    
                if cc.rectContainsPoint(rect,cc.p(x,y)) then
                    return el
                end
            end
        end
    end
    return nil
end