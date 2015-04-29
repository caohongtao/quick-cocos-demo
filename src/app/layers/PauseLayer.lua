PauseLayer = class("PauseLayer",  function()
    return display.newLayer("PauseLayer")
end)

local PAUSE_PANEL = {
    frame = {
        "ui/panel2.png",
        pos = {x=display.cx,y=display.cy},
        align = display.CENTER,
    },
    continue = {
        normal = "ui/bigbutton1.png",
        pressed = "ui/bigbutton2.png",
        pos = {x=display.cx,y=display.cy+105},
        align = display.CENTER,
    },
    restart = {
        normal = "ui/bigbutton1.png",
        pressed = "ui/bigbutton2.png",
        pos = {x=display.cx,y=display.cy},
        align = display.CENTER,
    },
    back = {
        normal = "ui/bigbutton1.png",
        pressed = "ui/bigbutton2.png",
        pos = {x=display.cx,y=display.cy-105},
        align = display.CENTER,
    },
}

function PauseLayer:ctor()
    cc(self):addComponent("components.behavior.EventProtocol"):exportMethods()
    
    cc.ui.UIImage.new(PAUSE_PANEL.frame[1])
        :align(PAUSE_PANEL.frame.align, PAUSE_PANEL.frame.pos.x, PAUSE_PANEL.frame.pos.y)
        :addTo(self)
        
    local resumeButton = cc.ui.UIPushButton.new({normal = PAUSE_PANEL.continue.normal,
        pressed = PAUSE_PANEL.continue.pressed,
        scale9 = true,})
        :onButtonClicked(function(event)
            print("resume game")
            
--            local queue = {self:getParent()}
--            while #queue > 0 do
--                local nodes = queue[1]:getChildren()
--                for _, node in ipairs(nodes) do
--                    if node == self then
--                        node:setVisible(false)
--                    else
--                        table.insert(queue,node)
--                    end
--                end
--                queue[1]:resume()
--                table.remove(queue,1)
--            end
--            
--            local resumeEvent = cc.EventCustom:new("resume game")
--            cc.Director:getInstance():getEventDispatcher():dispatchEvent(resumeEvent)

            audio.resumeMusic()
            cc.Director:getInstance():popScene()
        end)
        :align(PAUSE_PANEL.continue.align, PAUSE_PANEL.continue.pos.x, PAUSE_PANEL.continue.pos.y)
        :addTo(self)
    display.newSprite('ui/jixuyouxi.png',0,0):addTo(resumeButton)
        
    local restartButton = cc.ui.UIPushButton.new({normal = PAUSE_PANEL.restart.normal,
        pressed = PAUSE_PANEL.restart.pressed,
        scale9 = true,})
        :onButtonClicked(function(event)
            print('restart')
            cc.Director:getInstance():popScene()
            self.gameScene:performWithDelay(function()
                cc.Director:getInstance():getEventDispatcher():dispatchEvent(cc.EventCustom:new("GAME_REPLAY"))
            end,0.1)
            
        end)
        :align(PAUSE_PANEL.restart.align, PAUSE_PANEL.restart.pos.x, PAUSE_PANEL.restart.pos.y)
        :addTo(self)
    display.newSprite('ui/congxinkaishi.png',0,0):addTo(restartButton)
        
    local backButton = cc.ui.UIPushButton.new({normal = PAUSE_PANEL.back.normal,
        pressed = PAUSE_PANEL.back.pressed,
        scale9 = true,})
        :onButtonClicked(function(event)
            print('back')
            cc.Director:getInstance():popScene()
            self.gameScene:performWithDelay(function()
                cc.Director:getInstance():getEventDispatcher():dispatchEvent(cc.EventCustom:new("GAME_BACK"))
            end,0.1)
        end)
        :align(PAUSE_PANEL.back.align, PAUSE_PANEL.back.pos.x, PAUSE_PANEL.back.pos.y)
        :addTo(self)
    display.newSprite('ui/huidaodating.png',0,0):addTo(backButton)
        
--    self:setVisible(false)
end
