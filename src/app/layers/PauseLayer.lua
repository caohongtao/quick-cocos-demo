PauseLayer = class("PauseLayer",  function()
    return display.newLayer("PauseLayer")
end)

local PAUSE_PANEL = {
    frame = {
        "ui/stopbox.png",
        pos = {x=display.cx,y=display.cy},
        align = display.CENTER,
    },
    continue = {
        normal = "ui/continue1.png",
        pressed = "ui/continue2.png",
        pos = {x=display.cx,y=display.cy+70},
        align = display.CENTER,
    },
    restart = {
        normal = "ui/replay1.png",
        pressed = "ui/replay2.png",
        pos = {x=display.cx,y=display.cy-30},
        align = display.CENTER,
    },
    back = {
        normal = "ui/back1.png",
        pressed = "ui/back2.png",
        pos = {x=display.cx,y=display.cy-135},
        align = display.CENTER,
    },
}

function PauseLayer:ctor()
    cc(self):addComponent("components.behavior.EventProtocol"):exportMethods()
    
    cc.ui.UIImage.new(PAUSE_PANEL.frame[1])
        :align(PAUSE_PANEL.frame.align, PAUSE_PANEL.frame.pos.x, PAUSE_PANEL.frame.pos.y)
        :addTo(self)
        
    cc.ui.UIPushButton.new({normal = PAUSE_PANEL.continue.normal,
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

            cc.Director:getInstance():popScene()
        end)
        :align(PAUSE_PANEL.continue.align, PAUSE_PANEL.continue.pos.x, PAUSE_PANEL.continue.pos.y)
        :addTo(self)
        
    cc.ui.UIPushButton.new({normal = PAUSE_PANEL.restart.normal,
        pressed = PAUSE_PANEL.restart.pressed,
        scale9 = true,})
        :onButtonClicked(function(event)
            print('restart')
            cc.Director:getInstance():popScene()
            self.gameScene:performWithDelay(function()
                cc.Director:getInstance():getRunningScene():dispatchEvent({name = "GAME_START"})   
            end,0.1)
            
        end)
        :align(PAUSE_PANEL.restart.align, PAUSE_PANEL.restart.pos.x, PAUSE_PANEL.restart.pos.y)
        :addTo(self)
        
    cc.ui.UIPushButton.new({normal = PAUSE_PANEL.back.normal,
        pressed = PAUSE_PANEL.back.pressed,
        scale9 = true,})
        :onButtonClicked(function(event)
            print('back')
        end)
        :align(PAUSE_PANEL.back.align, PAUSE_PANEL.back.pos.x, PAUSE_PANEL.back.pos.y)
        :addTo(self)
        
--    self:setVisible(false)
end
