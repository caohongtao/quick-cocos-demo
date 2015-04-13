local DataManager = require("app.DataManager")
local MainUILayer   = class("MainUILayer", function()
    return display.newLayer("MainUILayer")
end)

function MainUILayer:ctor()
 
       cc(self):addComponent("components.behavior.EventProtocol"):exportMethods()

    -- 开始游戏按键
        cc.ui.UIPushButton.new({normal="ui/replay1.png",
                                pressed ="ui/replay2.png",
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
            
--            DataManager.set(DataManager.GOLD,DataManager.get(DataManager.GOLD)+20)
            
        end)
        :align(display.BOTTOM_CENTER, 240,83)
        :addTo(self)
        
        
        
end


return MainUILayer
