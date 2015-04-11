require("config")
require("cocos.init")
require("framework.init")
gameState = require("framework.cc.utils.GameState")

local MyApp = class("MyApp", cc.mvc.AppBase)

function MyApp:ctor()
    MyApp.super.ctor(self)
    self:initGameState()
end

GameData={}
function MyApp:initGameState()
    gameState.init(function(param)
        local returnValue=nil
        if param.errorCode then
            print("error")
        else
            -- crypto
            if param.name=="save" then
                local str=json.encode(param.values)
                str=crypto.encryptXXTEA(str, "abcd")
                returnValue={data=str}
            elseif param.name=="load" then
                local str=crypto.decryptXXTEA(param.values.data, "abcd")
                returnValue=json.decode(str)
            end
            -- returnValue=param.values
        end
        return returnValue
    end, "data.txt","1234")
    GameData=gameState.load()
    if not GameData then
        GameData=initialGameData
        gameState.save(GameData)
    end
    
    gameState.clear = function ()
        GameData=initialGameData
        gameState.save(GameData)
    end
end

function MyApp:run()
    cc.FileUtils:getInstance():addSearchPath("res/")
    cc.Director:getInstance():setContentScaleFactor(480 / CONFIG_SCREEN_WIDTH)
--    display:setDesignResolutionSize()
    self:enterScene("GameScene")
end

return MyApp
