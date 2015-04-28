require("config")
require("cocos.init")
require("framework.init")
scheduler = require("framework.scheduler")

local MyApp = class("MyApp", cc.mvc.AppBase)

function MyApp:ctor()
    MyApp.super.ctor(self)
end

function MyApp:run()
    cc.FileUtils:getInstance():addSearchPath("res/")
    cc.Director:getInstance():setContentScaleFactor(480 / CONFIG_SCREEN_WIDTH)
--    display:setDesignResolutionSize()
    self:enterScene("MainScene")
end

return MyApp
