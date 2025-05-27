angle.collectible = angle.collectible or {}   -- 전역 네임스페이스 안전하게

local ollo_head = require("angle.collectibles.customs.ollo_head")
local ollo_suit = require("angle.collectibles.customs.ollo_suit")
local mini_nick = require("angle.collectibles.customs.mini_nick")

local function register_collectibles(angle, ids)
    ollo_head(angle, ids.ollo_head)
    ollo_suit(angle, ids.ollo_suit)
    mini_nick(angle, ids.mini_nick)
    -- 필요하면 추가 아이템도 여기에!
end

return register_collectibles