
-- 0 - disable debug info, 1 - less debug info, 2 - verbose debug info
DEBUG = 1

-- display FPS stats on screen
DEBUG_FPS = true

-- dump memory info every 10 seconds
DEBUG_MEM = false

-- load deprecated API
LOAD_DEPRECATED_API = false

-- load shortcodes API
LOAD_SHORTCODES_API = true

-- screen orientation
CONFIG_SCREEN_ORIENTATION = "portrait"

-- design resolution
CONFIG_SCREEN_WIDTH  = 640
CONFIG_SCREEN_HEIGHT = 960

-- auto scale mode
CONFIG_SCREEN_AUTOSCALE = "FIXED_WIDTH"

--下面是自己定义的配置
TOTAL_ELEMENT_TYPE = 4

MATRIX_WIDTH = 12
MATRIX_HEIGHT = 10

res = {
    elementTexture = {
        fire = {
            normal = "fire_normal.png",
            horizontal = "fire_horizontal.png",
            vertical = "fire_vertical.png"
        },
        light = {
            normal = "light_normal.png",
            horizontal = "light_horizontal.png",
            vertical = "light_vertical.png"
        },
        water = {
            normal = "water_normal.png",
            horizontal = "water_horizontal.png",
            vertical = "water_vertical.png"
        },
        wind = {
            normal = "wind_normal.png",
            horizontal = "wind_horizontal.png",
            vertical = "wind_vertical.png"
        }
    }
}