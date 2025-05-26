local mod = RegisterMod("My Mod", 1)

local ids = {
    ollo_head = Isaac.GetItemIdByName("Ollo Head"),
    -- 필요시 다른 아이템 id도 같이!
}

local register_collectibles = require("angle.collectibles.init")
register_collectibles(mod, ids)