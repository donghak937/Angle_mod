return function(mod, id)
    local BURST_DELAY = 2
    local SPREAD_DEGREES = 7
    local COLT_TEAR_VARIANT = Isaac.GetEntityVariantByName("colt_tear") or 9201

    local ColtTear = {}
    ColtTear.GFX = "gfx/colt_tear.png"
    ColtTear.ANM2 = "gfx/colt_tear.anm2"
    ColtTear.DEATH_EFFECT = 9200

    function ColtTear:Init(tear, player)
        if not tear or not player or not player:HasCollectible(id) then return end
        local spr = tear:GetSprite()
        spr:ReplaceSpritesheet(0, ColtTear.GFX)
        spr:Load(ColtTear.ANM2, true)
        spr:Play("Idle", true)
        spr:SetFrame("Idle", 0)
        spr.Rotation = tear.Velocity:GetAngleDegrees() + 180
    end

    function ColtTear:Update(tear, player)
        if not tear or not player or not player:HasCollectible(id) then return end
        tear:GetSprite().Rotation = tear.Velocity:GetAngleDegrees() + 180
    end

    local burstQueue = {}

    local function getBurstCount(player)
        if player:HasCollectible(CollectibleType.COLLECTIBLE_SOY_MILK)
            or player:HasCollectible(CollectibleType.COLLECTIBLE_ALMOND_MILK) then
            return 2
        end
        return 6
    end

    function mod:ColtGunCache(player, cacheFlag)
        if player:HasCollectible(id) then
            if cacheFlag == CacheFlag.CACHE_FIREDELAY then
                local tearsMult = require("angle.collectibles.customs.tearsMult")(player) * 0.5
                if tearsMult ~= 0 then
                    player.MaxFireDelay = player.MaxFireDelay / tearsMult
                end
            end
            if cacheFlag == CacheFlag.CACHE_SHOTSPEED then
                player.ShotSpeed = player.ShotSpeed + 0.5
            end
        end
    end
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.ColtGunCache)

    function mod:ColtGunCacheRefresh(player)
        if player:HasCollectible(id) then
            player:AddCacheFlags(
                CacheFlag.CACHE_FIREDELAY |
                CacheFlag.CACHE_SHOTSPEED |
                CacheFlag.CACHE_TEARFLAG
            )
            player:EvaluateItems()
        end
    end
    mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.ColtGunCacheRefresh)

    function mod:OnFireTear(tear)
        local player = tear.SpawnerEntity and tear.SpawnerEntity:ToPlayer()
        if player and player:HasCollectible(id) then
            local idx = player:GetCollectibleRNG(id):GetSeed() .. tostring(player.InitSeed)
            burstQueue[idx] = burstQueue[idx] or {}

            table.insert(burstQueue[idx], {
                remain = getBurstCount(player),
                delay = 0,
                angle = tear.Velocity:GetAngleDegrees(),
                speed = tear.Velocity:Length(),
                flags = tear.TearFlags,
                color = tear.Color,
                damage = tear.CollisionDamage,
                scale = tear.Scale,
                player = player,
                pos = tear.Position
            })
            tear:Remove()
        end
    end
    mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, mod.OnFireTear)

    function mod:GlobalBurstTearUpdate()
        for p = 0, Game():GetNumPlayers()-1 do
            local player = Isaac.GetPlayer(p)
            local idx = player:GetCollectibleRNG(id):GetSeed() .. tostring(player.InitSeed)
            burstQueue[idx] = burstQueue[idx] or {}
            local newQueue = {}
            for i, data in ipairs(burstQueue[idx]) do
                if data.remain > 0 then
                    data.delay = (data.delay or 0) - 1
                    if data.delay <= 0 then
                        local spread = (math.random() - 0.5) * 2 * SPREAD_DEGREES
                        local angle = (data.angle or 0) + spread
                        local velocity = Vector(data.speed or 10, 0):Rotated(angle)
                        local newTear = Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, data.player.Position, velocity, data.player):ToTear()
                        newTear:ChangeVariant(COLT_TEAR_VARIANT)   -- ★ 커스텀 눈물 Variant로 바꿔주기!
                        newTear.TearFlags = data.flags or 0
                        newTear.Color = data.color or Color(1,1,1,1)
                        newTear.CollisionDamage = data.damage or data.player.Damage
                        newTear.Scale = data.scale or 1
                        data.remain = data.remain - 1
                        data.delay = BURST_DELAY
                    end
                    if data.remain > 0 then
                        table.insert(newQueue, data)
                    end
                end
            end
            burstQueue[idx] = newQueue
        end
    end
    mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.GlobalBurstTearUpdate)

    -- 커스텀 눈물 그래픽/회전 관리
    function mod:ColtTearInit(tear)
        local player = tear.SpawnerEntity and tear.SpawnerEntity:ToPlayer()
        ColtTear:Init(tear, player)
    end
    mod:AddCallback(ModCallbacks.MC_POST_TEAR_INIT, mod.ColtTearInit, COLT_TEAR_VARIANT)

    function mod:ColtTearUpdate(tear)
        local player = tear.SpawnerEntity and tear.SpawnerEntity:ToPlayer()
        ColtTear:Update(tear, player)
    end
    mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, mod.ColtTearUpdate, COLT_TEAR_VARIANT)

    -- 눈물 소멸 시 Death Effect만 Spawn
    function mod:OnColtTearRemove(entity)
        local tear = entity:ToTear()
        if not tear then return end
        if tear.Variant ~= COLT_TEAR_VARIANT then return end
        local eff = Isaac.Spawn(EntityType.ENTITY_EFFECT, ColtTear.DEATH_EFFECT, 0, tear.Position, Vector(0,0), tear)
        local spr = eff:GetSprite()
        if spr then
            spr:Play("Death", true)
            spr.Rotation = tear:GetSprite().Rotation or 0
        end
    end
    mod:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, mod.OnColtTearRemove, EntityType.ENTITY_TEAR)

    if EID then
        EID:addCollectible(
            id,
            "#↑ 눈물 속도 +0.5가 증가합니다."..
            "#소지 시 모든 눈물이 점사로 발사되고, 각 발은 colt_tear 애니메이션이 적용됩니다."..
            "#↓ 연사 속도가 절반으로 감소합니다.",
            "Colt Gun"
        )
    end
end
