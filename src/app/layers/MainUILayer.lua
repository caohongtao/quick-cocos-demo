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

        self._ui_panel = display.newNode():addTo(self)

        -- 设置按钮
         self._setting_btn = cc.ui.UIPushButton.new({normal="ui/Upgrade.png",pressed = "ui/Upgrade2.png",scale9 = false})
        :onButtonClicked(function()
            self:popSettingLayer()
        end)
        :align(display.BOTTOM_CENTER, 390,592)
        :addTo(self._ui_panel)

        -- 礼包按钮
         self._gift_btn = cc.ui.UIPushButton.new({normal="ui/Package.png",pressed = "ui/Package2.png",scale9 = false})
        :onButtonClicked(function()
            self:popSettingLayer()
        end)
        :align(display.BOTTOM_CENTER, 116,592)
        :addTo(self._ui_panel)

        -- 成就按钮
         self._achive_btn = cc.ui.UIPushButton.new({normal="ui/Achievement.png",pressed = "ui/Achievement2.png",scale9 = false})
        :onButtonClicked(function()
            self:popSettingLayer()
        end)
        :align(display.BOTTOM_CENTER, 247,592)
        :addTo(self._ui_panel)

        -- 金币
        cc.ui.UIImage.new("ui/gold_frame.png")
        :align(display.LEFT_BOTTOM, 100,751)
        :addTo(self._ui_panel)        

        -- 钻石
        cc.ui.UIImage.new("ui/point_frame.png")
        :align(display.LEFT_BOTTOM, 280,751)
        :addTo(self._ui_panel)

        cc.ui.UIPushButton.new({normal="ui/plus.png",pressed = "ui/plus2.png",scale9 = false})
        :onButtonClicked(function()
            -- 弹出充值
        end)
        :align(display.BOTTOM_CENTER, 442,753)
        :addTo(self._ui_panel)


         -- 开始游戏按键
         self._start_btn = cc.ui.UIPushButton.new({normal="ui/congxinkaishi.png",scale9 = false})
                :setButtonSize(140, 45)
                :onButtonPressed(function(event)
            event.target:setScale(0.9)
        end)
        :onButtonRelease(function(event)
            event.target:setScale(1.0)
        end)
        :onButtonClicked(function()
            cc.Director:getInstance():getEventDispatcher():dispatchEvent(cc.EventCustom:new("GAME_START"))
        end)

        :align(display.BOTTOM_CENTER, 240,83)
        :addTo(self._ui_panel)

end


function MainUILayer:hideUI()
    -- body
    self._ui_panel:setVisible(false)
end

function MainUILayer:showUI()
    -- body
    self._ui_panel:setVisible(true)
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