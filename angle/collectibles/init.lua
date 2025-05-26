local ollo_head = require("angle.collectibles.customs.ollo_head")
local ollo_suit = require("angle.collectibles.customs.ollo_suit")

local function register_collectibles(mod, ids)
    ollo_head(mod, ids.ollo_head)
    ollo_suit(mod, ids.ollo_suit)
    -- 필요시 다른 아이템도 여기에 추가
end

return register_collectibles