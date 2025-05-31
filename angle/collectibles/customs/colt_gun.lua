    return function(mod, id)
        local BURST_DELAY = 2
        local SPREAD_DEGREES = 7

        local getIsaacTearsMultiplier = require("angle.collectibles.customs.tearsMult")

        local burstQueue = {}

        -- 두유/아몬드밀크만 점사 개수 줄이기
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
                    local tearsMult = getIsaacTearsMultiplier(player) * 0.5
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

        -- 각 눈물의 점사 정보를 큐에 저장 + 원본 눈물 삭제
        function mod:OnFireTear(tear)
            local player = tear.SpawnerEntity and tear.SpawnerEntity:ToPlayer()
            if player and player:HasCollectible(id) then
                local idx = player:GetCollectibleRNG(id):GetSeed() .. tostring(player.InitSeed)
                burstQueue[idx] = burstQueue[idx] or {}

                table.insert(burstQueue[idx], {
                    remain = getBurstCount(player), -- 점사 개수
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

        -- 점사 눈물 자동 생성 (플레이어 현재 위치에서 생성)
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

        -- 눈물 비행 Idle/Death 애니 적용
        function mod:ColtTearSkin(tear)
            local player = tear.SpawnerEntity and tear.SpawnerEntity:ToPlayer()
            local angle = tear.Velocity:GetAngleDegrees()
            
            if player and player:HasCollectible(id) then
                spr.Rotation = angle
                local spr = tear:GetSprite()
                spr:ReplaceSpritesheet(0, "gfx/colt_tear.png")
                spr:Load("gfx/colt_tear.anm2", true)
                spr:Play("Idle", true)
                spr:SetFrame("Idle", 0)
            end
        end
        mod:AddCallback(ModCallbacks.MC_POST_TEAR_INIT, mod.ColtTearSkin)

        -- 눈물 소멸 시 Death 이펙트 생성
        local COLT_DEATH_EFFECT = 9200 -- 예시. mod에서 등록한 EffectVariant

        function mod:ColtTearDeathEffect(tear)
            local player = tear.SpawnerEntity and tear.SpawnerEntity:ToPlayer()
            if player and player:HasCollectible(id) then
                if tear:IsDead() then
                    local eff = Isaac.Spawn(EntityType.ENTITY_EFFECT, COLT_DEATH_EFFECT, 0, tear.Position, Vector(0,0), player):ToEffect()
                    local spr = eff:GetSprite()
                    spr:Play("Death", true)
                    spr.Rotation = tear:GetSprite().Rotation or 0
                end
            end
        end
        mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, mod.ColtTearDeathEffect)



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
