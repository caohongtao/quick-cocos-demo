local AchivementLayer   = class("AchivementLayer", function()
    return display.newLayer("AchivementLayer")
end)

function AchivementLayer:ctor(event)

    cc(self):addComponent("components.behavior.EventProtocol"):exportMethods()

    -- _tmp_rounds      = DataManager.get("_tmp_rounds")
    -- _tmp_grounds     = DataManager.get("_tmp_grounds")
    -- _tmp_save_animal = DataManager.get("_tmp_save_animal")
    -- _tmp_use_item_1  = DataManager.get("_tmp_use_item_1")
    -- _tmp_use_item_2  = DataManager.get("_tmp_use_item_2")
    -- _tmp_use_item_3  = DataManager.get("_tmp_use_item_3")
    -- _tmp_atk_boss    = DataManager.get("_tmp_atk_boss")
    -- _tmp_dizz_boss   = DataManager.get("_tmp_dizz_boss")

    self.panel =   cc.ui.UIImage.new("ui/panel1.png")
        :align(display.CENTER, display.cx, display.cy)
        :addTo(self)

    cc.ui.UIImage.new("ui/chengjiu.png")
    :align(display.LEFT_BOTTOM, 148, 416)
    :addTo(self.panel)

    cc.ui.UIPushButton.new({normal="ui/x.png",
        pressed ="ui/x.png",
        scale9 = false})
        :onButtonClicked(
            function() self:dispatchEvent({name = "JUMP_LEVELUP"})  end)
        :align(display.LEFT_BOTTOM, 373,450)
        :addTo(self.panel)

     self.params = event
    
    self._achivements_tag = 599

    self:reflushData(self.params)

     self:showData()
end

function AchivementLayer:showData()

    print("AchivementLayer:showData()")
    
    local node = self.panel:getChildByTag(self._achivements_tag)
    
    if  node then  node:removeAllChildren() else node = display.newNode():addTo(self.panel,5,self._achivements_tag)  end 
    
    local i = 2
    for k,v in pairs(self._shownList) do

        cc.ui.UILabel.new({
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = string.gsub(v.desc, "@", v.sum),
            align = cc.ui.TEXT_ALIGN_LEFT,
            color = display.COLOR_BLACK,
            x = 48,
            y = 96+74*i,
        }):addTo(node)

        if v.finished then
            cc.ui.UIPushButton.new({normal="ui/wancheng.png",
                pressed ="ui/wancheng.png",
                scale9 = false})
                :onButtonClicked(function() self:finishedAchivement(v.id) end)
                :align(display.LEFT_BOTTOM, 260,86+74*i)
                :addTo(node)
        elseif v.achived then
            cc.ui.UIPushButton.new({normal="ui/lingqvjiangli.png",
                pressed ="ui/lingqvjiangli.png",
                scale9 = false})
                :onButtonClicked(function() self:finishedAchivement(v.id) end)
                :align(display.LEFT_BOTTOM, 260,86+74*i)
                :addTo(node)
        end

        cc.ui.UIImage.new("ui/line.png")
        :align(display.LEFT_BOTTOM, 40, 76+74*i)
        :addTo(node)

        i = i-1
    end
end



function AchivementLayer:finishedAchivement(id)

    print(" AchivementLayer:finishedAchivement(id) "..id)

    if s_data.achivement[id] then
        s_data.achivement[id].finished = true

        DataManager.achiveFinish(id)
        print("|给予奖励")
        --
        if s_data.achivement[id].award1 and s_data.achivement[id].award1 > 0 then DataManager.addGold(s_data.achivement[id].award1) end
        if s_data.achivement[id].award2 and s_data.achivement[id].award2 > 0 then DataManager.addPoint(s_data.achivement[id].award2) end

        -- 通知UI
        self:dispatchEvent({name = "REFLUSH_DATA"})
        
        -- 再次刷新成就列表
        scheduler.performWithDelayGlobal(function ()
            print("再次刷新成就列表")  
              
            self:reflushData(self.params)
    
            self:showData()
        end, 0.1)
    end
end


function AchivementLayer:reflushData(event)

    self._shownList = {}
    -- 扫描成就
   
    for k, v in pairs(s_data.achivement) do
        if v.finished ~=true  then
            if v.type ==1 then
                if DataManager.get(DataManager.GOLD) >= v.sum then v.achived = true  if #self._shownList<3 then table.insert(self._shownList,v) end end
            elseif v.type ==2 then
                if DataManager.get(DataManager.TOPGROUD) >= v.sum then v.achived = true if #self._shownList<3 then table.insert(self._shownList,v)end end
            elseif v.type ==3 then
                if DataManager.get(DataManager.TOP_SCORE) >= v.sum then v.achived = true if #self._shownList<3 then table.insert(self._shownList,v)end  end
            elseif v.type ==4 then
                if DataManager.get(DataManager.SAVES) >= v.sum then v.achived = true if #self._shownList<3 then table.insert(self._shownList,v)end  end
            elseif v.type ==5 then
                if DataManager.get(DataManager.GAIN_BOX) >= v.sum then v.achived = true if #self._shownList<3 then table.insert(self._shownList,v)end  end
            elseif v.type ==6 then
                if event and event.relive >= v.sum then v.achived = true if #self._shownList<3 then table.insert(self._shownList,v)end  end
            elseif v.type ==7 then
                if event and  event.use1 >= v.sum then v.achived = true if #self._shownList<3 then table.insert(self._shownList,v)end  end
            elseif v.type ==8 then
                if event and  event.use2 >= v.sum then v.achived = true if #self._shownList<3 then table.insert(self._shownList,v)end  end
            elseif v.type ==9 then
                if event and  event.use3 >= v.sum then v.achived = true if #self._shownList<3 then table.insert(self._shownList,v)end  end
            elseif v.type ==10 then
                if DataManager.get(DataManager.SPEEDLV) >= v.sum then v.achived = true if #self._shownList<3 then table.insert(self._shownList,v)end  end
            elseif v.type ==11 then
                if DataManager.get(DataManager.POWERLV) >= v.sum then v.achived = true if #self._shownList<3 then table.insert(self._shownList,v)end  end
            elseif v.type ==12 then
                if DataManager.get(DataManager.HPLV) >= v.sum then v.achived = true if #self._shownList<3 then table.insert(self._shownList,v)end  end
            elseif v.type ==13 then
                if DataManager.get(DataManager.LUCKLV) >= v.sum then v.achived = true if #self._shownList<3 then table.insert(self._shownList,v)end  end
            end
        end
    end

    if #self._shownList<3 then
        for k, v in pairs(s_data.achivement) do
            if v.finished ~=true and v.achived ~=true then table.insert(self._shownList,v) end
            if #self._shownList == 3 then break end
        end
    end


    if #self._shownList < 3 then
        for i=0,2-#self._shownList do
            table.insert(self._shownList,s_data.achivement[#s_data.achivement-i])
        end
    end
end


return AchivementLayer
