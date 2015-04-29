PlayLayer = class("PlayLayer",  function()
    return display.newLayer("PlayLayer")
end)
local JUDGE_RANGE = 6 -- 跟相邻元素相交或者相距在一定的范围内，都认为紧贴相邻。
function PlayLayer:ctor()
    self.map = nil
    self.mapSize = cc.p(MAP_WIDTH,MAP_HEIGHT)
    self.mapOriginPoint = cc.p(display.left+MAP_START_X, display.bottom+MAP_START_Y)

    self.elSize = nil

    self.m_elements = {}
    self.m_droppingElements = {}
    
    self.zPos = 0 --记录层数让后生成的元素显示层级在后。

    cc.SpriteFrameCache:getInstance():addSpriteFrames('sprite/elements.plist', 'sprite/elements.png')

    self:initMap()
    self:addChild(self.map)

    self.player = Player.new(self.elSize)
    self:addChild(self.player)

    self.boss = Boss.new(self.player)
    self.map:addChild(self.boss,1)

--    self:init()
end

function PlayLayer:init()

    local detectListener = cc.EventListenerCustom:create("detect_map", handler(self,self.detectMap))
    local digListener = cc.EventListenerCustom:create("dig_at", handler(self,self.digAt))
    local rollMapListener = cc.EventListenerCustom:create("roll_map", handler(self,self.rollMap))
    local removeListener = cc.EventListenerCustom:create("remove_element", function(event) self:removeAndDrop({event.el}) end)
    local BossAdvanceListener = cc.EventListenerCustom:create("boss_advance", handler(self,self.removeLines))
    local explode_Listener = cc.EventListenerCustom:create("bomb_explode", handler(self,self.bombExplode))
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(detectListener, self)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(digListener, self)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(rollMapListener, self)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(removeListener, self)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(BossAdvanceListener, self)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(explode_Listener, self)

    self:scheduleUpdateWithPriorityLua(handler(self, self.checkDroppingElements), 0)
--    self:scheduleUpdateWithPriorityLua(handler(self, self.showElementInfo), 0);

    self:initTouchListener()
    
    self.boss:init()
end

function PlayLayer:unscheduleAllTimers()
    self:unscheduleUpdate()
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
    self.map = cc.Node:create()
    
    Element:addAnimation()
    --以宽度为基准缩放
    local elActualSize = (display.width - self.mapOriginPoint.x * 2) / self.mapSize.x
    self.elSize = {width = elActualSize, height = elActualSize-6}

    for row=1, self.mapSize.y do
        self.m_elements[row] = {}
        for col=1, self.mapSize.x do
            local el = Element:new():create(row, col)
            el:setPosition(cc.p(self:matrixToPosition(row,col)))
            el:setScale(self.elSize.width/el:getContentSize().width)
            el:addTo(self.map)
            self.m_elements[row][col] = el
        end
    end
    self.m_elements[0], self.m_elements[self.mapSize.y + 1] = {}, {} --为了后面self.m_elements[row][col]获取方便，行号越界直接返回nil，而不是异常
    self.zPos = self.zPos - 1
    
    for row=1, self.mapSize.y do
        self.m_droppingElements[row] = {}
        for col=1, self.mapSize.x do
            self.m_droppingElements[row][col] = nil
        end
    end
    self.m_droppingElements[0], self.m_droppingElements[self.mapSize.y + 1] = {}, {}
end

function PlayLayer:removeElement(el)
    self.m_elements[el.m_row][el.m_col] = nil
    self.m_droppingElements[el.m_row][el.m_col] = nil
    el.fsm_:doEvent("destroy")
end

function PlayLayer:removeAndDrop(block)

    --1.标记依赖于el的unsupported的元素。
    --递归地把周围同色元素及上方元素都认为失去支点，需要掉落。可能会有个别元素误判，会在checkDroppingElements时修正，很快从idle->shake->idle。

    local unSupportedQueue = {}
    table.foreach(block, function (_,el) table.insert(unSupportedQueue,el) end) --deep copy

    self:forEachElementOfMatrix(self.m_elements, function (el) el.touched = false end)

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
                        (key ~= 'up' and curr.m_type.isBrick and neighbour.m_type == curr.m_type) then

                        table.insert(unSupportedQueue,neighbour)
                    end
                end
            end

            --处理当前元素
            self.m_elements[curr.m_row][curr.m_col] = nil
            if self.m_droppingElements[curr.m_row][curr.m_col] then
            --防御性代码
                self.m_droppingElements[curr.m_row][curr.m_col].fsm_:doEvent("destroy")
            end
            self.m_droppingElements[curr.m_row][curr.m_col] = curr
            curr.touched = true
            curr.fsm_:doEvent("unSupport")
        end
    end

    --2.删除整片
    for _, element in ipairs(block) do
        self:removeElement(element)
    end
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
--        if row ~= el.m_row and self.m_droppingElements[row][col] ~= nil then
--            print('XXXXXXXXXXXXXXX掉落元素发生交错，'..self.m_droppingElements[row][col].fsm_:getState())
--        end
        
    if row ~= el.m_row and self.m_droppingElements[row][col] == nil then
        self.m_droppingElements[el.m_row][el.m_col] = nil
        self.m_droppingElements[row][col] = el
        el.m_row, el.m_col = row, col
    end
end

function PlayLayer:checkNeedSupported(el)
    local elPos = cc.p(el:getPosition())
    local row, col

    --1.寻找上下左右的元素
    row, col = self:positionToMatrix(elPos.x - self.elSize.width, elPos.y)
    local left = self.m_elements[row][col]
    if left and math.abs(left:getPositionY() - el:getPositionY()) > JUDGE_RANGE then left = nil end

    row, col = self:positionToMatrix(elPos.x + self.elSize.width, elPos.y)
    local right = self.m_elements[row][col]
    if right and math.abs(right:getPositionY() - el:getPositionY()) > JUDGE_RANGE then right = nil end

    row, col = self:positionToMatrix(elPos.x, elPos.y + self.elSize.height / 2 + JUDGE_RANGE)
    local up = self.m_elements[row][col]

    row, col = self:positionToMatrix(elPos.x, elPos.y - self.elSize.height / 2 - JUDGE_RANGE)
    local down = self.m_elements[row][col]

    --2.下方有supported的元素，或者左,右,上有supported的且type一样(且为砖块)的元素，或已经掉到最后一行，都停止掉落
    local isSopported = false
    if left and (left.m_type == el.m_type and el.m_type.isBrick) and left:isStable()then
        isSopported = true
    end

    if right and (right.m_type == el.m_type and el.m_type.isBrick) and right:isStable() then
        isSopported = true
    end

    if up and (up.m_type == el.m_type and el.m_type.isBrick) and up:isStable() then
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
                        (key ~= 'up' and not neighbour:isStable() and (neighbour.m_type == curr.m_type and curr.m_type.isBrick)) then

                        table.insert(supportedQueue,neighbour)
                    end
                end
            end

            --处理当前元素
            self.m_droppingElements[curr.m_row][curr.m_col] = nil
            if self.m_elements[curr.m_row][curr.m_col] then
                --防御性代码
                self.m_elements[curr.m_row][curr.m_col].fsm_:doEvent("destroy")
            end
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

    self:removeAndDrop(block)
end

function PlayLayer:checkNeedPushBelow(el)
    --正在drop的元素，下方有shaking的元素，需要让其停止shake，直接drop
    
--    local down = self.m_droppingElements[el.m_row-1][el.m_col]
--    if down and down:getState() == 'SHAKE' and el:getState() == 'DROP' then
--        if el:getPositionY() - down:getPositionY() < self.elSize.height + JUDGE_RANGE then
--            down.fsm_:doEvent("push")
--            el:setPositionY(down:getPositionY() + self.elSize.height)
--        end
--    end

    if el:getState() ~= 'DROP' then return end

    local row, col = el.m_row - 1, el.m_col
    local next = self.m_droppingElements[row][col]
    while next and next:getState() == 'SHAKE' do
        next.fsm_:doEvent("push")
        row = row - 1
        next = self.m_droppingElements[row][col]
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
        if el.m_type.isBrick then
            self:checkNeedRemove(el)
        end
    end)
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
        if (self.m_elements[i][col]         and self.m_elements[i][col].m_needDigTime > 0) or
           (self.m_droppingElements[i][col] and self.m_droppingElements[i][col].m_needDigTime > 0) then
            lines = (row-1) - i
            break
        end
    end
    
    if 0 == lines then
        print('rollMap err, 0 lines need to be rolled')
        local dropEvent = cc.EventCustom:new("Dropping")
        dropEvent.active = false
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(dropEvent)
    end

    self:addLines(lines)
    local diff = cc.p(0, lines*self.elSize.height)
    local dropSpeed = gamePara.baseDropDuration / DataManager.getCurrProperty('speed')
    local duration = diff.y / 100 * dropSpeed

    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    local dropEvent = cc.EventCustom:new("Dropping")
    dropEvent.active = true
    eventDispatcher:dispatchEvent(dropEvent)

    local moveAction = cc.Sequence:create(
        cc.MoveBy:create(duration,diff),
        cc.CallFunc:create(function()
            local dropEvent = cc.EventCustom:new("Dropping")
            dropEvent.active = false
            cc.Director:getInstance():getEventDispatcher():dispatchEvent(dropEvent)

            
            self:removeLines({bossPos = cc.p(display.cx, 1.3*display.cy)})
        end))

    self.map:runAction(moveAction)
end

function PlayLayer:addLines(cnt)
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
            el:setScale(self.elSize.width/el:getContentSize().width)
            el:setLocalZOrder(self.zPos)
            el:addTo(self.map)
            newLine[col] = el
        end
        table.insert(self.m_elements,row,newLine)
        table.insert(self.m_droppingElements,row,{})
    end
    
    self.zPos = self.zPos - 1
end

function PlayLayer:removeLines(event)
    local bossPos = self.map:convertToNodeSpaceAR(event.bossPos)
    local row, _ = self:positionToMatrix(bossPos.x, bossPos.y)
    local LinesOverBoss = self.mapSize.y - row
    local cnt = LinesOverBoss > 0 and LinesOverBoss or 0

    --    local screenLeftUp = self.map:convertToNodeSpace(cc.p(0,display.height))
    --    local row, _ = self:positionToMatrix(screenLeftUp.x, screenLeftUp.y)
    --    local LinesOverScreen = self.mapSize.y - row
    --    cnt = LinesOverScreen > 0 and LinesOverScreen or 0
    --    assert(LinesOverScreen<10,'LinesOverScreen'..LinesOverScreen..' is bigger than 2')

    for row = self.mapSize.y, self.mapSize.y - (cnt-1), -1 do
        for col=1, self.mapSize.x do
            if self.m_elements[row][col] then
                local el = self.m_elements[row][col]
                cc.Director:getInstance():getActionManager():removeAllActionsFromTarget(el)
                el:runAction(cc.Sequence:create(
                    cc.FadeOut:create(0.2 * (self.mapSize.y + 1 - row)),
                    cc.CallFunc:create(function()
                        el:removeFromParent(true)
                    end)))
--                self.m_elements[row][col]:removeFromParent(true)
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

    if row > self.mapSize.y + 1 then    --人物born的特殊情况，防止m_elements一维越界，产生异常。
        event.result = 'empty'
        return
    end

    if 'left' == event.direction then
        if col <= 1 then event.result = 'wall'
        elseif self.m_elements[row][col-1] then event.result, event.element ='element', self.m_elements[row][col-1]
        elseif self.m_droppingElements[row][col-1] then event.result, event.element ='element', self.m_droppingElements[row][col-1]
        else event.result = 'empty'
        end
    elseif 'right' == event.direction then
        if col >= self.mapSize.x then event.result = 'wall'
        elseif self.m_elements[row][col+1] then event.result, event.element ='element', self.m_elements[row][col+1]
        elseif self.m_droppingElements[row][col+1] then event.result, event.element ='element', self.m_droppingElements[row][col+1]
        else event.result = 'empty'
        end
        --    elseif 'up' == event.direction then

    elseif 'down' == event.direction then

        if self.m_elements[row-1][col] then event.result, event.element ='element', self.m_elements[row-1][col]
        elseif self.m_droppingElements[row-1][col] then event.result, event.element ='element', self.m_droppingElements[row-1][col]
        else event.result = 'empty'
        end
    elseif 'center' == event.direction then
        if self.m_elements[row][col] then event.result, event.element ='element', self.m_elements[row][col]
        elseif self.m_droppingElements[row][col] then event.result, event.element ='element', self.m_droppingElements[row][col]
        else event.result = 'empty'
        end
    end
end

function PlayLayer:digAt(event)
    local target = event.target
    local playerPos = event.playerPos

    --挖掘一整道元素
    if event.effect then
        local block = {}
        local pos = self.map:convertToNodeSpace(playerPos)
        local PlayerRow,PlayerCol = self:positionToMatrix(pos.x, pos.y) --穿透挖掘，有可能没有挖掘对象。所以位置要根据playerPos算

        --获取一道元素
        if 'left' == event.effect then
            for col=1, PlayerCol, 1 do
                if self.m_elements[PlayerRow][col] then table.insert(block,self.m_elements[PlayerRow][col]) end
                if self.m_droppingElements[PlayerRow][col] then table.insert(block,self.m_droppingElements[PlayerRow][col]) end
            end
        elseif 'right' == event.effect then
            for col=PlayerCol, self.mapSize.x, 1 do
                if self.m_elements[PlayerRow][col] then table.insert(block,self.m_elements[PlayerRow][col]) end
                if self.m_droppingElements[PlayerRow][col] then table.insert(block,self.m_droppingElements[PlayerRow][col]) end
            end
        elseif 'up' == event.effect then
            for row=PlayerRow, self.mapSize.y, 1 do
                if self.m_elements[row][PlayerCol] then table.insert(block,self.m_elements[row][PlayerCol]) end
                if self.m_droppingElements[row][PlayerCol] then table.insert(block,self.m_droppingElements[row][PlayerCol]) end
            end
        elseif 'down' == event.effect then
            for row=1, PlayerRow, 1 do
                if self.m_elements[row][PlayerCol] then table.insert(block,self.m_elements[row][PlayerCol]) end
                if self.m_droppingElements[row][PlayerCol] then table.insert(block,self.m_droppingElements[row][PlayerCol]) end
            end
        end
        self:removeAndDrop(block)
        
    --挖单个元素
    else
        --地面上的元素
        if target:isStable() then
            if target.m_type.isBrick then
                self:removeAndDrop(self:getBlock(target))
            else
                self:removeAndDrop({target})
            end
        --正在shake或者drop的元素,只删除单个而不是整块，并且不检查上方是否需要掉落
        else
            self:removeElement(target)
        end

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

--function PlayLayer:showTutorial()
--    local playerPos = self.player:convertToWorldSpaceAR(cc.p(0,0))
--    
--    self.tutorialLayer = display.newLayer()
--    self.tutorialLayer:setTouchSwallowEnabled(false)
--    self.tutorialLayer:addTo(self)
--
--    local leftRegion = display.newSprite('ui/touch_hint.png',display.cx-1,playerPos.y):addTo(self.tutorialLayer)
--    leftRegion:setAnchorPoint(cc.p(1,0))
--    leftRegion:setScale(2)
--
--    local rightRegion = display.newSprite('ui/touch_hint.png',display.cx+1,playerPos.y):addTo(self.tutorialLayer)
--    rightRegion:setAnchorPoint(cc.p(0,0))
--    rightRegion:setScale(2)
--
--    local downRegion = display.newSprite('ui/touch_hint.png',display.cx,playerPos.y-2):addTo(self.tutorialLayer)
--    downRegion:setAnchorPoint(cc.p(0.5,1))
--    downRegion:setScale(2)
--    
--    DataManager.set('tutorial_finished', true)
--    DataManager.save()
--end
--
--function PlayLayer:initTouchListener()
--    DataManager.set('tutorial_finished', false)
--    DataManager.save()
--    if not DataManager.get('tutorial_finished') then
--    	self:showTutorial()
--    end
--
--    local hint = display.newSprite('ui/touch_hint.png',display.cx,display.top - 100):addTo(self)
--    hint:setAnchorPoint(cc.p(0.5,0.5))
--    hint:setScale(2)
--    hint:setVisible(false)
--    
--    self:setTouchEnabled(true)
--    self:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
--    self:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
--        if event.name == "began" then
--            local touchPos = cc.p(event.x, event.y)
--            local playerPos = self.player:convertToWorldSpaceAR(cc.p(0,0))
--            
--            local touchDir = nil
--            if touchPos.y < playerPos.y then
--                touchDir = 'down'
--                hint:setRotation(0)
--            elseif touchPos.x < display.cx then
--                touchDir = 'left'
--                hint:setRotation(90)
--            else
--                touchDir = 'right'
--                hint:setRotation(-90)
--            end
--            
--            if self.tutorialLayer then self.tutorialLayer:removeFromParent(true) self.tutorialLayer = nil end
--            hint:setVisible(true)
--            hint:performWithDelay(function() hint:setVisible(false) end, 0.1)
--                
--            local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
--            local touchEvent = cc.EventCustom:new('handle_touch')
--            touchEvent.touchDir = touchDir
--            eventDispatcher:dispatchEvent(touchEvent)
--            return true
--        end
--    end)
--end
--
function PlayLayer:initTouchListener()
    local RADIUS = 32
    local btnPos = {
            left  = {x=150, y = 107,},
            down  = {x=252, y = 102,},
            right = {x=358, y = 103,},
          }
    local left  = display.newSprite('ui/leftArrow.png',btnPos.left.x,btnPos.left.y):addTo(self)
    left:setScale(RADIUS*2/left:getContentSize().height)
    left:setGlobalZOrder(10)
    
    local right = display.newSprite('ui/rightArrow.png',btnPos.right.x,btnPos.right.y):addTo(self)
    right:setScale(RADIUS*2/right:getContentSize().height)
    right:setGlobalZOrder(10)
        
    local down  = display.newSprite('ui/downArrow.png',btnPos.down.x,btnPos.down.y):addTo(self)
    down:setScale(RADIUS*2/down:getContentSize().height)
    down:setGlobalZOrder(10)
        

    self:setTouchEnabled(true)
    self:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
    self:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        if event.name == "began" then
            local touchPos = cc.p(event.x, event.y)
            local touchDir = nil

            if cc.pDistanceSQ(btnPos.left,touchPos) < RADIUS * RADIUS then
                touchDir = 'left'
            elseif cc.pDistanceSQ(btnPos.right,touchPos) < RADIUS * RADIUS then
                touchDir = 'right'
            elseif cc.pDistanceSQ(btnPos.down,touchPos) < RADIUS * RADIUS then
                touchDir = 'down'
            else
                return
            end
                
            local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
            local touchEvent = cc.EventCustom:new('handle_touch')
            touchEvent.touchDir = touchDir
            eventDispatcher:dispatchEvent(touchEvent)
            return true
        end
    end)
end

function PlayLayer:initTouchListener2()
    self:setTouchEnabled(true)
    self:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
    self:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)

            local OFFSET = 30
            local touchDir = nil        
            if event.name == "began"  then 

                if  self._ismoved  ~=true then 
                    self._ismoved  = true
                    self._prevX = event.x
                    self._prevY = event.y    
                end         
            end

            if event.name == "moved"  then 
                if  self._ismoved  ~=true then 
                    self._ismoved  = true
                    self._prevX = event.prevX
                    self._prevY = event.prevY    
                end     
            end   


            if event.name == "ended" then
                if math.abs(self._prevX - event.x) < math.abs(self._prevY - event.y)  and  self._prevY - event.y > OFFSET then
                    touchDir = 'down'
                elseif event.x < self._prevX  and  self._prevX - event.x > OFFSET then
                    touchDir = 'left'
                elseif event.x > self._prevX  and   event.x - self._prevX > OFFSET then
                    touchDir = 'right'
                end

                if touchDir then
                    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
                    local touchEvent = cc.EventCustom:new('handle_touch')
                    touchEvent.touchDir = touchDir
                    eventDispatcher:dispatchEvent(touchEvent)    
                end
                self._ismoved  = false
            end
            return true
    end)
end

function PlayLayer:bombExplode(event)
    local bomb = event.el
    local row,col = self:positionToMatrix(bomb:getPosition())
    
    local grids = {}
    for c=1, self.mapSize.x do
        if self.m_elements[row] and self.m_elements[row][c] then
            table.insert(grids,self.m_elements[row][c])
        elseif self.m_droppingElements[row] and self.m_droppingElements[row][c] then
            self:removeElement(self.m_droppingElements[row][c])
        end
    end
    self:removeAndDrop(grids)
end