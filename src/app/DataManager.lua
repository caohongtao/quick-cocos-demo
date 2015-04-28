local GameState = require("framework.cc.utils.GameState")
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
DataManager.SAVES     ="save_animal"
DataManager.GAIN_BOX  ="gain_box"
DataManager.MUSIC_ON  ="music_on"  
DataManager.SOUND_ON  ="sound_on" 

function DataManager.init()
    GameState.init(onState, "gameInfo.dat", "key_diGET")
    DataManager.load()
    -- 初始化成就 
    for k,v in pairs(DataManager.data._finished_achivements) do
         s_data.achivement[v].finished = true
    end
    --测试
    DataManager.data.gold = 10000
    DataManager.data.point = 1000
    DataManager.data.topScore = 4000 -- 最高分数
    DataManager.data.total_rounds = 400 -- 总局数
    DataManager.data.topGroud = 800 -- 最高层数
    DataManager.save()
end


function DataManager.get(key) 
    return DataManager.data[key]
end

function DataManager.set(key,value) 
    DataManager.data[key] = value
    return DataManager.data[key]
end

function createDataFile()
    print("init gameinfo dat")
    DataManager.data = { point    = 0, -- 钻石
             gold     = 0, -- 金币
             topScore = 0, -- 最高分数
             total_rounds = 0, -- 总局数
             topGroud = 0, -- 最高层数
             speedLv  = 0, -- 速度等级
             powerLv  = 0, -- 挖掘等级
             hpLv     = 0, -- 生命等级
             luckLv   = 0, -- 幸运等级
             item_1   = 0, -- 道具蘑菇数量
             item_2   = 0, -- 道具栗子数量
             item_3   = 0, -- 道具可乐数量
             save_animal = 0, -- 救起小动物的总数量
             gain_box =  0,   -- 收集宝箱的总数量
             music_on = 1,
             sound_on = 1,
             _tmp_rounds = 0,
             _tmp_grounds = 0,
             _tmp_use_item_1 = 0,
             _tmp_use_item_2 = 0,
             _tmp_use_item_3 = 0,
             _tmp_atk_boss = 0,
             _tmp_dizz_boss = 0,
             _tmp_save_animal = 0,
             _finished_achivements = {},             
             _finished_quests = {}
             }

    DataManager.save()
end


function DataManager.achiveFinish(id)
    if DataManager.data._finished_achivements[id] == nil then
        table.insert(DataManager.data._finished_achivements,id)
        DataManager.save()
    end
end

function DataManager.questOver(id)
    if DataManager.data._finished_quests[id] == nil then
        table.insert(DataManager.data._finished_quests,id)
        DataManager.save()
    end
end

function DataManager.addGold(sum)
    if sum < 0  and DataManager.data[DataManager.GOLD] + sum < 0 then print("error  !  gold is not enough !")  return false end
    DataManager.data[DataManager.GOLD] = DataManager.data[DataManager.GOLD] + sum
    return true
end

function DataManager.addPoint(sum)
    if sum < 0  and DataManager.data[DataManager.POINT] + sum < 0 then print("error  !  point is not enough !")  return false end
    DataManager.data[DataManager.POINT] = DataManager.data[DataManager.POINT] + sum
    return true
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

function DataManager.getCurrProperty(property)
    return s_data.level["key"..(DataManager.get(property..'Lv') + 1)][property]
end

return DataManager