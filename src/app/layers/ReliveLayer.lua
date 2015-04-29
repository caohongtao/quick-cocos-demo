local DataManager = require("app.DataManager")
local Relive   = class("Relive", function()
    return display.newLayer("Relive")
end)

----原地复活界面
function Relive:ctor(settlementInfo)
    self.settlementInfo = settlementInfo
       cc(self):addComponent("components.behavior.EventProtocol"):exportMethods()

    -- 开始游戏按键
      local panel =   cc.ui.UIImage.new("ui/panel2.png")
        :align(display.CENTER, display.cx, display.cy)
        :addTo(self)

        cc.ui.UIImage.new("ui/yuandifuhuo.png")
                :align(display.LEFT_BOTTOM, 72, 265)
                :addTo(panel)
        cc.ui.UIImage.new("ui/groove.png")
                :align(display.LEFT_BOTTOM, 44 ,126)
                :addTo(panel)
        cc.ui.UIImage.new("ui/Diamonds.png")
        :align(display.LEFT_BOTTOM, 72 ,126)
        :addTo(panel)
        self.needDiamondLabel = cc.ui.UILabel.new({UILabelType = cc.ui.UILabel.LABEL_TYPE_BM, font = "fonts/r.fnt",})
            :align(display.LEFT_BOTTOM, 160, 145)
            :addTo(panel)
--        self.needDiamondLabel:setScale(0.6)
        self.needDiamondLabel:setString(math.pow(2,self.settlementInfo.relive))
        ---- 再来一局                 
        cc.ui.UIPushButton.new({normal="ui/button.png",
                                pressed ="ui/button2.png",
                                scale9 = false})                                
        :onButtonClicked(function()
--            self:dispatchEvent({name = "JUMP_END",params=event})           
            local event = {name = "GAME_END", params = self.settlementInfo}
            cc.Director:getInstance():popScene()
            self.gameScene:performWithDelay(function()
                cc.Director:getInstance():getRunningScene():dispatchEvent(event)   
            end,0.1)
        end)
        :align(display.LEFT_BOTTOM, 35,30)        
        :addTo(panel):addChild(cc.ui.UIImage.new("ui/zailaiyiju.png"):align(display.LEFT_BOTTOM, 24 ,18))
        
        


        -----复活
        cc.ui.UIPushButton.new({normal="ui/button.png",
                                pressed ="ui/button2.png",
                                scale9 = false})                                
        :onButtonClicked(function()
            -- 扣除point
            if DataManager.addPoint(-math.pow(2,self.settlementInfo.relive)) then 
--                self:dispatchEvent({name = "JUMP_BACK_GAME",params=event})
                cc.Director:getInstance():popScene()

                self.gameScene:performWithDelay(function()
                    local resumeEvent = cc.EventCustom:new("player rebirth")
                    cc.Director:getInstance():getEventDispatcher():dispatchEvent(resumeEvent)
                    
                    local event = cc.EventCustom:new("update hub")
                    event.type = 'gem'
                    cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
                end,0.1)
            else
                -- 钻石不足
                print("error ! point not enough")
            end    
        end)
        :align(display.LEFT_BOTTOM, 235,30)        
        :addTo(panel):addChild(cc.ui.UIImage.new("ui/fuhuo.png"):align(display.LEFT_BOTTOM, 50 ,18))
end


return Relive
