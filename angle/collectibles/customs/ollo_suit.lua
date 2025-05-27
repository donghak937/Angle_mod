local SUIT_TIMER_KEY = "OlloSuit_Timer"
local SUIT_STATE_KEY = "OlloSuit_State"
local SUIT_PREV_STATE_KEY = "OlloSuit_PrevState"
local DAMAGE_DURATION = 30 * 120
local getIsaacDamageMultiplier = require("angle.collectibles.customs.mult")

return function(mod, id)
    function mod:OlloSuitPickup(player)
        if player:HasCollectible(id) and not player:GetData().olloSuitPicked then
            player:AddMaxHearts(2)
            player:AddHearts(2)
            player:GetData().olloSuitPicked = true
        end
    end

    mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.OlloSuitPickup)

    function mod:OlloSuitTimer(player)
        if player:HasCollectible(id) then
            local data = player:GetData()
            data[SUIT_TIMER_KEY] = data[SUIT_TIMER_KEY] or 0
            data[SUIT_STATE_KEY] = data[SUIT_STATE_KEY] or "boost"
            data[SUIT_PREV_STATE_KEY] = data[SUIT_PREV_STATE_KEY] or data[SUIT_STATE_KEY]

            if data[SUIT_STATE_KEY] == "boost" then
                data[SUIT_TIMER_KEY] = data[SUIT_TIMER_KEY] + 1
                if data[SUIT_TIMER_KEY] % 60 == 0 then
                end
                if data[SUIT_TIMER_KEY] >= DAMAGE_DURATION then
                    data[SUIT_STATE_KEY] = "nerf"
                end
            end

            if data[SUIT_STATE_KEY] ~= data[SUIT_PREV_STATE_KEY] then
                player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
                player:EvaluateItems()
                data[SUIT_PREV_STATE_KEY] = data[SUIT_STATE_KEY]
            end
        end
    end
    mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.OlloSuitTimer)

    function mod:OlloSuitCache(player, cacheFlag)
        if player:HasCollectible(id) then
            local state = player:GetData()[SUIT_STATE_KEY] or "boost"
            
            if cacheFlag == CacheFlag.CACHE_DAMAGE then
                local mult = getIsaacDamageMultiplier(player)
                if state == "boost" then
                    player.Damage = player.Damage + 3 * mult
                else
                    player.Damage = player.Damage + 0.3 * mult
                end
            end
        end
    end
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.OlloSuitCache)

    if EID then
        EID:addCollectible(
            id,
            "#↑ 먹는 순간 2분 동안 공격력 +3이 증가합니다."..
            "# 2분 후 {{DamageSmall}} 효과가 사라지고 공격력 +0.3이 증가합니다"..
            "#{{Heart}} 최대 체력 +1",
            "Ollo Suit"
        )
    end
end
