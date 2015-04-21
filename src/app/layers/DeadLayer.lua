DeadLayer = class("DeadLayer",  function()
    return display.newLayer("DeadLayer")
end)

function DeadLayer:ctor()
    self.timeLeft = 10

    --买活按钮
    cc.ui.UIPushButton.new()
        :align(display.CENTER, display.cx, display.cy)
        :setButtonLabel("normal", cc.ui.UILabel.new({
            UILabelType = 2,
            text = "花2元钱复活",
            size = 60,
            color = display.COLOR_BLACK,
            font = "Times New Roman",
        }))
        :onButtonClicked(function(event)
            print("player rebirth")

--            local queue = {self:getParent()}
--            while #queue > 0 do
--                local nodes = queue[1]:getChildren()
--                for _, node in ipairs(nodes) do
--                    if node == self then
--                        node:setVisible(false)
--                        node:stopCount()
--                    else
--                        table.insert(queue,node)
--                    end
--                end
--                queue[1]:resume()
--                table.remove(queue,1)
--            end
        
--            self:removeFromParent(true)
--            display.resume()

            cc.Director:getInstance():popScene()
            
            self.gameScene:performWithDelay(function()
                local resumeEvent = cc.EventCustom:new("player rebirth")
                cc.Director:getInstance():getEventDispatcher():dispatchEvent(resumeEvent)
            end,0.1)
        end)
        :addTo(self)
        
    --倒计时
    self.timeLable = cc.ui.UILabel.new({
            text        = "10",
            font        = "Times New Roman",
            size        = 100,
            color       = display.COLOR_BLACK,
            x           = display.cx,
            y           = display.cy+200,
        })
        :align(display.CENTER)
        :addTo(self)
        
--    self:setVisible(false)
    self:startCount()
end

function DeadLayer:startCount()
    self.timeLeft = 10
    self.timeLable:setString(self.timeLeft)
    
    self.countDownAction = cc.RepeatForever:create(cc.Sequence:create(
        cc.DelayTime:create(1),
        cc.CallFunc:create(function()
            if self.timeLeft == 0 then
--                self:stopCount()
                self:gameEnd()
            end
            self.timeLeft = self.timeLeft - 1
            self.timeLable:setString(self.timeLeft)
        end)))
    self:runAction(self.countDownAction)
end
--
--function DeadLayer:stopCount()
--    self:stopAction(self.countDownAction)    --确保下次弹出时，从10重新开始
--end

function DeadLayer:gameEnd()

    --    DataManager.set(DataManager.GOLD, DataManager.get(DataManager.GOLD) + self.coins)
    --    DataManager.set(DataManager.POINT, DataManager.get(DataManager.POINT) + self.gems)
    --    DataManager.set(DataManager.TOPGROUD, DataManager.get(DataManager.TOPGROUD) > self.score and DataManager.get(DataManager.TOPGROUD) or self.deepth)
    --    DataManager.set(DataManager.TOP_SCORE, DataManager.get(DataManager.TOP_SCORE) > self.score and DataManager.get(DataManager.TOP_SCORE) or self.score)
    
    local gameEndEvent = {}
    gameEndEvent.saves = 0
    gameEndEvent.use1 = 0
    gameEndEvent.use2 = 0
    gameEndEvent.use3 = 0
    gameEndEvent.atkboss = 0
    gameEndEvent.dizzboss = 0
    gameEndEvent.box = 0
    gameEndEvent.golds = 0
    gameEndEvent.grounds = 0
    
    cc.Director:getInstance():popScene()
    self.gameScene:performWithDelay(function()
        cc.Director:getInstance():getRunningScene():dispatchEvent({name = "GAME_END", event = gameEndEvent})   
    end,0.1)
end