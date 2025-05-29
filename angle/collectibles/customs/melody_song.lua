return function(mod, id)
    local radius = 80 -- 반지름
    local subScale = 1 -- 공배수
    local ORBIT_SPEED = 6 -- 속도
    local ORBIT_DURATION = 180 -- 공전 시간
    local MAX_ORBIT_TEARS = 3 -- 최대 음표
    local REFRESH_INTERVAL = 30 --때리는 간격

    local orbitTears = {}

    local function GetOrbitPos(player, orbitIdx, nowFrame)
        local baseAngle = 360 * (orbitIdx - 1) / MAX_ORBIT_TEARS
        local angle = (baseAngle + ORBIT_SPEED * nowFrame) % 360
        local rad = math.rad(angle)
        return player.Position + Vector(math.cos(rad), math.sin(rad)) * radius
    end

    local function SpawnOrbitTear(player, damage, orbitIdx, nowFrame, baseSpawnFrame, refreshCount)
        local orbitPos = GetOrbitPos(player, orbitIdx, nowFrame)
        local subTear = Isaac.Spawn(
            EntityType.ENTITY_TEAR,
            TearVariant.BLUE,
            0,
            orbitPos,
            Vector(0, 0),
            player
        ):ToTear()
        local sprite = subTear:GetSprite()
        sprite:Load("gfx/melody_song.anm2", true)
        sprite:Play("Idle", true)
        subTear.Scale = subScale
        subTear.CollisionDamage = (damage or 3.5) * 2
        subTear.FallingSpeed = 0
        subTear.FallingAcceleration = 0
        subTear.TearFlags = TearFlags.TEAR_PIERCING | TearFlags.TEAR_SPECTRAL
        subTear:GetData().melodyTear = {
            IsSub = true,
            SpawnFrame = nowFrame,
            BaseSpawnFrame = baseSpawnFrame or nowFrame,
            RefreshCount = refreshCount or 0,
            OrbitIdx = orbitIdx
        }
        orbitTears[orbitIdx] = subTear
        return subTear
    end

    function mod:OnTearDamage(entity, amount, flags, source, countdown)
        if source and source.Entity and source.Entity.Type == EntityType.ENTITY_TEAR then
            local tear = source.Entity:ToTear()
            if tear then
                local tearData = tear:GetData()
                if not (tearData.melodyTear and tearData.melodyTear.IsSub) then
                    local player = tear.SpawnerEntity
                    if player and player:ToPlayer() and player:ToPlayer():HasCollectible(id) then
                        local nowFrame = Game():GetFrameCount()
                        local damage = player.Damage or 3.5

                        for i = 1, MAX_ORBIT_TEARS do
                            local t = orbitTears[i]
                            if not (t and t:Exists()) then
                                SpawnOrbitTear(player, damage, i, nowFrame)
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.OnTearDamage)

    function mod:OnTearUpdate(tear)
        local data = tear:GetData()
        if data.melodyTear and data.melodyTear.IsSub then
            local player = Isaac.GetPlayer(0)
            local nowFrame = Game():GetFrameCount()
            local orbitIdx = data.melodyTear.OrbitIdx or 1

            if orbitIdx < 1 or orbitIdx > MAX_ORBIT_TEARS then orbitIdx = 1 end

            if orbitTears[orbitIdx] ~= tear then
                orbitTears[orbitIdx] = tear
            end

            -- 위치 계산
            local orbitPos = GetOrbitPos(player, orbitIdx, nowFrame)
            tear.Position = orbitPos
            tear.Velocity = Vector(0, 0)
            tear.FallingSpeed = 0
            tear.FallingAcceleration = 0

            local baseSpawnFrame = data.melodyTear.BaseSpawnFrame or data.melodyTear.SpawnFrame or nowFrame
            data.melodyTear.BaseSpawnFrame = baseSpawnFrame
            local lived = nowFrame - baseSpawnFrame

            if lived > ORBIT_DURATION then
                orbitTears[orbitIdx] = nil
                tear:Remove()
                return
            end

            if lived > 0 and lived % REFRESH_INTERVAL == 0 then
                local damage = player.Damage or 3.5
                SpawnOrbitTear(
                    player,
                    damage,
                    orbitIdx,
                    nowFrame,
                    baseSpawnFrame,
                    (data.melodyTear.RefreshCount or 0) + 1
                )
                tear:Remove()
                return
            end
        end
    end
    mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, mod.OnTearUpdate)

    function mod:OnNewRoom()
        orbitTears = {}
    end
    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.OnNewRoom)

    if EID then
        EID:addCollectible(
            id,
            "#적을 눈물로 맞추면 캐릭터 공격력 2배의 음표가 공전합니다."..
            "#음표는 6초뒤에 사라집니다.",
            "Melody's Song"
        )
    end
end
