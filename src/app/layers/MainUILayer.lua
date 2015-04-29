local SettingLayer = require("src.app.layers.SettingLayer")


local MainUILayer   = class("MainUILayer", function()
    return display.newLayer("MainUILayer")
end)

function MainUILayer:ctor()
 
       cc(self):addComponent("components.behavior.EventProtocol"):exportMethods()


       -- 背景
        cc.ui.UIImage.new("ui/cover.png")
        :align(display.CENTER, display.cx, display.cy)
        :addTo(self)

        

        -- 设置界面
         self._b = cc.ui.UIPushButton.new({normal="ui/player_ctl_btn.png",scale9 = false})
        :onButtonClicked(function()
            self:popSettingLayer()
        end)
        :align(display.BOTTOM_CENTER, 10,22)
        :addTo(self)


         -- 开始游戏按键
         self._b = cc.ui.UIPushButton.new({normal="ui/congxinkaishi.png",scale9 = false})
                :setButtonSize(140, 45)
                :onButtonPressed(function(event)
            event.target:setScale(0.9)
        end)
        :onButtonRelease(function(event)
            event.target:setScale(1.0)
        end)
        :onButtonClicked(function()
            self:getParent():dispatchEvent({name = "GAME_START"})
        end)

        :align(display.BOTTOM_CENTER, 240,83)
        :addTo(self)

end

function MainUILayer:popSettingLayer()
    if self.settingLayer == nil then
        self.settingLayer = SettingLayer.new()
        self.settingLayer:addTo(self)
    end

    self.settingLayer:setVisible(true)
end


function MainUILayer:shutDownSettingLayer()
    self.settingLayer:setVisible(false)
    self:removeChild(self.settingLayer)
    self.settingLayer = nil
end

return MainUILayer
