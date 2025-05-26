local function register(mod, id)
    function mod:OlloHeadCache(player, cacheFlag)
        if player:HasCollectible(id) then
            print("OlloHead 콜백 진입!", id, cacheFlag)
            if cacheFlag == CacheFlag.CACHE_SHOTSPEED then
                player.ShotSpeed = player.ShotSpeed + 0.7
                print("눈물속도 +0.7!")
            end
            if cacheFlag == CacheFlag.CACHE_TEARFLAG then
                player.TearFlags = player.TearFlags | TearFlags.TEAR_HOMING
                print("유도효과 추가!")
            end
        end
    end
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.OlloHeadCache)

    function mod:OlloHeadCacheRefresh(player)
        if player:HasCollectible(id) then
            player:AddCacheFlags(CacheFlag.CACHE_SHOTSPEED | CacheFlag.CACHE_TEARFLAG)
            player:EvaluateItems()
            print("캐시 강제갱신!")
        end
    end
    mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.OlloHeadCacheRefresh)
end

return register