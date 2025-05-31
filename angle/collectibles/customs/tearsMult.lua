function getIsaacTearsMultiplier(player)
    local mult = 1
    local effects = player:GetEffects()
    local ptype = player:GetPlayerType()

    -- 무기 타입
    if player:HasWeaponType(WeaponType.WEAPON_BOMBS) then
        if player:HasWeaponType(WeaponType.WEAPON_MONSTROS_LUNGS) then
            mult = mult / 4.3
        else
            mult = mult * 0.4
        end
    elseif ptype == PlayerType.PLAYER_AZAZEL or ptype == PlayerType.PLAYER_AZAZEL_B
        and not player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) then
        mult = mult * 0.267
    elseif player:HasWeaponType(WeaponType.WEAPON_BRIMSTONE) then
        mult = mult / 3
    elseif player:HasWeaponType(WeaponType.WEAPON_MONSTROS_LUNGS) then
        mult = mult / 4.3
    end

    -- Technology 2
    if player:HasCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY_2) then
        mult = (mult * 2) / 3
    end

    -- Eve's Mascara
    if player:HasCollectible(CollectibleType.COLLECTIBLE_EVES_MASCARA) then
        mult = (mult * 2) / 3
    end

    -- Ipecac
    if player:HasCollectible(CollectibleType.COLLECTIBLE_IPECAC) then
        mult = mult / 3
    end

    -- 20/20, Inner Eye, Mutant Spider, Polyphemus
    if player:HasCollectible(CollectibleType.COLLECTIBLE_20_20) then
        -- 변화 없음
    elseif player:HasCollectible(CollectibleType.COLLECTIBLE_INNER_EYE) or effects:HasCollectibleEffect(NullItemID.ID_REVERSE_HANGED_MAN) then
        mult = mult * 0.51
    elseif player:HasCollectible(CollectibleType.COLLECTIBLE_POLYPHEMUS) or player:HasCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER) then
        mult = mult * 0.42
    end

    -- Almond Milk, Soy Milk
    if player:HasCollectible(CollectibleType.COLLECTIBLE_ALMOND_MILK) then
        mult = mult * 4
    elseif player:HasCollectible(CollectibleType.COLLECTIBLE_SOY_MILK) then
        mult = mult * 5.5
    end

    -- Chariot 카드 효과 (리버스 포함)
    if effects:HasCollectibleEffect(NullItemID.ID_REVERSE_CHARIOT) or effects:HasCollectibleEffect(NullItemID.ID_REVERSE_CHARIOT_ALT) then
        mult = mult * 4
    end

    return mult
end

return getIsaacTearsMultiplier
