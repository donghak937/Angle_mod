local triple_homing = require("customs.triple_homing")

local function register_collectibles(mod, ids)
    triple_homing(mod, ids.triple_homing)
    -- 필요시 다른 아이템도 여기에 추가
end

return register_collectibles