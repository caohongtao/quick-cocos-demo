require("app.DataManager")
require("app.diggerData")

local MainUILayer = require("app.layers.MainUILayer")
local AchivementLayer = require("app.layers.AchivementLayer")
local LevelLayer = require("app.layers.LevelLayer")
local EndLayer = require("app.layers.EndLayer")
local ReliveLayer = require("app.layers.ReliveLayer")
local GameLayer = require("src.app.layers.GameLayer")

local MainScene   = class("MainScene", function()
    return display.newScene("MainScene")
end)

function MainScene:ctor()

   print("ctor()")    
   
	-- 数据初始化
	DataManager.init()	

    -- 创建ui层
    self.uiLayer = MainUILayer.new()    

    self:addChild(self.uiLayer)
    
    self:initAudio()

    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(cc.EventListenerCustom:create("GAME_START", handler(self,self.gameStart)),self)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(cc.EventListenerCustom:create("GAME_END", handler(self,self.gameEnd)),self)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(cc.EventListenerCustom:create("JUMP_MAIN", handler(self,self.jump2main)),self)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(cc.EventListenerCustom:create("GAME_BACK", handler(self,self.gameBack)),self)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(cc.EventListenerCustom:create("GAME_REPLAY", handler(self,self.gameReplay)),self)
end

function MainScene:initAudio()

    audio.preloadMusic('audio/mainSceneBG.mp3')
    audio.preloadMusic('audio/gameSceneBG.mp3')
    audio.preloadSound('audio/dig.wav')
    audio.preloadSound('audio/getProp.wav')
    
    audio.setSoundsVolume(DataManager.get(DataManager.SOUND_ON) == 0 and 0 or 1.0)
    audio.setMusicVolume(DataManager.get(DataManager.MUSIC_ON) == 0 and 0 or 0.3)
    
    --cocos的简单声音引擎测出bug(当两次连续调用playMusic播放同一首music时，第二次会播放不出来。此现象只在android客户端出现。因此此处封装特殊函数，记录正在播放的music)
    audio.myPlayMusic = function(file, isLoop)
        if DataManager.get(DataManager.MUSIC_ON) == 0 then return end

        if file == audio.__currMusic then
--            if not audio.isMusicPlaying() then
                audio.rewindMusic()
                audio.resumeMusic()
--            end
        else
            audio.playMusic(file,isLoop)
            audio.__currMusic = file
        end
    end

    audio.myPlayMusic('audio/mainSceneBG.mp3',true)
end

function MainScene:removeGameLayer()
    if self.gameLayer then
        local queue = {self.gameLayer}
        while #queue > 0 do
            local nodes = queue[1]:getChildren()
            for _, node in ipairs(nodes) do
                table.insert(queue,node)
            end
            if queue[1].unscheduleAllTimers then
                queue[1]:unscheduleAllTimers()
            end
            table.remove(queue,1)
        end
        self.gameLayer:removeFromParent(true)
        self.gameLayer = nil
    end
end

-- 开始游戏
function MainScene:gameStart(event)
    self:removeGameLayer()
    self.gameLayer = GameLayer.new()
    self.gameLayer:setPosition(0,- display.height)
    self:addChild(self.gameLayer)
    self.uiLayer:hideUI()
    -- self.uiLayer:setVisible(false)

    -- 开始一个卷动动画
    local _time = 2
    self.uiLayer:runAction(cca.moveTo(1.5,0,display.height))
    self.gameLayer:runAction(cca.seq({cca.moveTo(1.5,0,0),
                                    cca.callFunc(function ()
                                            print("gameLayer init")   
                                            self.gameLayer:init()  
                                            self.uiLayer:setVisible(false)
                                        end),

                                    }))   
end

function MainScene:gameReplay(event)
    self:removeGameLayer()
    self.gameLayer = GameLayer.new()
    self:addChild(self.gameLayer)
    self.gameLayer:init()  
end

function MainScene:testLayer(event)
    local backgroudLayer = BackgroundLayer.new()
    backgroudLayer:setPosition(display.left,display.bottom)
    backgroudLayer:setAnchorPoint(0,0)
    self:addChild(backgroudLayer)

    scheduler.performWithDelayGlobal(function ()
        self:gameEnd({
            params = {
            saves=2, -- 救动物
            use1=2,  -- 使用物品
            use2=3,
            use3=4,
            atkboss=2, -- 击退boss
            dizzboss=1,-- 晕眩bos
            box=4,     -- 宝箱数
            golds=100,   -- 金币数
            grounds=600, -- 层数
            points =  20,  -- 钻石
            relive = 1,    -- 复活一次
            }
            })
    end, 0.1)
end
-- 结束游戏
--event.saves, -- 救动物
--event.use1,  -- 使用物品
--event.use2,
--event.use3,
--event.atkboss, -- 击退boss
--event.dizzboss,-- 晕眩boss
--event.box,     -- 宝箱数
--event.golds,   -- 金币数
--event.points,  -- 钻石数目
--event.grounds, -- 层数

function MainScene:gameEnd(event)
    -- 弹出结算面板    
    print("----------出 结算--------------")

    self.gameLayer:pauseGameLayer()
    
    self.endLayer = EndLayer.new(event.params)
    self:addChild(self.endLayer)
end

-- 切换成绩面板
function MainScene:jump2achivement(event)


    self.endLayer:setVisible(false)
    
    self.achivementLayer = AchivementLayer.new(event.params)
    self:addChild(self.achivementLayer)

    self.achivementLayer:addEventListener("JUMP_LEVELUP",handler(self,self.jump2levelUp))  
    
    
end

-- 切换升级面板
function MainScene:jump2levelUp()

    print("切换到升级")
    self.achivementLayer:setVisible(false)
    
    self.levelLayer = LevelLayer.new()

    self:addChild(self.levelLayer)

    self.levelLayer:addEventListener("JUMP_MAIN",handler(self,self.jump2main))  
    
    
end

-- 回到主界面
function MainScene:jump2main()

    print("  回到主界面")

    self:removeGameLayer()
    self.uiLayer:showUI()
    self.uiLayer:setPosition(0,0)
    
    self.uiLayer:setVisible(true)
    
    audio.myPlayMusic('audio/mainSceneBG.mp3',true)
end

function MainScene:gameBack()
	self:removeGameLayer()
	self:jump2main()
end

function MainScene:onEnter()

end

function MainScene:onExit()

end

return MainScene
