local getIsaacTearsMultiplier = require("angle.collectibles.customs.tearsMult")


return function(mod, id)
    -- 아이템 효과 등록
    function mod:OlloHeadCache(player, cacheFlag)
        if player:HasCollectible(id) then
            if cacheFlag == CacheFlag.CACHE_SHOTSPEED then
                player.ShotSpeed = player.ShotSpeed + 0.7
            end
            if cacheFlag == CacheFlag.CACHE_TEARFLAG then
                player.TearFlags = player.TearFlags | TearFlags.TEAR_HOMING
            end
        end
    end
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.OlloHeadCache)

    function mod:OlloHeadCacheRefresh(player)
        if player:HasCollectible(id) then
            player:AddCacheFlags(CacheFlag.CACHE_SHOTSPEED | CacheFlag.CACHE_TEARFLAG)
            player:EvaluateItems()
        end
    end
    mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.OlloHeadCacheRefresh)

    -- EID 설명 등록 (여기서 관리!)
    if EID then
        EID:addCollectible(
            id,
            "#↑ 눈물 속도 +0.7가 증가합니다."..
            "#{{Collectible3}} 유도 눈물을 발사합니다.",
            "Ollo Head"
        )
    end
end
