PlayLayer = class("PlayLayer",  function()
    return display.newLayer("PlayLayer")
end)

function PlayLayer:ctor()
    self.map = cc.Node:create()
    self.mapSize = cc.p(MAP_WIDTH,MAP_HEIGHT)
    self.mapOriginPoint = cc.p(display.left+MAP_START_X, display.bottom+MAP_START_Y)
    
    self.elSize = nil

    self.m_elements = {}
    self.m_droppingElements = {}
    
    self:init()
end

function PlayLayer:init()

    cc.SpriteFrameCache:getInstance():addSpriteFrames('sprite/elements.plist', 'sprite/elements.png')
    
    self:initMap()
    self:addChild(self.map)
    
    local player = Player.new(self.elSize)
    self:addChild(player)
    
    local detectListener = cc.EventListenerCustom:create("detect_map", handler(self,self.detectMap))
    local digListener = cc.EventListenerCustom:create("dig_at", handler(self,self.digAt))
    local rollMapListener = cc.EventListenerCustom:create("roll_map", handler(self,self.rollMap))
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(detectListener, self)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(digListener, self)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(rollMapListener, self)

    local scheduler = cc.Director:getInstance():getScheduler()
    scheduler:scheduleScriptFunc(handler(self, self.checkDroppingElements), 1.0 / 60.0, false)
--    self:scheduleUpdateWithPriorityLua(handler(self, self.showElementInfo), 0);
end

function PlayLayer:showElementInfo()
    self:forEachElementOfMatrix(self.m_elements, function(el)
        local showSupportedLabel = el:getChildByName('support')
        if nil == showSupportedLabel then
            showSupportedLabel = cc.Label:createWithTTF('hello','fonts/arial.ttf',20)
            showSupportedLabel:setColor(cc.c3b(0,0,0))
            showSupportedLabel:setPosition(55,10)
            showSupportedLabel:setName('support')
            el:addChild(showSupportedLabel)
        end
        showSupportedLabel:setString(el:getState())
    end)

    self:forEachElementOfMatrix(self.m_droppingElements, function (el)
        local showSupportedLabel = el:getChildByName('support')
        showSupportedLabel:setString(el:getState())
    end)
end

function PlayLayer:initMap()

    --以宽度为基准缩放
    local elActualSize = (display.width - self.mapOriginPoint.x * 2) / self.mapSize.x
    self.elSize = {width = elActualSize, height = elActualSize}

    for row=1, self.mapSize.y do
        self.m_elements[row] = {}
        for col=1, self.mapSize.x do
            local el = Element:new():create(row, col)
            el:setPosition(cc.p(self:matrixToPosition(row,col)))
            el:setScale(self.elSize.width/el:getContentSize().width, self.elSize.height/el:getContentSize().height)
            el:addTo(self.map)
            self.m_elements[row][col] = el
        end
    end
    self.m_elements[0], self.m_elements[self.mapSize.y + 1] = {}, {} --为了后面self.m_elements[row][col]获取方便，行号越界直接返回nil，而不是异常

    for row=1, self.mapSize.y do
        self.m_droppingElements[row] = {}
        for col=1, self.mapSize.x do
            self.m_droppingElements[row][col] = nil
        end
    end
    self.m_droppingElements[0], self.m_droppingElements[self.mapSize.y + 1] = {}, {}
end


function PlayLayer:removeElement(el)
    if not el then return end
    local block = self:getBlock(el)
    
    --1.标记依赖于el的unsupported的元素。
    --递归地把周围同色元素及上方元素都认为失去支点，需要掉落。可能会有个别元素误判，会在checkDroppingElements时修正，很快从idle->shake->idle。
    
    self:forEachElementOfMatrix(self.m_elements, function (el) el.touched = false end)
    local unSupportedQueue = {el}
    while #unSupportedQueue > 0 do
        local curr = unSupportedQueue[1]
        table.remove(unSupportedQueue,1)

        if not curr.touched then
            local neighbours = {
                up =  self.m_elements[curr.m_row+1][curr.m_col],
                down = self.m_elements[curr.m_row-1][curr.m_col],
                left = self.m_elements[curr.m_row][curr.m_col-1],
                right = self.m_elements[curr.m_row][curr.m_col+1]
            }

            for key, neighbour in pairs(neighbours) do
                if neighbour then

                    --                neighbour.touched = true
                    if (key == 'up') or
                        (key ~= 'up' and neighbour.m_type == curr.m_type) then

                        table.insert(unSupportedQueue,neighbour)
                    end
                end
            end

            --处理当前元素
            self.m_elements[curr.m_row][curr.m_col] = nil
            self.m_droppingElements[curr.m_row][curr.m_col] = curr
            curr.touched = true
            curr.fsm_:doEvent("unSupport")
        end
    end
    
    --2.删除整片
    for _, element in ipairs(block) do
        self.m_elements[element.m_row][element.m_col] = nil
        self.m_droppingElements[element.m_row][element.m_col] = nil
        element.fsm_:doEvent("destroy")
    end
end

function PlayLayer:markUnSupported()
    --先全部置为 unsupported
    self:forEachElementOfMatrix(self.m_elements, function(el) el.m_supported = false end)

    --将所有空位下方的元素全部置为 supported
    for col=1, self.mapSize.x do
        local emptyRow = self.mapSize.y + 1

        for row=1, self.mapSize.y do
            if nil == self.m_elements[row][col] then
                emptyRow = row break
            end
        end
        for row=1, emptyRow - 1 do
            if self.m_elements[row][col] then
                self.m_elements[row][col].m_supported = true 
            end
        end
    end

--    --对所有块进行检查，每个块中有一个为supported，则整块为supported
--    local blocks = self:divideIntoBlocks()
--    for _, block in ipairs(blocks) do
--        local blockSupported = false
--        
--        for _, el in ipairs(block) do
--            if el.m_supported then
--                blockSupported = true break
--          end
--      end
--      
--        if blockSupported then
--            for _, el in ipairs(block) do
--                el.m_supported = true
--            end
--      end
--    end

    --个别元素自身为unsupported,但其下方有supported的元素。应该当作supported处理。
    --此处认为此种元素应该掉落，下一次做掉落判断时，认为其落在了下方元素上.以此做简化处理。
end

function PlayLayer:dropUnSupported()
    self:markUnSupported()
    
    self:forEachElementOfMatrix(self.m_elements, function(el)
        if el.m_supported then return end

        --摇动结束后，才认为不是支撑点。 否则会在摇晃时，跟正在掉落的元素重叠。
        self.m_elements[el.m_row][el.m_col] = nil
        self.m_droppingElements[el.m_row][el.m_col] = el
        el.fsm_:doEvent("unSupport")
    end)
end

function PlayLayer:divideIntoBlocks()
    local blocks = {}
    self:forEachElementOfMatrix(self.m_elements, function(el) el.divided = false end)

    self:forEachElementOfMatrix(self.m_elements, function(el, blocks)
        if el.divided then return end

        local block = self:getBlock(el)
        for _, element in ipairs(block) do
            element.divided = true
        end

        table.insert(blocks,block)
    end, blocks)

    return blocks
end

function PlayLayer:getBlock(el)
    self:forEachElementOfMatrix(self.m_elements, function (el) el.reached = false end)

    local queue = {el}
    el.reached = true
    local index = 1

    while queue[index] do
        local curr = queue[index]

        local neighbours = self:getNeighbours(curr)
        for _, neighbour in ipairs(neighbours) do
            if not neighbour.reached then
                table.insert(queue,neighbour)
                neighbour.reached = true
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

function PlayLayer:refreshPosInDroppingMatrix(el)
    local row, col = self:positionToMatrix(el:getPosition())

    --下方的如果还没变为nil，暂不设置，等下方移动后，再设，避免重叠。
    if row ~= el.m_row and self.m_droppingElements[row][col] == nil then
        self.m_droppingElements[el.m_row][el.m_col] = nil
        self.m_droppingElements[row][col] = el
        el.m_row, el.m_col = row, col
    end
end

function PlayLayer:checkNeedSupported(el)
    local elPos = cc.p(el:getPosition())
    local row, col
    local judgeRange = 6 -- 跟相邻元素相交或者相距在一定的范围内，都认为紧贴相邻。

    --1.寻找上下左右的元素
    row, col = self:positionToMatrix(elPos.x - self.elSize.width, elPos.y)
    local left = self.m_elements[row][col]
    if left and math.abs(left:getPositionY() - el:getPositionY()) > judgeRange then left = nil end

    row, col = self:positionToMatrix(elPos.x + self.elSize.width, elPos.y)
    local right = self.m_elements[row][col]
    if right and math.abs(right:getPositionY() - el:getPositionY()) > judgeRange then right = nil end

    row, col = self:positionToMatrix(elPos.x, elPos.y + self.elSize.height / 2 + judgeRange)
    local up = self.m_elements[row][col]

    row, col = self:positionToMatrix(elPos.x, elPos.y - self.elSize.height / 2 - judgeRange)
    local down = self.m_elements[row][col]

    --2.下方有supported的元素，或者左,右,上有supported的且type一样的元素，或已经掉到最后一行，都停止掉落
    local isSopported = false
    if left and left.m_type == el.m_type and left:isStable()then
        isSopported = true
    end

    if right and right.m_type == el.m_type and right:isStable() then
        isSopported = true
    end

    if up and up.m_type == el.m_type and up:isStable() then
        isSopported = true
    end

    if down and down:isStable() then
        isSopported = true
    end
    
    if el.m_row == 1 then
        isSopported = true
    end

    --4.将尽可能多的dropping元素设置为supported，即使有些特殊情况没考虑到，会在下次判断的时候，进行修正。这样做可以让地图检测快速收敛（越多的supported,下次检测越少）。  
    --将上下左右相邻的，能固定住的也用广度优先固定
    if not isSopported then
        return
    end

    self:forEachElementOfMatrix(self.m_droppingElements, function (el) el.reached = false end)
    local supportedQueue = {el}
    
    while #supportedQueue > 0 do
        local curr = supportedQueue[1]
        table.remove(supportedQueue,1)
        
        if not curr.reached then
            local droppingNeighbours = {
                up =  self.m_droppingElements[curr.m_row+1][curr.m_col],
                down = self.m_droppingElements[curr.m_row-1][curr.m_col],
                left = self.m_droppingElements[curr.m_row][curr.m_col-1],
                right = self.m_droppingElements[curr.m_row][curr.m_col+1]
            }

            for key, neighbour in pairs(droppingNeighbours) do
                if neighbour then

                    if (key == 'up' and not neighbour:isStable()) or
                        (key ~= 'up' and not neighbour:isStable() and neighbour.m_type == curr.m_type) then

                        table.insert(supportedQueue,neighbour)
                    end
                end
            end

            --处理当前元素
            self.m_droppingElements[curr.m_row][curr.m_col] = nil
            self.m_elements[curr.m_row][curr.m_col] = curr
            curr:setRotation(0)
            curr.reached = true
            local destPos = cc.p(self:matrixToPosition(curr.m_row,curr.m_col))
            curr.fsm_:doEvent("support", destPos)   --drop to load
        end
    end
end

function PlayLayer:checkNeedRemove(el)
    if not el.needCheckRemove then return end
    
    local block = self:getBlock(el)
    if #block < 4 then
        --需要检查，个数却不足3，则标志置为false，避免下次检查
        for _, element in ipairs(self:getBlock(el)) do
            element.needCheckRemove = false
        end
        return
     end
    
    self:removeElement(el)
--    for _, element in ipairs(self:getBlock(el)) do
--        self.m_elements[element.m_row][element.m_col] = nil
--        self.m_droppingElements[element.m_row][element.m_col] = nil
--        element.fsm_:doEvent("destroy")
--    end
    
--    self.needDropUnSupported = true
end

function PlayLayer:checkNeedPushBelow(el)
    --正在drop的元素，下方有shaking的元素，需要让其停止shake，直接drop
    local down = self.m_droppingElements[el.m_row-1][el.m_col]
    if down and down:getState() == 'SHAKE' and el:getState() == 'DROP' then
        if el:getPositionY() - down:getPositionY() < self.elSize.height then
            down.fsm_:doEvent("push")
        end
    end
end

function PlayLayer:checkDroppingElements()

    self:forEachElementOfMatrix(self.m_droppingElements, function (el)
        self:refreshPosInDroppingMatrix(el)
        self:checkNeedSupported(el)
        if not el:isStable() then self:checkNeedPushBelow(el) end
        --        self:checkNeedRemove(el)    有的元素已经在checkNeedSupported时移除m_droppingElements了，会导致消除不了。因此放在下面的循环做
    end)
    
    self:forEachElementOfMatrix(self.m_elements, function (el)
        self:checkNeedRemove(el)
    end)
--    
--    --若有消除了的元素，则需要重新drop相关元素。
--    if self.needDropUnSupported == true then
--        self:dropUnSupported()
--        self.needDropUnSupported = false
--    end
end

function PlayLayer:forEachElementOfMatrix(matrix, callback, userData)
    for row=1, self.mapSize.y do
        for col=1, self.mapSize.x do
            if matrix[row][col] then
                callback(matrix[row][col], userData)
            end
        end
    end
end

function PlayLayer:rollMap(event)
    local playerPos = event.playerPos
    local pos = self.map:convertToNodeSpace(playerPos)
    local row,col = self:positionToMatrix(pos.x, pos.y)
    
    local lines = row - 1
    for i=row-1 < self.mapSize.y and row-1 or self.mapSize.y, 1, -1 do
        if self.m_elements[i][col] or (self.m_droppingElements[i][col]) then-- and "SHAKE" == self.m_droppingElements[i][col]:getState()) then
            lines = (row-1) - i
            break
        end
    end
    if 0 == lines then return end
    
    self:addLines(lines)
    local diff = cc.p(0, lines*self.elSize.height)
    local moveSpeed = 0.4 --移动100像素用时，跟元素块掉落的速度一样。
    local duration = diff.y / 100 * 0.4

    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    local dropEvent = cc.EventCustom:new("Dropping")
    dropEvent.active = true
    eventDispatcher:dispatchEvent(dropEvent)
    
    local moveAction = cc.Sequence:create(
        cc.MoveBy:create(duration,diff),
        cc.CallFunc:create(function()
            local dropEvent = cc.EventCustom:new("Dropping")
            dropEvent.active = false
            eventDispatcher:dispatchEvent(dropEvent)
            
            self:removeLines()
        end))
    
    self.map:runAction(moveAction)
end

function PlayLayer:addLines(cnt)
    --更新界面
    local event = cc.EventCustom:new("update hub")
    event.type = 'score'
    event.data = cnt*10
    cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
    local event = cc.EventCustom:new("update hub")
    event.type = 'deepth'
    event.data = cnt
    cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)

    --在下方增加层
    local screenLeftDown = self.map:convertToNodeSpace(cc.p(0,0))
    local LinesUnderScreen, _ = self:positionToMatrix(screenLeftDown.x, screenLeftDown.y)
    cnt = cnt > LinesUnderScreen and cnt-LinesUnderScreen or 0
    assert(LinesUnderScreen<10,'LinesUnderScreen'..LinesUnderScreen..' is bigger than 2')
    
    self:forEachElementOfMatrix(self.m_elements, function(el) el.m_row = el.m_row + cnt end)
    self:forEachElementOfMatrix(self.m_droppingElements, function(el) el.m_row = el.m_row + cnt end)
    self.mapOriginPoint.y = self.mapOriginPoint.y - cnt * self.elSize.height
    self.mapSize.y = self.mapSize.y + cnt
    
    for row=1, cnt do
        local newLine = {}
        for col=1, self.mapSize.x do
            local el = Element:new():create(row, col)
            el:setPosition(cc.p(self:matrixToPosition(row,col)))
            el:setScale(self.elSize.width/el:getContentSize().width, self.elSize.height/el:getContentSize().height)
            el:addTo(self.map)
            newLine[col] = el
        end
        table.insert(self.m_elements,row,newLine)
        table.insert(self.m_droppingElements,row,{})
    end
end

function PlayLayer:removeLines()
    local screenLeftUp = self.map:convertToNodeSpace(cc.p(0,display.height))
    local row, _ = self:positionToMatrix(screenLeftUp.x, screenLeftUp.y)
    local LinesOverScreen = self.mapSize.y - row
    cnt = LinesOverScreen > 0 and LinesOverScreen or 0
    assert(LinesOverScreen<10,'LinesOverScreen'..LinesOverScreen..' is bigger than 2')
    
    for row = self.mapSize.y, self.mapSize.y - (cnt-1), -1 do
        for col=1, self.mapSize.x do
            if self.m_elements[row][col] then
                self.m_elements[row][col]:removeFromParent(true)
            end
            if self.m_droppingElements[row][col] then
                self.m_droppingElements[row][col]:removeFromParent(true)
            end

        end
        table.remove(self.m_elements, row)
        table.remove(self.m_droppingElements, row)
    end

    self.mapSize.y = self.mapSize.y - cnt
end

function PlayLayer:detectMap(event)
    local playerPos = event.playerPos
    local pos = self.map:convertToNodeSpace(playerPos)
    local row,col = self:positionToMatrix(pos.x, pos.y)
    event.env = {}
    
    if row > self.mapSize.y + 1 then    --人物born的特殊情况，防止m_elements一维越界，产生异常。
        event.env.down = nil 
        return
    end
    
    if col <= 1 then event.env.left = 'wall'
    elseif self.m_elements[row][col-1] then event.env.left = self.m_elements[row][col-1]
    elseif self.m_droppingElements[row][col-1] then event.env.left = self.m_droppingElements[row][col-1]
    else event.env.left = nil
    end
    
    if col >= self.mapSize.x then event.env.right = 'wall'
    elseif self.m_elements[row][col+1] then event.env.right = self.m_elements[row][col+1]
    elseif self.m_droppingElements[row][col+1] then event.env.right = self.m_droppingElements[row][col+1]
    else event.env.right = nil
    end

    if self.m_elements[row-1][col] then event.env.down = self.m_elements[row-1][col] --or (self.m_droppingElements[row-1][col]) then-- and "SHAKE" == self.m_droppingElements[row-1][col]:getState()) then
    elseif self.m_droppingElements[row-1][col] then event.env.down = self.m_droppingElements[row-1][col]
    else event.env.down = nil
    end
    
    if self.m_elements[row][col] then event.env.center = self.m_elements[row][col]
    elseif self.m_droppingElements[row][col] then event.env.center = self.m_droppingElements[row][col]
    else event.env.center = nil
    end
end

function PlayLayer:digAt(event)
--    local playerPos = event.playerPos
--    local digDir = event.digDir
--    
--    local pos = self.map:convertToNodeSpace(playerPos)
--    local row,col = self:positionToMatrix(pos.x, pos.y)
--    
--    local el
--    if digDir == 'down' then
--        el = self.m_elements[row-1][col]
--    elseif digDir == 'left' then
--        el = self.m_elements[row][col-1]
--    elseif digDir == 'right' then
--        el = self.m_elements[row][col+1]
--    elseif digDir == 'center' then
--        el = self.m_elements[row][col]
--    end
--    
--    self:removeElement(el)

    local target = event.target
    if target:isStable() then --self.m_elements[target.m_row][target.m_col] then
        --地面上的元素
        self:removeElement(target)
    else
        --正在shake或者drop的元素
        self.m_elements[target.m_row][target.m_col] = nil
        self.m_droppingElements[target.m_row][target.m_col] = nil
        target.fsm_:doEvent("destroy")
    end
end

function PlayLayer:matrixToPosition(row, col)
    local x = self.mapOriginPoint.x + self.elSize.width * (col - 1 + 0.5)
    local y = self.mapOriginPoint.y + self.elSize.height * (row - 1 + 0.5)
    return x, y
end

function PlayLayer:positionToMatrix(x, y)
    local row = math.ceil((y - self.mapOriginPoint.y) / self.elSize.height)
    local col = math.ceil((x - self.mapOriginPoint.x) / self.elSize.width)
--
--    if row > self.mapSize.y or row < 1 then
--        row = 0
--    end
--
--    if col > self.mapSize.x or col < 1 then
--        col = 0
--    end

    return row, col
end