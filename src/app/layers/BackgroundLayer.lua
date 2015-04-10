BackgroundLayer = class("BackgroundLayer",  function()
    return display.newLayer("BackgroundLayer")
end)

function BackgroundLayer:ctor()
    cc.ui.UIImage.new("ui/background.png")
        :align(display.LEFT_BOTTOM, display.left, display.bottom)
        :addTo(self)
end