local EndLayer   = class("EndLayer", function()
    return display.newLayer("EndLayer")
end)

function EndLayer:ctor(event)
 
       cc(self):addComponent("components.behavior.EventProtocol"):exportMethods()




        local result = {
            _tmp_rounds = DataManager.set(DataManager.get("_tmp_rounds")+1),
            _tmp_grounds = DataManager.set(DataManager.get("_tmp_grounds")+event.grounds),
            _tmp_save_animal = DataManager.set(DataManager.get("_tmp_save_animal")+event.saves),
            _tmp_use_item_1 = DataManager.set(DataManager.get("_tmp_use_item_1")+event.use1),
            _tmp_use_item_2 = DataManager.set(DataManager.get("_tmp_use_item_2")+event.use2),
            _tmp_use_item_3 = DataManager.set(DataManager.get("_tmp_use_item_3")+event.use3),
            _tmp_atk_boss = DataManager.set(DataManager.get("_tmp_atk_boss")+event.atkboss),
            _tmp_dizz_boss = DataManager.set(DataManager.get("_tmp_dizz_boss")+event.dizzboss),


            
        }
        
        DataManager.save()

      local panel =   cc.ui.UIImage.new("ui/fenshudiban.png")
        :align(display.LEFT_BOTTOM, display.cx -    430/2, display.cy-300)
        :addTo(self)



        -- 跳转 成就界面
         cc.ui.UIPushButton.new({normal="ui/X.png",
                                pressed ="ui/X.png",
                                scale9 = false})                                
        -- :onButtonPressed(function(event)
        --     event.target:setScale(0.9)
        -- end)
        -- :onButtonRelease(function(event)
        --     event.target:setScale(1.0)
        -- end)
        :onButtonClicked(function()
            self:dispatchEvent({name = "JUMP_ACHIVEMENT",params=event})           
        end)
        :align(display.LEFT_BOTTOM, 373,450)
        :addTo(panel)


        -- 挖掘深度
        cc.ui.UILabel.new({  
            UILabelType = cc.ui.UILabel.LABEL_TYPE_BM,
            text = event.grounds,   -- 金币数
            font = "fonts/r.fnt",  
            --font        = "Times New Roman",
            align = cc.ui.TEXT_ALIGN_LEFT,  
            x = 156,  
            y = 100+60+60,  
        }):addTo(panel)

                -- 金币
        cc.ui.UILabel.new({  
            UILabelType = cc.ui.UILabel.LABEL_TYPE_BM,
            text = event.golds,   -- 金币数
            font = "fonts/r.fnt",  
            --font        = "Times New Roman",
            align = cc.ui.TEXT_ALIGN_LEFT,  
            x = 156,  
            y = 100+60,  
        }):addTo(panel)

                -- 钻石
        cc.ui.UILabel.new({  
            UILabelType = cc.ui.UILabel.LABEL_TYPE_BM,
            text = event.points,   -- 金币数
            font = "fonts/r.fnt",  
            --font        = "Times New Roman",
            align = cc.ui.TEXT_ALIGN_LEFT,  
            x = 156,  
            y = 100,  
        }):addTo(panel)

                -- 历史最高
        cc.ui.UILabel.new({  
            UILabelType = cc.ui.UILabel.LABEL_TYPE_BM,
            text = DataManager.get("topScore"),   -- 金币数
            font = "fonts/r.fnt",  
            --font        = "Times New Roman",
            align = cc.ui.TEXT_ALIGN_LEFT,  
            x = 225,  
            y = 356,  
        }):addTo(panel)
        -- 添加scrollview 存放任务列表
end






return EndLayer
