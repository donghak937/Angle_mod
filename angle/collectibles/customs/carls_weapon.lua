return function(mod, id)
    local CARL_BOOMERANG_VARIANT = 8654
    local collectible = id

    --------------------
    -- Ready 취소 함수
    --------------------
    local function TryCancelCarlBoomerang(player)
        if player:GetData().carlReady then
            player:GetData().carlReady = false
            player:GetData().carlPrevAim = Vector.Zero
            player:GetData().carlPrevFire = Direction.NO_DIRECTION
            player:AnimateCollectible(collectible, "HideItem", "PlayerPickup")
        end
    end

    ------------------------------
    -- 액티브 사용: Ready 진입
    ------------------------------
    function mod:UseCarlActive(_, rng, player, useFlags, activeSlot, varData)
        if not player:GetData().carlReady then
            player:GetData().carlReady = true
            player:GetData().carlPrevAim = Vector.Zero
            player:GetData().carlPrevFire = Direction.NO_DIRECTION
            player:GetData().carlActiveSlot = activeSlot
            player:AnimateCollectible(collectible, "LiftItem", "PlayerPickup")
        else
            TryCancelCarlBoomerang(player)
        end
        return {Discharge = false, Remove = false, ShowAnim = false}
    end
    mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.UseCarlActive, collectible)

    -----------------------------------------------
    -- 실제 발사 트리거: Aim+FireDirection 동시 지원
    -----------------------------------------------
    function mod:CarlActivePlayerUpdate(player)
        local data = player:GetData()
        data.carlReady = data.carlReady or false
        data.carlPrevAim = data.carlPrevAim or Vector.Zero
        data.carlPrevFire = data.carlPrevFire or Direction.NO_DIRECTION

        local curAim = player:GetAimDirection()
        local curFire = player:GetFireDirection()

        -- 트리거: Aim이나 Fire가 새로 눌렸을 때
        local aimTriggered = (data.carlPrevAim:Length() < 1e-3 and curAim:Length() > 1e-3)
        local fireTriggered = (data.carlPrevFire == Direction.NO_DIRECTION and curFire ~= Direction.NO_DIRECTION)

        if data.carlReady and (aimTriggered or fireTriggered) then
            -- 실제 발사 방향 계산
            local finalDir
            if curAim:Length() > 1e-3 then
                finalDir = curAim
            else
                if curFire == Direction.LEFT then
                    finalDir = Vector(-1, 0)
                elseif curFire == Direction.RIGHT then
                    finalDir = Vector(1, 0)
                elseif curFire == Direction.UP then
                    finalDir = Vector(0, -1)
                elseif curFire == Direction.DOWN then
                    finalDir = Vector(0, 1)
                else
                    finalDir = Vector(1, 0)
                end
            end

            mod:SpawnCarlBoomerang(player, finalDir)
            data.carlReady = false

            local slot = data.carlActiveSlot or ActiveSlot.SLOT_PRIMARY
            if slot == ActiveSlot.SLOT_PRIMARY then
                if player:GetActiveItem(slot) ~= collectible or player:GetActiveCharge(slot) < Isaac.GetItemConfig():GetCollectible(collectible).MaxCharges then
                    slot = ActiveSlot.SLOT_SECONDARY
                end
            end
            player:DischargeActiveItem(slot)
            player:AnimateCollectible(collectible, "HideItem", "PlayerPickup")
        end

        data.carlPrevAim = curAim
        data.carlPrevFire = curFire
    end
    mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.CarlActivePlayerUpdate)

    -----------------------------------------
    -- 방 이동, 피격 시 Ready 상태 해제
    -----------------------------------------
    function mod:CarlOnNewRoom()
        for i = 0, Game():GetNumPlayers() - 1 do
            local player = Isaac.GetPlayer(i)
            TryCancelCarlBoomerang(player)
        end
    end
    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.CarlOnNewRoom)

    function mod:CarlOnTakeDamage(player, _, _, _, _)
        TryCancelCarlBoomerang(player)
    end
    mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.CarlOnTakeDamage)

    -----------------------------------------
    -- 부메랑 발사 함수 (관통 여부 체크!)
    -----------------------------------------
    function mod:SpawnCarlBoomerang(player, aimVec)
        local dir = aimVec
        if dir:Length() < 1e-3 then dir = Vector(1, 0) else dir = dir:Normalized() end

        local boomerang = Isaac.Spawn(EntityType.ENTITY_EFFECT, CARL_BOOMERANG_VARIANT, 0,
            player.Position + dir * 15, dir * 15, player)
        local data = boomerang:GetData()
        data.IsCarlsBoomerang = true
        data.Angle = dir:GetAngleDegrees()
        data.StartPos = player.Position
        data.Returning = false
        data.Owner = player
        data.Damage = 10 + player.Damage
        data.Timer = 0
        data.HitEnemies = {}
        data.AnimInit = false

        local ptype = player:GetPlayerType()
        -- 관통 아이템 보유 체크 (원하는 것만 추가)
       data.CanPierceTerrain =
            player:HasCollectible(CollectibleType.COLLECTIBLE_DEAD_DOVE)         -- Dead Dove (Flight + Spectral)
            or player:HasCollectible(CollectibleType.COLLECTIBLE_DEAD_ONION)     -- Dead Onion (Piercing + Spectral)
            or player:HasCollectible(CollectibleType.COLLECTIBLE_OUIJA_BOARD)    -- Ouija Board (Spectral)
            or player:HasCollectible(CollectibleType.COLLECTIBLE_SPIRIT_OF_THE_NIGHT) -- Spirit of the Night (Spectral + Flight)
            or player:HasCollectible(CollectibleType.COLLECTIBLE_TINY_PLANET)    -- Tiny Planet (Spectral)
            or player:HasCollectible(CollectibleType.COLLECTIBLE_CONTINUUM)      -- Continuum (Spectral + wall travel)
            or player:HasCollectible(CollectibleType.COLLECTIBLE_PUPULA_DUPLEX)  -- Pupula Duplex (Spectral + wide)
            or player:HasCollectible(CollectibleType.COLLECTIBLE_THE_WIZ)        -- The Wiz (Spectral)
            or (ptype == 10)                 -- Ghost form lost
            or (ptype == 31)

            -- 위에 원하는 관통 아이템을 추가로 이어붙이면 됨!

        -- 부메랑이 플레이어의 슬롯 정보를 기억(돌아올 때 쿨 완충용)
        data.ChargeSlot = player:GetData().carlActiveSlot or ActiveSlot.SLOT_PRIMARY
    end

    --------------------------------------------------------
    -- 부메랑 이펙트: 이동, 데미지, 리턴, "관통" 장애물 체크!
    --------------------------------------------------------
    function mod:CarlsBoomerangUpdate(effect)
        local data = effect:GetData()
        if not data.IsCarlsBoomerang then return end

        local player = data.Owner
        if not player or not player:Exists() then effect:Remove(); return end

        local SPEED = 13
        local RANGE = 180
        local RETURN_SPEED = 16

        data.Timer = data.Timer + 1

        -- anm2 불러오기 (최초 1회)
        local sprite = effect:GetSprite()
        if not data.AnimInit then
            sprite:Load("gfx/carl_active.anm2", true)
            sprite:Play("Attack", true)
            data.AnimInit = true
        elseif not sprite:IsPlaying("Attack") then
            sprite:Play("Attack", true)
        end


        local OBSTACLE_TYPES = {
            [GridEntityType.GRID_ROCK] = true,
            [GridEntityType.GRID_ROCKB] = true,
            [GridEntityType.GRID_ROCKT] = true,
            [GridEntityType.GRID_ROCK_SS] = true,
            [GridEntityType.GRID_POOP] = true,
            [GridEntityType.GRID_TNT] = true,
            [GridEntityType.GRID_STATUE] = true,
            [GridEntityType.GRID_PILLAR] = true,
            [GridEntityType.GRID_LOCK] = true,
        }
        -- 관통 여부에 따라 장애물 충돌 체크 분기
        if not data.Returning then
            effect.Velocity = Vector.FromAngle(data.Angle) * SPEED
            local room = Game():GetRoom()
            local outOfRoom = room:IsPositionInRoom(effect.Position, 0) == false
            local distanceTooFar = (effect.Position - data.StartPos):Length() >= RANGE
            local timerOver = data.Timer > 30

            -- 장애물 체크: 관통 상태 아닐 때만 돌(rock), 구멍(pit) 등 부딪힘 판정
            local hitObstacle = false
            local hitObstacle = false
            if not data.CanPierceTerrain then
                local grid = room:GetGridEntityFromPos(effect.Position)
                if grid and OBSTACLE_TYPES[grid:GetType()] then
                    hitObstacle = true
                end
            end

            if outOfRoom or distanceTooFar or timerOver or hitObstacle then
                data.Returning = true
            end
        else
            -- 리턴 동작
            local toPlayer = (player.Position - effect.Position):Normalized()
            effect.Velocity = toPlayer * RETURN_SPEED
            if (effect.Position - player.Position):Length() < 15 then
                -- ✅ 부메랑이 돌아오면 쿨 완충!
                local slot = data.ChargeSlot or ActiveSlot.SLOT_PRIMARY
                player:SetActiveCharge(Isaac.GetItemConfig():GetCollectible(id).MaxCharges, slot)
                -- 또는 player:FullCharge(slot)
                effect:Remove()
                return
            end
        end

        -- 적 피격, 상태, 로그 등 기존대로
        for _, ent in ipairs(Isaac.FindInRadius(effect.Position, 24, EntityPartition.ENEMY)) do
            if ent:IsVulnerableEnemy() and not data.HitEnemies[ent.InitSeed] then
                ent:TakeDamage(data.Damage, DamageFlag.DAMAGE_NO_PENALTIES, EntityRef(player), 0)
                data.HitEnemies[ent.InitSeed] = true
            end
        end
    end
    mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.CarlsBoomerangUpdate, CARL_BOOMERANG_VARIANT)

    ---------------------------
    -- EID 툴팁
    ---------------------------
    if EID then
        EID:addCollectible(
            collectible,
            "#사용 시 공격 방향으로 공격력 + 10의 곡괭이를 던집니다."
            .. "#지형관통 아이템이 있을 시, 관통합니다.",
            "Carl's Weapon"
        )
    end
end
