require("app.layers.PlayLayer")
require("app.layers.BackgroundLayer")
require("app.layers.PauseLayer")
local Relive = require("app.layers.ReliveLayer")
require("app.layers.HubLayer")
require("app.sprites.Element")
require("app.sprites.Player")
require("app.sprites.Boss")

local GameLayer = class("GameLayer", function()
    return display.newLayer("GameLayer")
end)

function GameLayer:ctor()
    self:stub()
    
    cc.SpriteFrameCache:getInstance():addSpriteFrames('sprite/crush.plist', 'sprite/crush.png')
    cc.SpriteFrameCache:getInstance():addSpriteFrames('sprite/fart.plist', 'sprite/fart.png')
    cc.SpriteFrameCache:getInstance():addSpriteFrames('sprite/explode.plist', 'sprite/explode.png')
    cc.SpriteFrameCache:getInstance():addSpriteFrames('sprite/gain_prop.plist', 'sprite/gain_prop.png')
    cc.SpriteFrameCache:getInstance():addSpriteFrames('sprite/cola_jet.plist', 'sprite/cola_jet.png')

    local pauseListener = cc.EventListenerCustom:create("pause game", handler(self,self.pauseGame))
    local dieListener = cc.EventListenerCustom:create("player die", handler(self,self.playerDie))
    local adjustMapListener = cc.EventListenerCustom:create("adjust map", handler(self,self.adjustMapStrategy))
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(pauseListener, self)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(dieListener, self)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(adjustMapListener, self)
    
    local backgroudLayer = BackgroundLayer.new()
    backgroudLayer:setPosition(display.left,display.bottom)
    backgroudLayer:setAnchorPoint(0,0)
    self:addChild(backgroudLayer)
    
    self:adjustMapStrategy({stage = 1})
    local playLayer = PlayLayer.new()
    self:addChild(playLayer)
    
    local hubLayer = HubLayer.new()
    self:addChild(hubLayer)

    audio.myPlayMusic('audio/gameSceneBG.mp3',true)
end

function GameLayer:pauseGame()
    audio.pauseMusic()
    
    local pauseScene = display.newScene('pauseScene')
    pauseScene:addChild(self:captureScreen())
    
    local pauseLayer = PauseLayer.new()
    pauseLayer.gameScene = self
    pauseScene:addChild(pauseLayer)
    
    cc.Director:getInstance():pushScene(pauseScene)
end

function GameLayer:playerDie(event)
    audio.pauseMusic()
    
    local deadScene = display.newScene('deadScene')
    deadScene:addChild(self:captureScreen())

--    local deadLayer = DeadLayer.new()
    local deadLayer = Relive.new()
    
    deadLayer.gameScene = self
    deadLayer.settlementInfo = event.settlement
    deadScene:addChild(deadLayer)

    cc.Director:getInstance():pushScene(deadScene)
end

function GameLayer:captureScreen()
    local renderTexture = cc.RenderTexture:create(display.width,display.height)
    renderTexture:begin()
    self:visit()
    renderTexture:endToLua()
    
    local sp = display.newFilteredSprite(renderTexture:getSprite():getTexture(),'GRAY',{0.2, 0.3, 0.5, 0.1})
    sp:setAnchorPoint(cc.p(0,0))
    sp:setFlippedY(true)
    
    return sp
end

function GameLayer:adjustMapStrategy(event)
    local mode = mapStrategys.sequence[event.stage]
    local strategy = mapStrategys[mode][math.random(1,#mapStrategys[mode])]
    
    local totalProbability = 0
    for k, v in pairs(elements) do
        local probability = strategy[k]
        if not v.isBrick then
            probability = probability * DataManager.getCurrProperty('luck') * 10
        end
        totalProbability = totalProbability + probability
        v.IntervalEnd = totalProbability
    end
    mapStrategys.totalProbability = totalProbability
end

function GameLayer:stub()
    DataManager.set(DataManager.SPEEDLV, 4)
    DataManager.set(DataManager.HPLV, 4)
    DataManager.set(DataManager.LUCKLV, 4)
    DataManager.set(DataManager.POWERLV, 0)
    DataManager.save()
end

return GameLayer
