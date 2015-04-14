GameState = require("framework.cc.utils.GameState")
DataManager = {}

DataManager.POINT     ="point"
DataManager.GOLD      ="gold"
DataManager.TOP_SCORE ="topScore"
DataManager.TOPGROUD  ="topGroud"
DataManager.SPEEDLV   ="speedLv"
DataManager.POWERLV   = "powerLv"
DataManager.HPLV      ="hpLv"
DataManager.LUCKLV    ="luckLv"
DataManager.ITEM_1    ="item_1"
DataManager.ITEM_2    ="item_2"
DataManager.ITEM_3    ="item_3"






function DataManager.init()
    GameState.init(onState, "gameInfo.dat", "key_diGET")
    DataManager.load()
end


function DataManager.get(key) 
    return DataManager.data[key]
end

function DataManager.set(key,value) 
    DataManager.data[key] = value
    DataManager.save()
    return DataManager.data[key]
end

function createDataFile()
    print("init gameinfo dat")
    DataManager.data = { point    = 0, -- 钻石
             gold     = 0, -- 金币
             topScore = 0, -- 最高分数
             topGroud = 0, -- 最高层数
             speedLv  = 0, -- 速度等级
             powerLv  = 0, -- 挖掘等级
             hpLv     = 0, -- 生命等级
             luckLv   = 0, -- 幸运等级
             item_1   = 0, -- 道具蘑菇数量
             item_2   = 0, -- 道具栗子数量
             item_3   = 0, -- 道具可乐数量
             _tmp_rounds = 0,
             _tmp_grounds = 0,
             _tmp_save_animal = 0,
             _tmp_use_item_1 = 0,
             _tmp_use_item_2 = 0,
             _tmp_use_item_3 = 0,
             _tmp_atk_boss = 0,
             _tmp_dizz_boss = 0,
             }

    DataManager.save()
end



function onState(event)
        if event.errorCode then
            if event.errorCode == GameState.ERROR_STATE_FILE_NOT_FOUND then 
                createDataFile()  
            end
            return
        end

        if "load" == event.name then
            if event.values.data ~= nil then 
            local str = crypto.decryptXXTEA(event.values.data, "24rs#201ojN")
            DataManager.data = json.decode(str)
            end
        elseif "save" == event.name then
            local str = json.encode(event.values)
            if str then
            str = crypto.encryptXXTEA(str, "24rs#201ojN")
                return {data = str}
            else
                print("ERROR, encode fail")
                return
            end

            return {data = str}
        end
end


function DataManager.load()
    GameState.load()
end

function DataManager.save()
    if DataManager.data ~=nil then         
        GameState.save(DataManager.data)
    end
end
