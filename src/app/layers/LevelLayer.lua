local DataManager = require("app.DataManager")
local DataManager = require("app.DataManager")
local LevelLayer   = class("LevelLayer", function()
    return display.newLayer("LevelLayer")
end)

---- 升级界面
function LevelLayer:ctor()
 
       cc(self):addComponent("components.behavior.EventProtocol"):exportMethods()



        self.panel =   cc.ui.UIImage.new("ui/panel1.png")
        :align(display.CENTER, display.cx, display.cy)
        :addTo(self)

        cc.ui.UIImage.new("ui/uplevel.png")
        :align(display.LEFT_BOTTOM, 148, 416)
        :addTo(self.panel)


        cc.ui.UIPushButton.new({normal="ui/button.png",
        pressed ="ui/button.png",
        scale9 = false})
        :onButtonClicked(function()self:dispatchEvent({name = "JUMP_MAIN"})  end)
        :align(display.LEFT_BOTTOM, 128,30)
        :addTo(self.panel):addChild(cc.ui.UIImage.new("ui/sure.png"):align(display.LEFT_BOTTOM, 44, 14))
        
        
        self._lvup_tag = 299

        self:showData()
end


function LevelLayer:showData()

    print("LevelLayer:showData()")


    local node = self.panel:getChildByTag(self._lvup_tag)

    if  node then  node:removeAllChildren() else   node = display.newNode():addTo(self.panel,10,self._lvup_tag)  end 

    -- 4个升级项
    local _title_img = {"ui/luck.png","ui/power.png","ui/digge.png","ui/speed.png"}
    local _attr_index = {DataManager.LUCKLV,DataManager.HPLV,
                        DataManager.POWERLV,DataManager.SPEEDLV}
    local _level = {DataManager.get(DataManager.LUCKLV),DataManager.get(DataManager.HPLV),
                        DataManager.get(DataManager.POWERLV),DataManager.get(DataManager.SPEEDLV)}
                        
    -- 幸运
    for i = 1,4 do
        cc.ui.UIImage.new(_title_img[i])
            :align(display.LEFT_BOTTOM, 24, 138+71*(i-1))
            :addTo(node)

        -- 星级
        for j = 1, 5 do  
            local _img_star = nil
            if j<= _level[i] then  _img_star = "ui/star.png"  else  _img_star = "ui/stargroove.png" end
            cc.ui.UIImage.new(_img_star)
                :align(display.LEFT_BOTTOM, 109+35*(j-1), 140+71*(i-1))
                :addTo(node)
        end  



        local _nextLv = _level[i]+1  
        local _cost   = s_data.level["key".._nextLv].cost
        if _nextLv < 5  then
            local _button= cc.ui.UIPushButton.new({normal="ui/uplevelbutton.png",
                pressed ="ui/uplevelbutton.png",
                scale9 = false})
                :onButtonClicked(function() 
                    -- 升级操作
                    if DataManager.addGold(-_cost) then 
                        print(" udpate !!")
                      DataManager.set(_attr_index[i],_nextLv)
                        scheduler.performWithDelayGlobal(function ()self:showData() end, 0.1)
                    else
                        -- 金币不足
                        print("error ! gold not enough")
                    end  
                end)
                :align(display.LEFT_BOTTOM, 277,132+71*(i-1))                
            _button:addTo(node)  


            local _cost =  cc.ui.UILabel.new({
                UILabelType = cc.ui.UILabel.LABEL_TYPE_BM,
                font = "fonts/r.fnt",                    
                text =  _cost,
                align = cc.ui.TEXT_ALIGN_RIGHT,
                color = display.COLOR_BLACK,
                x = 63,
                y = 26,
            }):addTo(_button)
            _cost:setScale(0.5)
        end
    end  
end

return LevelLayer
