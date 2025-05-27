return function(mod, id)
    -- 가장 가까운 적 찾기 함수
    function mod:MiniNickClosestEnemy(pos)
        local entities = Isaac.GetRoomEntities()
        local closest, dist = nil, 999999
        for _, e in ipairs(entities) do
            if e:IsVulnerableEnemy() and not e:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
                local d = (e.Position - pos):LengthSquared()
                if d < dist then
                    closest, dist = e, d
                end
            end
        end
        return closest
    end

    -- familiar 초기화
    function mod:MiniNickInit(fam)
        fam:AddToFollowers()
        fam.FireCooldown = 0
        local data = fam:GetData()
        data.ShootAnimTimer = 0
        data.LastShotDir = Vector(0, 1)
    end
    mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, mod.MiniNickInit, Isaac.GetEntityVariantByName("Mini Nick"))

    -- 캐시 처리
    function mod:MiniNickOnCache(player, cacheFlag)
        if cacheFlag == CacheFlag.CACHE_FAMILIARS then
            local count = player:GetCollectibleNum(id)
            player:CheckFamiliar(Isaac.GetEntityVariantByName("Mini Nick"), count, player:GetCollectibleRNG(id))
        end
    end
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.MiniNickOnCache)

    -- 애니메이션 분기용 (간단히 4방향)
    local DIRECTION_FLOAT_ANIM = {
        [Direction.NO_DIRECTION] = "FloatDown",
        [Direction.LEFT] = "FloatSide",
        [Direction.UP] = "FloatUp",
        [Direction.RIGHT] = "FloatSide",
        [Direction.DOWN] = "FloatDown"
    }
    local DIRECTION_SHOOT_ANIM = {
        [Direction.NO_DIRECTION] = "FloatShootDown",
        [Direction.LEFT] = "FloatShootSide",
        [Direction.UP] = "FloatShootUp",
        [Direction.RIGHT] = "FloatShootSide",
        [Direction.DOWN] = "FloatShootDown"
    }

    local function dirToAnimDir(vec)
        local angle = vec:GetAngleDegrees()
        if angle > -45 and angle <= 45 then
            return Direction.RIGHT
        elseif angle > 45 and angle <= 135 then
            return Direction.DOWN
        elseif angle <= -45 and angle > -135 then
            return Direction.UP
        else
            return Direction.LEFT
        end
    end

    -- familiar 업데이트
    function mod:MiniNickUpdate(fam)
        fam:FollowParent()
        local player = fam.Player
        local sprite = fam:GetSprite()
        fam.FireCooldown = fam.FireCooldown or 0

        local data = fam:GetData()
        data.ShootAnimTimer = data.ShootAnimTimer or 0
        data.LastShotDir = data.LastShotDir or Vector(0, 1)

        local fireVec = Vector(0, 1)
        local shootAnim, idleAnim
        local animFlipX = false

        local player_fire_direction = player:GetFireDirection()
        local hasKingBaby = player:HasCollectible(CollectibleType.COLLECTIBLE_KING_BABY)
        local useAutoAim = false

        -- King Baby 효과 + 공격 중일 때만 적 자동조준
        if hasKingBaby and player_fire_direction ~= Direction.NO_DIRECTION then
            local enemy = mod:MiniNickClosestEnemy(fam.Position)
            if enemy then
                fireVec = (enemy.Position - fam.Position):Normalized()
                useAutoAim = true
                -- 애니메이션 방향 결정
                local angle = fireVec:GetAngleDegrees()
                if angle > -45 and angle <= 45 then
                    shootAnim = "FloatShootSide"
                    idleAnim = "FloatSide"
                    animFlipX = false
                elseif angle > 45 and angle <= 135 then
                    shootAnim = "FloatShootDown"
                    idleAnim = "FloatDown"
                    animFlipX = false
                elseif angle <= -45 and angle > -135 then
                    shootAnim = "FloatShootUp"
                    idleAnim = "FloatUp"
                    animFlipX = false
                else
                    shootAnim = "FloatShootSide"
                    idleAnim = "FloatSide"
                    animFlipX = true
                end
            end
        end

        if not useAutoAim then
            if player_fire_direction == Direction.LEFT then
                fireVec = Vector(-1, 0)
                shootAnim = "FloatShootSide"
                idleAnim = "FloatSide"
                animFlipX = true
            elseif player_fire_direction == Direction.UP then
                fireVec = Vector(0, -1)
                shootAnim = "FloatShootUp"
                idleAnim = "FloatUp"
                animFlipX = false
            elseif player_fire_direction == Direction.RIGHT then
                fireVec = Vector(1, 0)
                shootAnim = "FloatShootSide"
                idleAnim = "FloatSide"
                animFlipX = false
            elseif player_fire_direction == Direction.DOWN then
                fireVec = Vector(0, 1)
                shootAnim = "FloatShootDown"
                idleAnim = "FloatDown"
                animFlipX = false
            else
                fireVec = Vector(0, 1)
                shootAnim = "FloatDown"
                idleAnim = "FloatDown"
                animFlipX = false
            end
        end

        -- 눈물 쏘는 쪽 방향 기억
        sprite.FlipX = animFlipX

        if player_fire_direction ~= Direction.NO_DIRECTION then
            if fam.FireCooldown <= 0 then
                local tear = fam:FireProjectile(fireVec)
                if tear then
                    tear.CollisionDamage = 1.5
                end
                fam.FireCooldown = 30
                data.ShootAnimTimer = 15
                data.LastShotDir = fireVec -- 방향 저장!
            else
                fam.FireCooldown = fam.FireCooldown - 1
            end

            if data.ShootAnimTimer > 0 then
                if not sprite:IsPlaying(shootAnim) then
                    sprite:Play(shootAnim, false)
                end
                data.ShootAnimTimer = data.ShootAnimTimer - 1
            else
                -- Idle: 마지막 쏜 방향 기준
                local lastDir = dirToAnimDir(data.LastShotDir)
                local lastIdleAnim = DIRECTION_FLOAT_ANIM[lastDir]
                sprite.FlipX = (lastDir == Direction.LEFT)
                if not sprite:IsPlaying(lastIdleAnim) then
                    sprite:Play(lastIdleAnim, false)
                end
            end
        else
            -- Idle: 마지막 쏜 방향 기준
            local lastDir = dirToAnimDir(data.LastShotDir)
            local lastIdleAnim = DIRECTION_FLOAT_ANIM[lastDir]
            sprite.FlipX = (lastDir == Direction.LEFT)
            if not sprite:IsPlaying(lastIdleAnim) then
                sprite:Play(lastIdleAnim, false)
            end
            fam.FireCooldown = 0
            data.ShootAnimTimer = 0
        end
    end

    -- EID 설명 등록
    if EID then
        EID:addCollectible(
            id,
            "#공격방향으로 공격력 1.5의 눈물을 발사합니다."..
            "#↑ 공격키를 빠르게 누를수록 빠르게 발사합니다"
        )
    end

    mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, mod.MiniNickUpdate, Isaac.GetEntityVariantByName("Mini Nick"))
end
