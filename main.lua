angle = RegisterMod("angle", 1)
local mod = angle

angle.Items = {
    ollo_head = Isaac.GetItemIdByName("Ollo Head"),
    ollo_suit = Isaac.GetItemIdByName("Ollo Suit"),
    mini_nick = Isaac.GetItemIdByName("Mini Nick"),
    carls_weapon = Isaac.GetItemIdByName("Carl's Weapon"),
    -- 다른 아이템도 여기에 추가!
}

local register_collectibles = require("angle.collectibles.init")
register_collectibles(mod, angle.Items)