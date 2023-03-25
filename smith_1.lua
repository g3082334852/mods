--------------------------------------------------------------------------
--[[ Smith class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

require "os"
require "json"
local Helper = require "helper"
local tools = require "tools"
local Parser = require "parser"

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------


local MAX_RAW = 240
local GIFT = "gift"
local ANVIL = "gf_anvil"
local UNIX = os.time({year=1970,month=1,day=1})
local WRAP_ITEM = "giftwrap"
local RESOLVE = "resolve_reel"
local FLAME = "flame_soul"
local SKILL_1 = "enlight_core"
local FORGING = "forging_agent"

local FIX = {
    head = { item = "lightbulb", tag = "CAVE_fueled", threshold = 20 },
    hands = { item = "lightbulb", tag = "CAVE_fueled", threshold = 20 },
}

local GF_SMITH = {
    eg = "铭刻",
    fu = "融合",
    re = "重锻",
    rs = "分解",
    rf = "保留"
}

local PACKITEMS = {
"enlight_core",
--"flame_soul"
}
local GF_GROUPS = {
    blue = { name = "蓝近", quality = 3, dmg = 220 },
    blue_range = { name = "蓝远", quality = 3, dmg = 170 },
    purple = { name = "紫近", quality = 4, dmg = 280 },
    purple_range = { name = "紫远", quality = 4, dmg = 220 },
    orange = { name = "橙近", quality = 5, dmg = 330 },
    orange_range = { name = "橙远", quality = 5, dmg = 280 },
    armor = { name = "盔甲", quality = 4 },
    special_orange = { name = "稀有橙近", quality = 5, dmg = 330 },
    special_orange_range = { name = "稀有橙远", quality =5, dmg = 280 },
    special_armor = { name = "毕业甲", quality = 4 }
}

local GF_SKILLS = {
    { name = "风暴", key = "fengbao" },
    { name = "陨星", key = "yunxing" },
    { name = "触手", key = "chushou" },
    { name = "充能", key = "chongneng" },
    { name = "突进", key = "tujin" , },
    { name = "碎甲", key = "suijia" },
    { name = "霹雳", key = "pili" },
    { name = "强力", key = "qiangli" },
    { name = "迅疾", key = "xunji" },
    { name = "趋避", key = "qubi" , },
    { name = "抵御", key = "diyu" },
    { name = "圣光", key = "shengguang" },
    { name = "批判", key = "pipan" },
    { name = "嗜血", key = "shixue" },
    { name = "爆裂", key = "baolie" },
    { name = "燃血", key = "ranxue" },
    { name = "连击", key = "lianji" },
    { name = "飓风", key = "jufeng" , },
    { name = "震退", key = "zhentui" },
    { name = "护盾", key = "hudun" },
    { name = "坚守", key = "jianshou" },
    { name = "自愈", key = "ziyu" },
    { name = "荆棘", key = "jingji" },
    { name = "穿甲", key = "chuanjia" },
    { name = "蓄势", key = "xushi" },
    { name = "狂暴", key = "kuangbao" },
    { name = "暴击", key = "baoji" },
    { name = "云箭", key = "yunjian" },
    { name = "破军", key = "pojun" },
    { name = "无双", key = "wushuang" },
    { name = "新生", key = "xinsheng" },
    { name = "神佑", key = "shenyou" },
    { name = "免控", key = "miankong" },
    { name = "自闭", key = "zibi"},
    { name = "日炎", key = "riyan"}
}

local GF_TAGS = {
    { name = "upgrade", desc = "伪属性", fn = function(item, group, data)
        return item.replica.forgeable:GetQuality() > group.quality and group.tags.upgrade or "re"
    end },
    { name = "dual", desc = "双特", fn = function(item, group, data)
        return data.weaponskill and #data.weaponskill > 1 and group.tags.dual or "re"
    end },
    { name = "maximun", desc = "满基础", fn = function(item, group, data)
        return data.dmg and data.dmg == group.dmg and group.tags.maximun or "re"
    end },
    { name = "unlimit", desc = "无级别", fn = function(item, group, data)
        return data.lv and data.lv < 0 and group.tags.unlimit or "re"
    end },
    { name = "skill", desc = "特性", fn = function(item, group, data) 
        if data.weaponskill and #data.weaponskill > 0 then
            if #data.weaponskill == 1 then--特性只有一个
                local n1=data.weaponskill[1].name
                local r = group.skills[n1]
                local lv = data.weaponskill[1].lv
                local dur = item.replica.forgeable:GetDur()
                if r and (r == "m" or r == 'm_s') then 
                    if r == "m_s" and dur > 10 then
                        return "re"
                    else
                        return "rs", n1..lv
                    end
                elseif r and r == "re" then
                    return r
                elseif r and r ~= "re" then
                    r = r:gsub("_s","")
                    return r, n1
                end
            elseif  #data.weaponskill == 2 then--特性有两个
                local n1 = data.weaponskill[1].name --第一个特性的name
                local n2 = data.weaponskill[2].name --第二个特性的name
                local dur = item.replica.forgeable:GetDur()--装备剩余锻造次数
                local r1 = group.skills[n1] --第一个特性的锻造方式
                local r2 = group.skills[n2] --第二个特性的锻造方式
                local lv1 = data.weaponskill[1].lv
                local lv2 = data.weaponskill[2].lv
                if r1 and (r1 == "rf" or r1 == "rs") then --如果 r1 是 "保留" 或 "分解"，则返回 r1 和 n1；
                    return r1, n1 .. lv1
                elseif r2 and (r2 == "rf" or r2 == "rs") then --如果 r2 是 "保留" 或 "分解"，则返回 r2 和 n2；
                    return r2, n2 .. lv2
                elseif r1 and r2 then
                    if r1 == "m" or r2 == "m" then
                        if dur > 10 then
                            return "re"
                        else
                            return "rs",n1..lv1..n2..lv2
                        end
                    elseif r1 =="m_s" or r2 == "m_s" then
                        if dur > 10 then 
                            return "re"
                        else 
                            return "rs",n1..lv1..n2..lv2
                        end
                    elseif r1 == "re" or r2 == "re"  then
                        return "re"
                    elseif r1 == "rs_s" and r2 == "rs_s" then
                        return "rs",n1..lv1..n2..lv2
                    else 
                        return "rf",n1..lv1..n2..lv2
                    end
                end
            end
        end
        return "re"
    end },
    { name = "nodur", desc = "无次数", fn = function(item, group, data)
        return item.replica.forgeable:GetDur() == 1 and group.tags.nodur or "re"
    end },
	{ name = "nodur_1", desc = "锻造剩5次", fn = function(item, group, data)
        return item.replica.forgeable:GetDur() <= 5 and group.tags.nodur_1 or "re"
    end },
    --[[{ name = "nodur_2", desc = "锻造剩10次", fn = function(item, group, data)
        return item.replica.forgeable:GetDur() <= 10 and group.tags.nodur_2 or "re"
    end }]]
}

local CONFIG_LIST = {
    general = {
        "range",
        "drop",
        "buy"
    },
    blue = {
        "enable",
        "ore",
        "flamesoul",
        items = {
            "huamei",
            "anri",
            "nilin",
            "miejitufu",
            "pohundao"
        },
        skills = {
            "fengbao",
            "yunxing",
            "chushou",
            "chongneng",
            "tujin",
            "qiangli",
            "suijia",
            "pili",
            "xunji"
        },
        tags = {
            "upgrade",
            "dual",
            "maximun",
            "unlimit",
            "nodur",
            "nodur_1"
        }
    },
    blue_range = {
        "enable",
        "ore",
        "flamesoul",
        items = {
            "xingchen",
            "liming",
            "hua",
        },
        skills = {
            "fengbao",
            "yunxing",
            "chushou",
            "chongneng",
            "qubi",
            "qiangli",
            "suijia",
            "pili",
            "xunji"
        },
        tags = {
            "upgrade",
            "dual",
            "maximun",
            "unlimit",
            "nodur",
            "nodur_1"
        }
    },
    purple = {
        "enable",
        "ore",
        "flamesoul",
        items = {
            "caijue",
            "xuezou",
            "xuansong",
            "taihua",
            "youheng",
            "daizong",
            "shenpan",
            "panyexueyin",
            "guiyan"
        },
        skills = {
            "tujin",
            "qiangli",
            "suijia",
            "pili",
            "xunji",
            "shixue",
			"lianji",
            "baolie",
            "ranxue",
            "zhentui"
        },
        tags = {
            "upgrade",
            "dual",
            "maximun",
            "unlimit",
            "nodur",
            "nodur_1"
        }
    },
    purple_range = {
        "enable",
        "ore",
        "flamesoul",
        items = {
            "riyao",
            "feiheng",
            "hanbingquanzhang"
        },
        skills = {
            "qubi",
            "qiangli",
            "suijia",
            "pili",
            "xunji",
            "jufeng",
            "shixue",
			"lianji",
            "baolie",
            "ranxue",
            "zhentui"
        },
        tags = {
            "upgrade",
            "dual",
            "maximun",
            "unlimit",
            "nodur",
            "nodur_1"
        }
    },
    orange = {
        "enable",
        "ore",
        "flamesoul",
        items = {
            "bihaitianwang",
            "chimingtiandi",
            "mingyue",
            "yaoyangshengzun",
            "chiri",
            "ziyueshengjun",
            "shuanglengjiuzhou",
            "hongying",
            "yangmie"
        },
        skills = {
            "shixue",
			"lianji",
            "baolie",
            "ranxue",
            "zhentui",
            "chuanjia",
            "xushi",
            "kuangbao",
            "baoji",
            "yunjian",
            "pojun"
        },
        tags = {
            "upgrade",
            "dual",
            "maximun",
            "unlimit",
            "nodur",
            "nodur_1",
           -- "nodur_2"
        }
    },
    orange_range = {
        "enable",
        "ore",
        "flamesoul",
        items = {
            "tihu",
            "yaoguang",
            "wumai",
            "wanzun",
            "hunzhang"
		},
        skills = {
            "jufeng",
            "shixue",
			"lianji",
            "baolie",
            "ranxue",
            "zhentui",
            "chuanjia",
            "xushi",
            "kuangbao",
            "baoji",
            "yunjian",
            "pojun"
        },
        tags = {
            "upgrade",
            "dual",
            "maximun",
            "unlimit",
            "nodur",
            "nodur_1",
            --"nodur_2"
        }
    },
    armor = {
        "enable",
        "ore",
        "flamesoul",
        items = {
            "jaggedarmor",
            "jaggedgrandarmor",
            "silkenarmor",
            "silkengrandarmor",
            "splintmail",
            "whisperinggrandarmor",
            "steadfastarmor"
        },
        skills = {
            "diyu",
            "shengguang",
            "pipan",
            "qiangli",
            "xunji",
            "hudun",
            "jianshou",
            "ziyu",
            "jingji",
            "zhentui",
            "wushuang",
            "xinsheng",
            "miankong",
            "zibi",
            "shenyou",
			"riyan"
        },
        tags = {
            "dual",
			"unlimit",
            "nodur",
            "nodur_1"
        }
    },
	special_orange = {--特殊橙近
	"enable",
    "ore",
    "flamesoul",
	    items = {
		    "tianjie",
			"chenxin",
	        "yihaung",
	        "tianzhao"
	    },
		skills = {
            "shixue",
			"lianji",
            "baolie",
            "ranxue",
            "zhentui",
            "chuanjia",
            "xushi",
            "kuangbao",
            "baoji",
            "yunjian",
            "pojun"
        },
        tags = {
            "dual",
            "maximun",
            "unlimit",
            "nodur",
            "nodur_1"
        }
	},
	special_orange_range = {--特殊橙远
	"enable",
    "ore",
    "flamesoul",
	    items = {
		"kongqueling",
		"youhaung",
		"yuedu"
		},
		skills = {
            "jufeng",
            "shixue",
			"lianji",
            "baolie",
            "ranxue",
            "zhentui",
            "chuanjia",
            "xushi",
            "kuangbao",
            "baoji",
            "yunjian",
            "pojun"
        },
        tags = {
            "dual",
            "maximun",
            "unlimit",
            "nodur",
            "nodur_1"
        }
	},
	special_armor = {--特殊盔甲
	"enable",
    "ore",
    "flamesoul",
	    items = {
	        "steadfastgrandarmor"
	    },
		skills = {
            "diyu",
            "shengguang",
            "pipan",
            "qiangli",
            "xunji",
            "hudun",
            "jianshou",
            "ziyu",
            "jingji",
            "zhentui",
            "wushuang",
            "xinsheng",
            "miankong",
            "zibi",
            "shenyou",
			"riyan"
        },
	    tags = {
        "dual",
		"unlimit",
        "nodur",
        "nodur_1"
        }
    }
}

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst
self.name = "自动锻造"
self.prefix = "smith"
self.config = CONFIG_LIST
self.run = false

--Private

--object and function
local _helper
local _parser
local _ontalkfn
local _cfg

--data
local _report_time
local _error
local _need
local _retain
local _unite
local _anvils
local _empty
local _wait
local _work

--path
local _start_pos
local _start_time
local _border_start
local _border_end

--behavior
local _anvil

--items
local _items, _es
local _forge, _key, _keys
local _fix_item, _fix_equip
local _equips
local _loot
local _unpack
local _pack
local _drop

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function Has(prefab, num)
    return _items[prefab] and _items[prefab].count >= num
end

local function Decode(anvil)
    local s, r = pcall(json.decode, anvil.replica.container._sb_data:value())
    if s then
        return r
    end
end
		
local function Add(r)
    local add = {}
    local enough = true
    local g = _cfg[r.key]
    
    if r.smith == "rs" then
        add[RESOLVE] = r.quality
    else
        add[g.ore] = 1
        if g.flamesoul then
            add[FLAME] = 1
        end
        if r.dur == 1 then
            add[FORGING] = 1
        end
    end
    
    for k, v in pairs(add) do
        if not Has(k, v) then
            enough = false
        end
    end
    
    return add, enough
end

local function IsSmith(item)
    local quality = item.replica.forgeable:GetQuality()
    local dur = item.replica.forgeable:GetDur()
    local name = tools.get_name(item.prefab)
    local k
    
    for g, _ in pairs(GF_GROUPS) do
        if _cfg[g].items[item.prefab] then
            k = g
        end
    end
    
    local result = { dur = dur, quality = quality, smith = "rf" }
    if not k then
        result.reason = "未分类: " .. name
    else
        result.key = k
        if dur == 0 then
            result.reason = "不可锻造"
        elseif not _cfg[k].enable then
            result.reason = "禁用 " .. _cfg[k].name
        elseif _cfg[k].items[item.prefab] ~= "re" then
            result.reason = name
            result.smith = _cfg[k].items[item.prefab]
        else
            tools.send("正在解析: " .. name .. " 分类: " .. _cfg[k].name .. " 可锻次数: " .. dur)
            result.k = k
            result.smith = "re"
            
            local data =  _parser:GetShowMeData(item, 15, 3)

            if data and data.quality then
                if data.gflock then
                    result.smith = "rf"
                    result.reason = "已绑定"
                    return result
                end
                
                for _,tag in ipairs(GF_TAGS) do
                    local smith, extra = tag.fn(item, _cfg[k], data)
                    if smith ~="re" then
                        result.smith = smith
                        result.reason = extra or tag.desc
                        return result
                    end
                end   
            else
                return nil
            end
            
        end
    end
    return result
end

local function IsForgeable(item)
    return item and item.replica.forgeable and not item:HasTag("gf_locked") and (item.replica.forgeable:IsTypeOf("weapon") or item.replica.forgeable:IsTypeOf("armor")) and not _retain[item] and not _unite[item]
end

local function IsUnite(item)
    if not _key and _unite[item] then
        if not _keys[_unite[item]] then
            _keys[_unite[item]] = item
        else
            _key = _unite[item]
            return true
        end
    end
end

local function IsNeed(item)
    if type(item) == "table" then
        if _empty > 0 and IsForgeable(item) and not _helper:Has(nil, nil, function(e) return IsForgeable(e) end, math.min(_empty, 8)) and _es > 4 then
            return true
        elseif item.prefab == GIFT then
            local data = _parser:GetShowMeData(item, 3600, 3)
            if data and data.items then
                for i, v in ipairs(data.items) do
                    if IsNeed(v.prefab) then
                        item.unpack = true
                        return true
                    end
                end
            end
        else
            return IsNeed(item.prefab)
        end
    elseif type(item) == "string" and _need[item] and _es > 1 and not Has(item, MAX_RAW) then
        return true
    end
end

local function IsDead()
    return self.inst:HasTag("playerghost") or self.inst:HasTag("corpse") 
end

local function RefreshItem()
    _forge = nil
    _key = nil
    _keys = {}
    
    _items, _es = _helper:Items(nil, nil, function(e)
        if not _forge and IsForgeable(e) then
            _forge = e
        end
        
        IsUnite(e)
        
        return true
    end)
    return true
end


local function RefreshAnvil()
    local ents = TheSim:FindEntities(_start_pos.x, 0, _start_pos.z, _cfg.general.range)
    _work = 0
    _empty = 0
    _wait = 0
    
    for _, v in ipairs(ents) do
        if v.prefab == ANVIL then
            if _anvils[v] then
                if not v.replica.container:CanBeOpened() then
                    _work = _work + 1
                end
                
                local r = _anvils[v]
                
                if r.smith == "rf" then
                    _empty = _empty + 1
                else
                    local count = r.smith == "rs" and r.quality or r.dur - 1
                    for p, c in pairs(r.add) do
                        if not _need[p] then
                            _need[p] = count
                        else
                            _need[p] = _need[p] + count
                        end
                    end
                end
            else
                _wait = _wait + 1
            end
        end
    end
end

local function Afford(prefab)
    return _items[prefab] or _helper:Afford(prefab) and _es > 0
end

local function MaxSq(e)
    local x,y,z = e:GetPosition():Get()
    return x > _border_start.x and z > _border_start.z and x < _border_end.x and z < _border_end.z
end

local function FindAnvil(fn)
    return _helper:Find(nil, _cfg.general.range, nil, nil, nil, ANVIL, function(e)
        return MaxSq(e) and (not fn or fn(e))
    end)
end

local function Report()
    if os.time() - _report_time < 30 then
        return
    end
    
    _report_time = os.time()
    RefreshAnvil()
    tools.send(string.format("锻造: %d 等待: %d 闲置: %d", _work, _wait, _empty))
end

local function EquipCheck()
    for _, v in pairs(_equips) do
        if v then
            if not v:IsValid() then
                _error = string.format("%s 丢失", tools.get_name(v.prefab))
                return
            end
            if not v.replica.inventoryitem:IsGrandOwner(self.inst) then
                _helper:Do(nil, v)
                return
            end
            if not v.replica.equippable:IsEquipped() then
                _helper.inventory:UseItemFromInvTile(v)
                return
            end
        end
    end
    return true
end

local function ShouldFix()
    for k, v in pairs(FIX) do
        local equip = _equips[k]
        if equip and equip:HasTag(v.tag) and tools.get_percent(equip) < v.threshold and Afford(v.item) then
            _fix_equip = equip
            _fix_item = v.item
            return true
        end
    end
end
--[[
local function ShouldAttack()
    local mobs = _helper:Find(nil, 30, {"_combat", "_health"}, {"FX", "NOCLICK", "DECOR", "INLIMBO", "wall"}, nil, nil, function(e)
        if e and e:IsValid() and not e.replica.health:IsDead() and _helper.combat:CanTarget(e) and
            e.replica.combat:GetTarget() == self.inst then
            return true
        end
    end)
    
    if #mobs > 0 then
        _mob = mobs[1]
        return true
    end
end
]]
local function ShouldPick()
    if _es < 5 then
        return false
    end
    
    _loot = {}
    
    _helper:Find(nil, _cfg.general.range, nil, true, nil, nil, function(e)
        if #_loot == 0 and e.replica and e.replica.inventoryitem and e.replica.inventoryitem:CanBePickedUp() then
            if IsNeed(e) then
                _loot = {e}
            elseif _empty > 0 and IsUnite(e) then
                _loot = {e, _keys[_unite[e]]}
            end
        end
    end)
    
    if #_loot > 0 then
        return true
    end
end
local function ShouldPack()
    if not _items[WRAP_ITEM] then
        return
    end
    
    _pack = {}
    local _pack_keep = {}
    local _pack_drop = {}
    
    _helper:IterateInventory(function(e,i,c)
        --if e and e.prefab == "enlight_core" and tools.is_full(e) then-
		if e and e.prefab and table.contains(PACKITEMS, e.prefab) then
            table.insert(_pack, {slot = i, container = c})
            
            if #_pack_keep > 9 then
                _pack = _pack_keep
                return true
            elseif #_pack_drop > 9 then
                _pack = _pack_drop
                return true
            end
        end
    end)
	if _helper:IsFull() then
                if #_pack_keep >= 0x2 then
                    _pack = _pack_keep
                    return true
                elseif #_pack_drop >= 0x2 then
                    _pack = _pack_drop
                    return true
                end
                return #_pack >= 0x2
            end
            return #_pack >= 0x9
    end

local function ShouldDrop()
    if not _items[GIFT] or not _cfg.general.drop then
        return
    end
    
    _drop = _helper:Item(GIFT, nil, function(e)
        if e.unpack or e.keep then
            return
        end
        
        local data = _parser:GetShowMeData(e, 3600, 3)
        
        if data and data.items then
            for _, v in ipairs(data.items) do
                if v.prefab ~= "enlight_core" then
                    e.keep = true
                    return
                end
            end
            
            return true
        end
    end)
    
    return _drop
end

local function ShouldUnpack()
    if _es < 5 then
        return false
    end
    
    _unpack = _helper:Item(nil, nil, function(e) return e.unpack end)
    
    return _unpack
end

local function ShouldAnvil()
    _anvil = nil
    
    FindAnvil(function(e)
        if not _anvil and e.replica.container and e.replica.container:CanBeOpened() then
            if _anvils[e] then
                local r = _anvils[e]
                if r.smith == "rf" and (_forge or _key) then
                    _anvil = e
                elseif r.add then
                    for k, v in pairs(r.add) do
                        if not Has(k, v) then
                            return false
                        end
                    end
                    
                    _anvil = e
                end
            else
                _anvil = e
            end
        end
    end)
    
    if _anvil then
        return true
    end
end

local function DoAnvil()
    local open = UNIX
    local co = _anvil.replica.container
    while self.run and _anvil:IsValid() and co:CanBeOpened() and not co:IsOpenedBy(self.inst) do
        if os.time() - open > 1 then
            _helper:Do(nil, _anvil)
            open = os.time()
        end
        Sleep(0.2)
    end
    Sleep(0.2)
    if _anvil:IsValid() and co:IsOpenedBy(self.inst) then
        _anvils[_anvil] = nil
        local e, r
        for i = 1, co:GetNumSlots() do
            local item = co:GetItemInSlot(i)
            if item then
                if item.replica.forgeable then
                    local t = item.replica.forgeable:GetType()
                    while self.run and _anvil:IsValid() and co:GetItemInSlot(i) do
                        if not e and IsForgeable(item) then
                            local d = IsSmith(item)
                            if d then
                                tools.send(string.format("%s, 原因: %s", GF_SMITH[d.smith], d.reason or ""))
                                
                                if d.smith == "rf" then
                                    _retain[item] = true
                                    _helper.inventory:DropItemFromInvTile(item, false)
                                elseif d.smith == "fu" then
                                    _unite[item] = d.key .. d.reason
                                    _helper.inventory:DropItemFromInvTile(item, false)
                                elseif d.smith == "rs" or d.smith == "re" then
                                    e = item
                                    r = d
                                    break
                                end
                            else
                                tools.send("解析失败")
                                Sleep(1)
                            end
                        elseif (t == "ore" or t == "additive" or t == "flame" or t == "resolve" or t == "enlight") and _helper:EmptySlot(2) then
                            _helper:MoveSlotOut(i, _anvil)
                        else
                            _helper.inventory:DropItemFromInvTile(item, false)
                        end
                        Sleep(0.2)
                    end
                else
                    _helper.inventory:DropItemFromInvTile(item, false)
                end
            end
        end
        Sleep(0.2)
        if e then
            local add, enough = Add(r)
            r.add = add
            _anvils[_anvil] = r
            if enough then
                for k, v in pairs(add) do
                    for i=1, co:GetNumSlots() do
                        if not co:GetItemInSlot(i) then
                            local si
                            local active
                            while self.run and _anvil:IsValid() and co:IsOpenedBy(self.inst) and (not si or tools.count(si) < v) do
                                if active then
                                    if active.prefab == k then
                                        if si then
                                            if tools.count(active) > 1 then
                                                co:AddOneOfActiveItemToSlot(i)
                                            else
                                                co:AddAllOfActiveItemToSlot(i)
                                            end
                                        else
                                            if tools.count(active) > 1 then
                                                co:PutOneOfActiveItemInSlot(i)
                                            else
                                                co:PutAllOfActiveItemInSlot(i)
                                            end
                                        end
                                    else
                                        _helper.inventory:ReturnActiveItem()
                                    end
                                else
                                    _helper:Take(k)
                                end
                                
                                Sleep(0.25)
                                si = co:GetItemInSlot(i)
                                active = _helper.inventory:GetActiveItem()
                            end
                            
                            _helper.inventory:ReturnActiveItem()
                            local has,num = ThePlayer.replica.inventory:Has("resolve_reel", 1)
                            if _cfg.general.buy  and num < 5 then
                                tools.send("购买分解符")
                                SendModRPCToServer(MOD_RPC.ebshop.buy,"resolve_reel",json.encode({right = true, cate = nil}, true))
                            end
                            if tools.count(si) > 1 then
                                while self.run and not _helper.inventory:GetActiveItem() do
                                    co:TakeActiveItemFromAllOfSlot(i)
                                    Sleep(0.2)
                                end
                                while self.run and not co:GetItemInSlot(i) do
                                    co:PutAllOfActiveItemInSlot(i)
                                    Sleep(0.2)
                                end
                            end
                            break
                        end
                    end
                end
                local sb = Decode(_anvil)
                if _anvil:IsValid() and co:IsOpenedBy(self.inst) and sb and sb.t == r.smith then
                    SendRPCToServer(RPC.DoWidgetButtonAction, ACTIONS.SMITH_ACTION.code, _anvil, ACTIONS.SMITH_ACTION.mod_name)
                    if sb.t == "rs" then
                        _anvils[_anvil] = nil
                    elseif sb.t == "re" and r.dur > 1 then
                        r.dur = r.dur - 1
                    end
                end
            else
                co:Close()
            end
        else
            if _helper:MoveIn(nil, nil, function(e) return IsForgeable(e) end, _anvil) then
                DoAnvil()
            elseif _key then
                while self.run and _anvil:IsValid() and co:IsOpenedBy(self.inst) do
                    _helper:MoveIn(nil, nil, function(e) return _unite[e] == _key end, _anvil)
                    Sleep(0.25)
                    local sb = Decode(_anvil)
                    if sb and sb.t == "fu" then
                        SendRPCToServer(RPC.DoWidgetButtonAction, ACTIONS.SMITH_ACTION.code, _anvil, ACTIONS.SMITH_ACTION.mod_name)
                        break
                    end
                end
            else
                _anvils[_anvil] = {smith = "rf"}
                co:Close()
            end
        end
        Sleep(0.25)
    end
end

local function DoFix()
    if _items[_fix_item] then
        _helper.inventory:ControllerUseItemOnItemFromInvTile(_fix_equip, _items[_fix_item].ent[1])
    else
        _helper:Buy(_fix_item, nil, 0.2)
    end
end

local function Check()
    while self.run do
        Report()
        if TheNet:GetServerName() == "" then
            _error = "已断开连接"
        elseif self.inst:HasTag("corpse") then
            TheNet:SendSlashCmdToServer("giveup", true)
        elseif self.inst:HasTag("playerghost") then
            local cost = _helper.gflevel:GetLevel() * 20
            if not _helper.gftrade:Afford(cost) then
                _error = string.format("复活金币不足 %d", cost)
            else
                TheNet:SendSlashCmdToServer("revivehere", true)
            end
        end
        
        Sleep(0.3)
    end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

_helper = Helper(inst)
_parser = Parser(inst)

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:Init(config, nocheck)
    if not ThePlayer then
        return false
    end
    
    _cfg = config
    
    if nocheck then
        return
    end
    
    
    _error = nil
    _report_time = 0
    
    _equips = {}
    _retain = {}
    _need = {}
    _unite = {}
    _anvils = {}
    _start_pos = self.inst:GetPosition()
    self.pos = _start_pos
    _start_time = os.time()
    _border_start = Point(_start_pos.x - _cfg.general.range, 0, _start_pos.z - _cfg.general.range)
    _border_end = Point(_start_pos.x + _cfg.general.range, 0, _start_pos.z + _cfg.general.range)
    _cfg.general.range = _cfg.general.range * 1.42
    
    
    for _, v in pairs(EQUIPSLOTS) do
        _equips[v] = _helper.inventory:GetEquippedItem(v)
    end
    
    if not _equips.hands then
        tools.talk("没有武器")
        return false
    end
    
    local anvils = FindAnvil()
    
    if #anvils <= 0 then
        tools.talk("没有 " .. tools.get_name(ANVIL))
        return false
    end
    
    tools.send(tools.get_name(ANVIL) .. ": " .. #anvils)
    
    for g, v in pairs(GF_GROUPS) do
        _cfg[g].key = g
        local skills = {}
        for _, s in ipairs(GF_SKILLS) do
            if _cfg[g].skills[s.key] then
                skills[s.name] = _cfg[g].skills[s.key]
            end
        end
        
        _cfg[g].skills = skills
        
        for p, q in pairs(v) do
            _cfg[g][p] = q 
        end
    end
    
    return true
end

function self:Main()
    self.run = true
    self.inst:StartThread(function()
        Check()
    end)
    Report()
    while self.run and not _error and not IsDead() do
        RefreshItem()
        if _helper.inventory:GetActiveItem() then
            if _es > 0 then
                _helper.inventory:ReturnActiveItem()
            else
                _helper.inventory:DropItemFromInvTile(_helper.inventory:GetActiveItem())
            end
        elseif not EquipCheck() then
            Sleep(0.1)
        elseif ShouldFix() then
            DoFix()
		elseif ShouldPack() then
            _helper.inventory:UseItemFromInvTile(_items[WRAP_ITEM].ent[1])
            Sleep(0.5)
            local bundle =_helper:Find(nil,0x4,{"bundle", "_container"},nil,nil,nil,function(e) return e.replica.container:IsOpenedBy(self.inst) end)[1]
            if bundle then
                local start = os.time()
                while bundle:IsValid() and bundle.replica.container and 
					not bundle.replica.container:IsFull() and
                    --not ShouldAttack() and 
					os.time() - start < 0x3 do
                    for _, v in ipairs(_pack) do
                        v.container:MoveItemFromAllOfSlot(v.slot,bundle)
                        Sleep(0.1)
                        end
                    end
                if bundle:IsValid() and bundle.replica.container and #bundle.replica.container:GetItems() >= 0x2 then
                            SendRPCToServer(RPC.DoWidgetButtonAction,ACTIONS.WRAPBUNDLE.code,bundle,ACTIONS.WRAPBUNDLE.mod_name)
                            Sleep(0x1)
                end
            end
        elseif ShouldPick() then
            for _, v in ipairs(_loot) do
                while self.run and v:IsValid() and not v.replica.inventoryitem:IsGrandOwner(self.inst) do
                    _helper:Do(nil, v)
                    Sleep(0.25)
                end
            end
        elseif ShouldUnpack() then
            _helper.inventory:UseItemFromInvTile(_unpack)
        elseif ShouldAnvil() then
            DoAnvil() 
        elseif self.inst:GetDistanceSqToPoint(_start_pos:Get()) > 25 then
            _helper:GoToPoint(_start_pos)
        elseif ShouldDrop() then
            _helper.inventory:DropItemFromInvTile(_drop, false)
        end
        Sleep(0.2)
    end
    
    self.run = false
    if _error then
        return _error
    end
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)