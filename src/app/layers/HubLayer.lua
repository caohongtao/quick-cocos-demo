local score = 0
local deepth = 0


HubLayer = class("HubLayer",  function()
    return display.newLayer("HubLayer")
end)

local UP_BAR = {
    texture = "ui/topbar.png",
    x = display.left,
    y = display.top-3,
    align = display.LEFT_TOP,

    pause = {
        normal = "ui/stopup.png",
        pressed = "ui/stopdown.png",
        pos = {x=33,y=display.height-35},
    },
    score = {
        text        = "0",
        UILabelType = cc.ui.UILabel.LABEL_TYPE_BM,
        font        = "fonts/r.fnt",
        scale       = 0.6,
--        size        = 30,
        color       = display.COLOR_WHITE,
        x           = 115,
        y           = display.height-32,
    },
    deepth = {
        text        = "0",
        UILabelType = cc.ui.UILabel.LABEL_TYPE_BM,
        font        = "fonts/r.fnt",
        scale       = 0.6,
        align       = cc.TEXT_ALIGNMENT_RIGHT,
--        size        = 30,
        color       = display.COLOR_WHITE,
        x           = 220,
        y           = display.height-32,
    },
    coin = {
        text        = "0",
        UILabelType = cc.ui.UILabel.LABEL_TYPE_BM,
        font        = "fonts/r.fnt",
        scale       = 0.6,
--        size        = 30,
        color       = display.COLOR_WHITE,
        textAlign   = cc.TEXT_ALIGNMENT_LEFT,
        textValign  = cc.VERTICAL_TEXT_ALIGNMENT_TOP,
        x           = 385,
        y           = display.height-32,
    },
}

local BOTTOM_BAR = {
    texture = "ui/bottom_bar.png",
    x = display.left,
    y = display.bottom,
    align = display.LEFT_BOTTOM,

    oxygenLabel = {
        UILabelType = cc.ui.UILabel.LABEL_TYPE_BM,
        font        = "fonts/r.fnt",
--        size        = 60,
        color       = cc.c3b(0, 0, 160),
        x           = 65,
        y           = 20,
    },
    skill1 = {
        normal = "ui/jineng1.png",
        pressed = "ui/jineng2.png",
        pos = {x=141,y=12},
    },
    skill2 = {
        normal = "ui/jineng2.png",
        pressed = "ui/jineng3.png",
        pos = {x=217,y=12},
    },
    skill3 = {
        normal = "ui/jineng3.png",
        pressed = "ui/jineng1.png",
        pos = {x=284,y=12},
    },
    buy = {
        normal = "ui/plusup.png",
        pressed = "ui/plusdown.png",
        pos = {x=458,y=32},
    },
    gemLabel = {
        UILabelType = cc.ui.UILabel.LABEL_TYPE_BM,
        font        = "fonts/r.fnt",
        scale       = 0.6,
        text        = "0",
--        size        = 30,
        color       = display.COLOR_WHITE,
        x           = 380,
        y           = 24,
    },
}
function HubLayer:ctor()
    self:createUpBar()
    self:createBottomBar()
    
    local updateHubListener = cc.EventListenerCustom:create("update hub", handler(self,self.updateDate))
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(updateHubListener, self)
    
    local alertOxygenListener = cc.EventListenerCustom:create("alert oxygen", handler(self,self.alertOxygen))
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(alertOxygenListener, self)
        
    
    self:setTouchSwallowEnabled(false)
end

function HubLayer:createUpBar()
    --底图
    cc.ui.UIImage.new(UP_BAR.texture)
        :align(UP_BAR.align, UP_BAR.x, UP_BAR.y)
        :addTo(self)
        
    --暂停按钮
    cc.ui.UIPushButton.new({normal = UP_BAR.pause.normal,
        pressed = UP_BAR.pause.pressed,
        scale9 = true,})
        :align(display.CENTER, UP_BAR.pause.pos.x, UP_BAR.pause.pos.y)
        :onButtonClicked(function(event)
            print("pause game")
            local pauseEvent = cc.EventCustom:new("pause game")
            cc.Director:getInstance():getEventDispatcher():dispatchEvent(pauseEvent)
        end)
        :addTo(self)
        
    --三个label
    self.scoreLabel = cc.ui.UILabel.new(UP_BAR.score)
        :align(display.LEFT_BOTTOM)
        :addTo(self)
    self.scoreLabel:setScale(UP_BAR.score.scale)
        
    self.deepthLabel = cc.ui.UILabel.new(UP_BAR.deepth)
        :align(display.LEFT_BOTTOM)
        :addTo(self)
    self.deepthLabel:setScale(UP_BAR.deepth.scale)
        
    self.coinLabel = cc.ui.UILabel.new(UP_BAR.coin)
        :align(display.LEFT_BOTTOM)
        :addTo(self)
    self.coinLabel:setScale(UP_BAR.coin.scale)
end

function HubLayer:createBottomBar()
    --底图
    cc.ui.UIImage.new(BOTTOM_BAR.texture)
        :align(BOTTOM_BAR.align, BOTTOM_BAR.x, BOTTOM_BAR.y)
        :addTo(self)
        
    --氧气
    self.oxygenProcess = cc.ProgressTimer:create(cc.Sprite:create('ui/oxygenBar.png')):addTo(self)
    self.oxygenProcess:setScale(1.2,1)
    self.oxygenProcess:setType(cc.PROGRESS_TIMER_TYPE_BAR)
    self.oxygenProcess:setPosition(cc.p(BOTTOM_BAR.oxygenLabel.x,BOTTOM_BAR.oxygenLabel.y))
    self.oxygenProcess:setMidpoint(cc.p(0,0.5))
    self.oxygenProcess:setBarChangeRate(cc.p(1,0))
    self.oxygenProcess:setPercentage(100)
    
    local oxygenProcessCover = cc.Sprite:create('ui/oxygenBarCover.png'):addTo(self)
    oxygenProcessCover:setPosition(cc.p(BOTTOM_BAR.oxygenLabel.x,BOTTOM_BAR.oxygenLabel.y))
    
    self.oxygenLabel = cc.ui.UILabel.new(BOTTOM_BAR.oxygenLabel)
        :align(display.CENTER, BOTTOM_BAR.oxygenLabel.x, BOTTOM_BAR.oxygenLabel.y + 3)
        :addTo(self)
    
    self.oxygenLabel:setString(DataManager.getCurrProperty('hp'))
    self.oxygenLabel:setScale(0.4)
    
    --技能蘑菇
    cc.ui.UIPushButton.new({normal = BOTTOM_BAR.skill1.normal,
                            pressed = BOTTOM_BAR.skill1.pressed,
                            scale9 = true,})
        :onButtonClicked(function(event) self:castSkill(elements.mushroom) end)
        :align(display.LEFT_BOTTOM, BOTTOM_BAR.skill1.pos.x, BOTTOM_BAR.skill1.pos.y)
        :addTo(self)
    self.skillMushroomLabel = cc.ui.UILabel.new({UILabelType = cc.ui.UILabel.LABEL_TYPE_BM, font = "fonts/r.fnt",})
        :align(display.LEFT_BOTTOM, BOTTOM_BAR.skill1.pos.x, BOTTOM_BAR.skill1.pos.y+3)
        :addTo(self)
    self.skillMushroomLabel:setScale(0.4)
    self.skillMushroomLabel:setString(DataManager.get(DataManager.ITEM_1))
    
    --技能栗子
    cc.ui.UIPushButton.new({normal = BOTTOM_BAR.skill2.normal,
                            pressed = BOTTOM_BAR.skill2.pressed,
                            scale9 = true,})
        :onButtonClicked(function(event) self:castSkill(elements.nut) end)
        :align(display.LEFT_BOTTOM, BOTTOM_BAR.skill2.pos.x, BOTTOM_BAR.skill2.pos.y)
        :addTo(self)
    self.skillNutLabel = cc.ui.UILabel.new({UILabelType = cc.ui.UILabel.LABEL_TYPE_BM, font = "fonts/r.fnt",})
        :align(display.LEFT_BOTTOM, BOTTOM_BAR.skill2.pos.x, BOTTOM_BAR.skill2.pos.y+3)
        :addTo(self)
    self.skillNutLabel:setScale(0.4)
    self.skillNutLabel:setString(DataManager.get(DataManager.ITEM_2))

    --技能可乐
    cc.ui.UIPushButton.new({normal = BOTTOM_BAR.skill3.normal,
                            pressed = BOTTOM_BAR.skill3.pressed,
                            scale9 = true,})
        :onButtonClicked(function(event) self:castSkill(elements.cola) end)
        :align(display.LEFT_BOTTOM, BOTTOM_BAR.skill3.pos.x, BOTTOM_BAR.skill3.pos.y)
        :addTo(self)
    self.skillColaLabel = cc.ui.UILabel.new({UILabelType = cc.ui.UILabel.LABEL_TYPE_BM, font = "fonts/r.fnt",})
        :align(display.LEFT_BOTTOM, BOTTOM_BAR.skill3.pos.x, BOTTOM_BAR.skill3.pos.y+3)
        :addTo(self)
    self.skillColaLabel:setScale(0.4)
    self.skillColaLabel:setString(DataManager.get(DataManager.ITEM_3))
        
    --宝石
    cc.ui.UIPushButton.new({normal = BOTTOM_BAR.buy.normal,
                            pressed = BOTTOM_BAR.buy.pressed,
                            scale9 = true,})
        :onButtonClicked(function(event)
                print('buy')
            end)
        :align(display.CENTER, BOTTOM_BAR.buy.pos.x, BOTTOM_BAR.buy.pos.y)
        :addTo(self)
        
    self.gemLabel = cc.ui.UILabel.new(BOTTOM_BAR.gemLabel)
        :align(display.LEFT_BOTTOM)
        :addTo(self)
    self.gemLabel:setScale(BOTTOM_BAR.gemLabel.scale)
    self.gemLabel:setString(DataManager.data[DataManager.POINT])
end

function HubLayer:castSkill(skillType)
    local event = cc.EventCustom:new("cast_skill")
    event.skillType = skillType
    cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
end

function HubLayer:updateDate(event)
    if event.type == 'score' then
        self.scoreLabel:setString(self.scoreLabel:getString() + 1)
    elseif event.type == 'deepth' then
        self.deepthLabel:setString(event.data)
    elseif event.type == 'oxygen' then
        self.oxygenLabel:setString(event.data)
        self.oxygenProcess:setPercentage(event.data/DataManager.getCurrProperty('hp')*100)
    elseif event.type == 'coin' then
        self.coinLabel:setString(event.data)
    elseif event.type == 'gem' then
        self.gemLabel:setString(DataManager.data[DataManager.POINT])
    elseif event.type == 'skillMushroom' then
        self.skillMushroomLabel:setString(DataManager.get(DataManager.ITEM_1))
    elseif event.type == 'skillNut' then
        self.skillNutLabel:setString(DataManager.get(DataManager.ITEM_2))
    elseif event.type == 'skillCola' then
        self.skillColaLabel:setString(DataManager.get(DataManager.ITEM_3))
    end

end

function HubLayer:alertOxygen()
    local duration = 0.6
    self.oxygenLabel:runAction(cc.Sequence:create(
        cc.ScaleBy:create(duration,2),
        cc.ScaleBy:create(duration,0.5),
        cc.ScaleBy:create(duration,2),
        cc.ScaleBy:create(duration,0.5),
        cc.ScaleBy:create(duration,2),
        cc.ScaleBy:create(duration,0.5)
    ))
    audio.playSound('audio/alert.mp3')
end
