
function getIsaacTearMultiplier(player)
    local mult = 1

    -- Debuff zone (계산 순서 위키 기준)
    if player:HasCollectible(CollectibleType.COLLECTIBLE_SOY_MILK) then
        mult = mult * 0.2
    elseif player:HasCollectible(CollectibleType.COLLECTIBLE_ALMOND_MILK) then
        mult = mult * 0.3
    elseif player:HasCollectible(CollectibleType.COLLECTIBLE_20_20)
      and not (player:HasCollectible(CollectibleType.COLLECTIBLE_INNER_EYE)
            or player:HasCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER)
            or player:HasCollectible(CollectibleType.COLLECTIBLE_C_SECTION)
            or player:HasCollectible(CollectibleType.COLLECTIBLE_POLYPHEMUS)) then
        mult = mult * 0.8
    end

    -- Brimstone + Technology = x1.5 (위키 표에 있음)
    if player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE)
    and player:HasCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY) then
        mult = mult * 1.5
    end

    -- Haemolacria x1.5
    if player:HasCollectible(CollectibleType.COLLECTIBLE_HAEMOLACRIA) then
        mult = mult * 1.5
    end

    -- Eve's Mascara x2
    if player:HasCollectible(CollectibleType.COLLECTIBLE_EVES_MASCARA) then
        mult = mult * 2
    end

    -- Polyphemus x2 (멀티샷 아이템 없을 때만)
    if player:HasCollectible(CollectibleType.COLLECTIBLE_POLYPHEMUS)
    and not (player:HasCollectible(CollectibleType.COLLECTIBLE_20_20)
          or player:HasCollectible(CollectibleType.COLLECTIBLE_INNER_EYE)
          or player:HasCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER)
          or player:HasCollectible(CollectibleType.COLLECTIBLE_C_SECTION)) then
        mult = mult * 2
    end

    -- Magic Mushroom, Cricket's Head, Blood of the Martyr(+Book of Belial) x1.5
    if player:HasCollectible(CollectibleType.COLLECTIBLE_MAGIC_MUSHROOM)
      or player:HasCollectible(CollectibleType.COLLECTIBLE_CRICKETS_HEAD)
      or (player:HasCollectible(CollectibleType.COLLECTIBLE_BLOOD_OF_THE_MARTYR)
        and player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL)) then
        mult = mult * 1.5
    end

    -- Immaculate Heart x1.2
    if player:HasCollectible(CollectibleType.COLLECTIBLE_IMMACULATE_HEART) then
        mult = mult * 1.2
    end

    -- Sacred Heart x2.3 (위키)
    if player:HasCollectible(CollectibleType.COLLECTIBLE_SACRED_HEART) then
        mult = mult * 2.3
    end

    -- Crown of Light x2 (실제 효과)
    if player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT) then
        mult = mult * 2
    end

    -- Mega Mush x4 (임시, 효과 중일 때만)
    if player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_MEGA_MUSH) then
        mult = mult * 4
    end

    -- 2개 이상의 Brimstone x1.2 (실제 Brimstone 2개 보유시)
    if player:GetCollectibleNum(CollectibleType.COLLECTIBLE_BRIMSTONE) >= 2 then
        mult = mult * 1.2
    end

    -- Odd Mushroom (Thin) x0.9
    if player:HasCollectible(CollectibleType.COLLECTIBLE_ODD_MUSHROOM_RATE) then
        mult = mult * 0.9
    end

    -- Ludovico Technique + Azazel x0.5
    if (player:GetPlayerType() == PlayerType.PLAYER_AZAZEL or player:GetPlayerType() == PlayerType.PLAYER_AZAZEL_B)
    and player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) then
        mult = mult * 0.5
    end

    -- Succubus 오라 안에 있을 때 (실시간 확인 필요, x1.5)

    if isPlayerInSuccubusAura(player) then
        mult = mult * 1.5
    end
    -- => 이런 오라/특수 이펙트류는 보통 별도 체크 필요

    -- 캐릭터 배수 (위키 기준)
    local ptype = player:GetPlayerType()
    if ptype == PlayerType.PLAYER_BLACKJUDAS then
        mult = mult * 2
    elseif ptype == PlayerType.PLAYER_THELOST_B then
        mult = mult * 1.3
    elseif ptype == PlayerType.PLAYER_AZAZEL
      or ptype == PlayerType.PLAYER_AZAZEL_B
      or ptype == PlayerType.PLAYER_THEFORGOTTEN
      or ptype == PlayerType.PLAYER_THEFORGOTTEN_B
      or ptype == PlayerType.PLAYER_LAZARUS2_B then
        mult = mult * 1.5
    elseif ptype == PlayerType.PLAYER_LAZARUS2 then
        mult = mult * 1.4
    elseif ptype == PlayerType.PLAYER_JUDAS then
        mult = mult * 1.35
    elseif ptype == PlayerType.PLAYER_CAIN
      or ptype == PlayerType.PLAYER_CAIN_B
      or ptype == PlayerType.PLAYER_KEEPER
      or ptype == PlayerType.PLAYER_EVE_B then
        mult = mult * 1.2
    elseif ptype == PlayerType.PLAYER_BLUEBABY then
        mult = mult * 1.05
    elseif ptype == PlayerType.PLAYER_BETHANY_B
      or (ptype == PlayerType.PLAYER_BLACKJUDAS and not player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_WHORE_OF_BABYLON)) then
        mult = mult * 0.75
    end

    return mult
end

return getIsaacTearMultiplier