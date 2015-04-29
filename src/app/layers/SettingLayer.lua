local SettingLayer   = class("SettingLayer", function()
    return display.newLayer("SettingLayer")
end)

function SettingLayer:ctor(event)
 
       cc(self):addComponent("components.behavior.EventProtocol"):exportMethods()

        
 
      local panel =   cc.ui.UIImage.new("ui/panel2.png")
        :align(display.CENTER, display.cx , display.cy)
        :addTo(self)

        cc.ui.UIImage.new("ui/setting.png")
        :align(display.LEFT_BOTTOM, 137, 270)
        :addTo(panel)


        -- "游戏音乐"
        cc.ui.UIImage.new("ui/backgroundmusic.png")
        :align(display.LEFT_BOTTOM, 39, 185)
        :addTo(panel)
        --游戏音效
        cc.ui.UIImage.new("ui/gamemusic.png")
        :align(display.LEFT_BOTTOM, 39, 95)
        :addTo(panel)

        
        local _img = nil

        -- 开关1
        if DataManager.get(DataManager.MUSIC_ON) == 1 then  _img = "ui/on.png" else _img = "ui/off.png" end

        self.music_btn = cc.ui.UIPushButton.new({normal=_img,
                                pressed =_img,
                                scale9 = false})                                
        :onButtonClicked(function()
            -- 切换        
            scheduler.performWithDelayGlobal(function () self:musicOffOn() end, 0.1)
        end)
        :align(display.LEFT_BOTTOM, 234,160)
        :addTo(panel)

        -- 开关2
        if DataManager.get(DataManager.SOUND_ON) == 1 then  _img = "ui/on.png" else _img = "ui/off.png" end
        self.sound_btn = cc.ui.UIPushButton.new({normal=_img,
                                pressed =_img,
                                scale9 = false})                                
        :onButtonClicked(function()
            -- 切换     
            scheduler.performWithDelayGlobal(function () self:soundOffOn() end, 0.1)   
        end)
        :align(display.LEFT_BOTTOM, 234,75)
        :addTo(panel)


        -- 关闭按钮
            cc.ui.UIPushButton.new({normal="ui/x.png",
        pressed ="ui/x.png",
        scale9 = false})
        :onButtonClicked(
            function() self:getParent():shutDownSettingLayer()  end)
        :align(display.LEFT_BOTTOM, 373,358)
        :addTo(panel)
end


function SettingLayer:musicOffOn()
    -- body
    local _img = nil

    if DataManager.get(DataManager.MUSIC_ON) == 1 then
       DataManager.set(DataManager.MUSIC_ON,0) 
        _img = "ui/off.png" 
        -- 关闭正在播放的music
        audio.setMusicVolume(0)
    else 
        DataManager.set(DataManager.MUSIC_ON,1) 
        _img = "ui/on.png" 
        audio.setMusicVolume(0.3)
        audio.myPlayMusic('audio/mainSceneBG.mp3', true)
    end
    self.music_btn:setButtonImage(cc.ui.UIPushButton.NORMAL, _img, true)
    self.music_btn:setButtonImage(cc.ui.UIPushButton.PRESSED, _img, true)    
end

function SettingLayer:soundOffOn()
    -- body
    local _img = nil

    if DataManager.get(DataManager.SOUND_ON) == 1 then
       DataManager.set(DataManager.SOUND_ON,0) 
        _img = "ui/off.png" 
        audio.setSoundsVolume(0)
    else 
        DataManager.set(DataManager.SOUND_ON,1) 
        _img = "ui/on.png" 
        audio.setSoundsVolume(1.0)
    end
    self.sound_btn:setButtonImage(cc.ui.UIPushButton.NORMAL, _img, true)
    self.sound_btn:setButtonImage(cc.ui.UIPushButton.PRESSED, _img, true)    
end


return SettingLayer
