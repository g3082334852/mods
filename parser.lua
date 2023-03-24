--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local GF_HINT = {
    {armor = "防御: "},
    {aggro = "攻击: "},
    {cookpot = "或为: "},
    {dmg = "伤害: "},
    {food = "食物"},
    {S2 = "今时为夏"},
    {health = "生命: "},
    {warm = "保暖: "},
    {kill = "击杀: "},
    {kills = "击杀数: "},
    {loyal = "忠诚: "},
    {S4 = "今时为秋"},
    {remaining_days = "剩余天数"},
    {owner = "所有者: "},
    {perish = "距离腐烂: "},
    {hunger = "饥饿: "},
    {range = "攻击距离: "},
    {sanity = "精神"},
    {thickness = "厚度: "},
    {units_of = "单位"},
    {resist = "抵抗: "},
    {waterproof = "防水: "},
    {heal = "生命: "},
    {fishes = "鱼数量: "},
    {sec = "剩余时间(秒): "},
    {smithtype = "正在: "},
    {love = "喜爱: "},
    {summer = "隔热: "},
    {absorb = "吸收: "},
    {S3 = "今时为秋"},
    {is_admin = "管理员\n离开多时\n勿念"},
    {temperature = "温度"},
    {hp = "生命: "},
    {armor_character = "伤害减免: "},
    {sanity_character = "基础精神: "},
    {fuel = "燃料: "},
    {speed = "速度: "},
    {uses_of = "次可用，共"},
    {obedience = "顺从: "},
    {S1 = "今时为冬"},
    {baby_level = "等级: "},
    {dmg_character = "基础伤害: "},
    {cooldown = "冷却"},
    {domest = "驯化: "},
    {will_die = "距死期: "},
    {will_dry = "距干燥: "},
    {dmg_bonus = "伤害: "},
    {crop = ""},
    {grow_in = "距成熟: "},
    {perish_product = ""},
    {rightlock = ""},
    {writeable = "留言: "},
    {trading_price = "售价: "},
    {zblevel = ""},
    {enemyskill = ""},
    {gfenhance = ""},
    {gfinlay = ""},
    {weaponskill = ""},
    {forgeable = ""},
    {tempskill = ""},
    {gflock = "已绑定: "},
    {templock = ""},
    {gfsale = ""},
    {skillinfo = ""},
    {extrainfo = ""},
    {timer = "时计"},
    {trade_gold = "价值金子: "},
    {trade_rock = "价值石头: "},
    {durability = "耐久: "},
    {strength = "力量: "},
    {aoe = "群伤: "},
    {reclean = ""}
}

for _, v in ipairs(GF_HINT) do
    for k, _ in pairs(v) do
        v["key"] = k
        break
    end
end

local BACKEN_THREAD_ID = "parser_thread"

--------------------------------------------------------------------------
--[[ Global variables ]]
--------------------------------------------------------------------------

local _last_showme_hint_str

--------------------------------------------------------------------------
--[[ Parser class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

local os = require "os"

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private


--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function Split(str, separate)
    local index, result = 0, {}
    for i, j in function() return string.find(str, separate, index, true) end do
        table.insert(result, string.sub(str, index, i - 1))
        index = j + 1
    end
    table.insert(result, string.sub(str, index))
    return result
end

local function ParseHint(hint)
    print("输入的参数："..hint)
    local separate = string.find(hint, ";", 1, true)
    if separate ~= nil and separate > 0 then
        local hint_str = hint:sub(separate + 1)
        if hint_str ~= nil and #hint_str > 0 then
            local hints = Split(hint_str, "")
            local data = {}
            for i,v in ipairs(hints) do
                local param_str = v:sub(2)
                local param = Split(param_str, ",")
                local tag = GF_HINT[string.byte(v:sub(1, 1)) - 0x40]
                if tag ~= nil then
                    local key = tag.key
                    if key == "zblevel" then
                        local lv = tonumber(param[1])
                        if not lv then
                            data.lv = 0
                        elseif lv < 0x0 then
                            data.lv = -1
                        else
                            data.lv = lv
                        end
                    elseif key == "dmg" then
                        data.dmg = tonumber(param_str)
                    elseif key == "forgeable" then
                        local quality = tonumber(param[1])
                        local count = tonumber(param[2])
                        if quality and quality > 0 then
                            data.quality = quality
                            if count then
                                data.dur = count
                            end
                        end
                    elseif key == "weaponskill" then
                        if data.weaponskill == nil then
                            data.weaponskill = {}
                        end
                        local skill = { name = param[1], lv = tonumber(param[2]), quality = tonumber(param[3])}
                        if param[4] then
                            skill.cd = tonumber(param[4])
                        end
                        data.weaponskill[skill.name] = skill.lv
                    elseif key == "templock" then
                        data.templock = param_str
                    elseif key == "gflock" then
                        if param_str ~= "" then
                            data.gflock = param_str
                        end
                    elseif key == "perish_product" then
                        if data.items == nil then
                            data.items = {}
                        end
                        local item = { prefab = param[1], count = param[2] == "0" and 1 or tonumber(param[2]) }
                        table.insert(data.items, item)
                    end
                end
            end

            function table.tostring(tbl)
                if type(tbl) ~= "table" then
                    return tostring(tbl)
                end
            
                local result = "{ "
                local sep = ""
                for k, v in pairs(tbl) do
                    local key = k
                    if type(k) == "number" then
                        key = "[" .. k .. "]"
                    end
                    result = result .. sep .. key .. " = " .. tostring(v)
                    sep = ", "
                end
                result = result .. " }"
                return result
            end
            print("解析后的数据：")
            function tostring(v)
                if type(v) == "table" then
                    return table.tostring(v)
                else
                    return tostring(v)
                end
            end
        end

    end
end


                    
local function GetEntityByHint(hint)
    local separate = string.find(hint, ";", 1, true)
    if separate ~= nil and separate > 0 then
        local guid = tonumber(hint:sub(1, separate - 1))
        if guid ~= nil then
            return Ents[guid]
        end
    end
end

local function UpdateShowMeHint(force)
    local now = os.time()
    local net_showme_hint = self.inst.player_classified ~= nil and self.inst.player_classified.net_showme_hint
    if net_showme_hint == nil then
        return
    end
    local hint = net_showme_hint:value()
    if hint == nil then
        return
    end
    local ent = GetEntityByHint(hint)
    if ent ~= nil then
        if force == true or hint ~= ent.showme_hint then

            ent.showme_hint = hint
            local showme_data = ParseHint(hint)

            if showme_data ~= nil then
                ent.showme_data = showme_data
                ent.showme_hint_update_time = now
                _last_showme_hint_str = hint
            end

        end

        if _last_showme_hint_str == nil or _last_showme_hint_str ~= hint then
            ent.showme_hint_update_time = now
            _last_showme_hint_str = hint
        end

        ent.on_net_showme_hint_time = now
    end
end

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:GetShowMeData(item, cachetime, waittime)
    if cachetime == nil then
        cachetime = 0
    end
    if waittime == nil then
        waittime = 0
    end
    
    if item.net_showme_hint_refresh_out_time ~= nil and os.time() - item.net_showme_hint_refresh_out_time <= cachetime and item.showme_data == nil then
        return item.showme_data
    end

    if item.showme_hint_update_time ~= nil and os.time() - item.showme_hint_update_time <= cachetime and item.showme_data ~= nil then
        return item.showme_data
    end
    
    SendModRPCToServer(MOD_RPC.ShowMeHint.Hint, item.GUID, item)
    local time = os.time()
    local ct = os.time()
    
    while not (item.showme_hint_update_time ~= nil and item.showme_hint_update_time >= time and item.showme_data ~= nil) or not (item.on_net_showme_hint_time ~= nil and item.on_net_showme_hint_time >= time) do
        if item.on_net_showme_hint_time ~= nil and item.on_net_showme_hint_time - time >= waittime then
            item.net_showme_hint_refresh_out_time = os.time()
            break
        end
        Sleep(0.1)
        if os.time() - ct >= 1 then
            SendModRPCToServer(MOD_RPC.ShowMeHint.Hint, item.GUID, item)
            ct = os.time()
        end
    end
    
    return item.showme_data
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

if not self.inst.parser_thread then
    self.inst.parser_thread = self.inst:StartThread(function()
        while true do
            UpdateShowMeHint(false)
            Sleep(0.2)
        end
    end, BACKEN_THREAD_ID)
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)