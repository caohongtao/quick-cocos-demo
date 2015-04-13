local DataManager = require("app.DataManager")
local AchivementLayer   = class("AchivementLayer", function()
    return display.newLayer("AchivementLayer")
end)

function AchivementLayer:ctor()
 
       cc(self):addComponent("components.behavior.EventProtocol"):exportMethods()

    -- 开始游戏按键
        cc.ui.UIPushButton.new({normal="img/replay1.png",
                                pressed ="img/replay2.png",
                                scale9 = false})
                                
        :setButtonSize(140, 45)
        :onButtonPressed(function(event)
            event.target:setScale(0.9)
        end)
        :onButtonRelease(function(event)
            event.target:setScale(1.0)
        end)
        :onButtonClicked(function()
            self:dispatchEvent({name = "GAME_START"})            
            print("start game")
            
            DataManager.set(DataManager.GOLD,DataManager.get(DataManager.GOLD)+20)
            
        end)
        :align(display.BOTTOM_CENTER, 240,83)
        :addTo(self)
        
        
        
end


return AchivementLayer
