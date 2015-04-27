local MainUILayer   = class("MainUILayer", function()
    return display.newLayer("MainUILayer")
end)

function MainUILayer:ctor()
 
       cc(self):addComponent("components.behavior.EventProtocol"):exportMethods()
   
         -- 开始游戏按键
         self._b = cc.ui.UIPushButton.new({normal="ui/congxinkaishi.png",
--        pressed ="ui/replay2.png",
        scale9 = false})

        :setButtonSize(140, 45)
        :onButtonPressed(function(event)
            event.target:setScale(0.9)
        end)
        :onButtonRelease(function(event)
            event.target:setScale(1.0)
        end)
        :onButtonClicked(function()
        
            --            self:dispatchEvent({name = "GAME_END",
            --                saves = 3, -- 救动物
            --                use1=1,  -- 使用物品
            --                use2=2,
            --                use3=1,
            --                atkboss=0, -- 击退boss
            --                dizzboss=0,-- 晕眩boss
            --                box=2,     -- 宝箱数
            --                golds=3,   -- 金币数
            --                grounds=58, -- 层数
            --            })            
            --            print(" game  -  end  ")
    

--            self:dispatchEvent({name = "GAME_START"})
            audio.playMusic('audio/gameSceneBG.mp3',true)
            audio.setMusicVolume(0.2)
            audio.pauseMusic()
            self:getParent():dispatchEvent({name = "GAME_START"})
        end)

        :align(display.BOTTOM_CENTER, 240,83)
        :addTo(self)
end


return MainUILayer
