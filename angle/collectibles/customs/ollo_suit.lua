local SUIT_TIMER_KEY = "OlloSuit_Timer"
local SUIT_STATE_KEY = "OlloSuit_State"
local SUIT_PREV_STATE_KEY = "OlloSuit_PrevState"
local DAMAGE_DURATION = 60 * 120


return function(mod, id)
    function mod:OlloSuitPickup(player)
        if player:HasCollectible(id) and not player:GetData().olloSuitPicked then
            --print("[OlloSuit] First time pickup: Max HP up!")
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
                    print("[OlloSuit] boost state ongoing..." .. tostring(data[SUIT_TIMER_KEY] / 60) .. " Sec")
                end
                if data[SUIT_TIMER_KEY] >= DAMAGE_DURATION then
                    print("[OlloSuit] boost → nerf state transition!")
                    data[SUIT_STATE_KEY] = "nerf"
                end
            end

            -- 상태 변화 시점에만 캐시 리셋
            if data[SUIT_STATE_KEY] ~= data[SUIT_PREV_STATE_KEY] then
                print("[OlloSuit] [OlloSuit] Damage cache evaluation! State: ", data[SUIT_PREV_STATE_KEY], "now:", data[SUIT_STATE_KEY])
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
                print("[OlloSuit] Damage cache evaluation! State:", state, "Damage was:", player.Damage)
                if state == "boost" then
                    player.Damage = player.Damage + 3
                    --print("[OlloSuit] boost: Damage +3 applied →", player.Damage)
                else
                    player.Damage = player.Damage + 0.3
                    --print("[OlloSuit] nerf: Damage +0.3 applied →", player.Damage)
                end
            end
        end
    end
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.OlloSuitCache)

    if EID then
        EID:addCollectible(
            id,
            "먹는 순간 2분 동안 데미지 +3#2분 후 데미지 +0.3#최대 체력 +1 (채워짐)",
            "Ollo Suit"
        )
    end
end
