local function register(mod, id)
    function mod:TripleHomingCache(player, cacheFlag)
        if player:HasCollectible(id) then
            if cacheFlag == CacheFlag.CACHE_DAMAGE then
                player.Damage = player.Damage * 3
            end
            if cacheFlag == CacheFlag.CACHE_TEARFLAG then
                player.TearFlags = player.TearFlags | TearFlags.TEAR_HOMING
            end
        end
    end
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.TripleHomingCache)
end

return register