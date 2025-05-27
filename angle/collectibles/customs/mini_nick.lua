local mini_nick_mod = RegisterMod("Mini Nick", 1)
local mini_nick_item = Isaac.GetItemIdByName("Mini Nick")
local mini_nick_familiar = Isaac.GetEntityVariantByName("Mini Nick")

if EID then
    EID:addCollectible(
        mini_nick_item,
        "{{Baby}} 바라보는 방향으로 눈물을 발사하며, King Baby 효과 시 가장 가까운 적을 자동 추적합니다.",
        "Mini Nick"
    )
end

function mini_nick_mod:closestEnemy(pos)
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

function mini_nick_mod:init(fam)
    fam:AddToFollowers()
    fam.FireCooldown = 0
end
mini_nick_mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, mini_nick_mod.init, mini_nick_familiar)

function mini_nick_mod:on_cache(player, cacheFlag)
    if cacheFlag == CacheFlag.CACHE_FAMILIARS then
        local count = player:GetCollectibleNum(mini_nick_item)
        player:CheckFamiliar(mini_nick_familiar, count, player:GetCollectibleRNG(mini_nick_item))
    end
end
mini_nick_mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mini_nick_mod.on_cache)

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

function mini_nick_mod:update(fam)
    fam:FollowParent()
    local player = fam.Player
    local sprite = fam:GetSprite()
    fam.FireCooldown = fam.FireCooldown or 0

    -- 사격 방향 설정
    local fireVec = Vector(0, 1)
    local shootAnim, idleAnim
    local animFlipX = false

    local player_fire_direction = player:GetFireDirection()
    local hasKingBaby = player:HasCollectible(CollectibleType.COLLECTIBLE_KING_BABY)
    local useAutoAim = false

    -- King Baby 효과 시: 가까운 적 자동조준
    if hasKingBaby then
        local enemy = mini_nick_mod:closestEnemy(fam.Position)
        if enemy then
            fireVec = (enemy.Position - fam.Position):Normalized()
            useAutoAim = true
            -- 방향 결정(애니메이션용, 간단화)
            local angle = fireVec:GetAngleDegrees()
            if angle > -45 and angle <= 45 then -- 오른쪽
                shootAnim = "FloatShootSide"
                idleAnim = "FloatSide"
                animFlipX = false
            elseif angle > 45 and angle <= 135 then -- 아래
                shootAnim = "FloatShootDown"
                idleAnim = "FloatDown"
                animFlipX = false
            elseif angle <= -45 and angle > -135 then -- 위
                shootAnim = "FloatShootUp"
                idleAnim = "FloatUp"
                animFlipX = false
            else -- 왼쪽
                shootAnim = "FloatShootSide"
                idleAnim = "FloatSide"
                animFlipX = true
            end
        end
    end

    -- King Baby 효과가 없거나, 적이 없다면 플레이어 방향으로
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

    sprite.FlipX = animFlipX

    -- 사격(조건: 플레이어가 발사중이거나, King Baby가 있으면 자동)
    if (player_fire_direction ~= Direction.NO_DIRECTION or useAutoAim) then
        if not sprite:IsPlaying(shootAnim) then
            sprite:Play(shootAnim, false)
        end
        if fam.FireCooldown <= 0 then
            local tear = fam:FireProjectile(fireVec)
            if tear then
                tear.CollisionDamage = 1.5
            end
            fam.FireCooldown = 9
        else
            fam.FireCooldown = fam.FireCooldown - 1
        end
    else
        if not sprite:IsPlaying(idleAnim) then
            sprite:Play(idleAnim, false)
        end
        fam.FireCooldown = 0
    end
end
mini_nick_mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, mini_nick_mod.update, mini_nick_familiar)
