local DataManager = require("app.DataManager")
local Relive   = class("Relive", function()
    return display.newLayer("Relive")
end)

----原地复活界面
function Relive:ctor(event)
 
       cc(self):addComponent("components.behavior.EventProtocol"):exportMethods()

    -- 开始游戏按键
      local panel =   cc.ui.UIImage.new("ui/yuandifuhuo.png")
        :align(display.LEFT_BOTTOM, display.cx -    430/2, display.cy-300)
        :addTo(self)
                         
        cc.ui.UIPushButton.new({normal="ui/zailaiyijv.png",
                                pressed ="ui/zailaiyijv.png",
                                scale9 = false})                                
        :onButtonClicked(function()
            self:dispatchEvent({name = "JUMP_END",params=event})           
        end)
        :align(display.LEFT_BOTTOM, 230,30)
        :addTo(panel)
        
        
        cc.ui.UIPushButton.new({normal="ui/fuhuo.png",
                                pressed ="ui/fuhuo.png",
                                scale9 = false})                                
        :onButtonClicked(function()
            -- 扣除point
            if DataManager.addPoint(-10) then 
                self:dispatchEvent({name = "JUMP_BACK_GAME",params=event})    
            else
                -- 钻石不足
                print("error ! point not enough")
            end    
        end)
        :align(display.LEFT_BOTTOM, 42,30)
        :addTo(panel)
end


return Relive
