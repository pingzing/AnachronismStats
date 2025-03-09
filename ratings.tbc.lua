local addonName, AS = ...; -- Get addon name and shared table.

-- Ratings.tbc
-- TBC-specific helper functions for dealing with various stat and rating calculations and tooltips

AS.MAX_LEVEL = 70;

local INT_PER_SPELLCRIT = { PALADIN = 79.4, WARLOCK = 81.9, DRUID = 79.4, SHAMAN = 78.1, MAGE = 81, PRIEST = 80 };

local AGI_PER_CRIT = {
    WARRIOR = 33,
    ROGUE = 40,
    PALADIN = 25,
    WARLOCK = 25,
    MAGE = 25,
    SHAMAN = 25,
    DRUID = 25,
    PRIEST = 25,
    HUNTER = 40,
};

local AGI_PER_DODGE = {
    WARRIOR = 30,
    ROGUE = 20,
    PALADIN = 25,
    WARLOCK = 25,
    MAGE = 25,
    SHAMAN = 25,
    DRUID = 25,
    PRIEST = 25,
    HUNTER = 25,
}

local ratingIDs = {
    WeaponSkill = CR_WEAPON_SKILL,
    Defense = CR_DEFENSE_SKILL,
    Dodge = CR_DODGE,
    Parry = CR_PARRY,
    Block = CR_BLOCK,
    MeleeHit = CR_HIT_MELEE,
    RangedHit = CR_HIT_RANGED,
    SpellHit = CR_HIT_SPELL,
    MeleeCrit = CR_CRIT_MELEE,
    RangedCrit = CR_CRIT_RANGED,
    SpellCrit = CR_CRIT_SPELL,
    MeleeHaste = CR_HASTE_MELEE,
    RangedHaste = CR_HASTE_RANGED,
    SpellHaste = CR_HASTE_SPELL,
    Expertise = CR_EXPERTISE,
};

-- TODO: Update for BC
local function GetPercentRegenWhileCasting(class)
    -- We need to check three possible talents:
    -- Meditation (Priest), Arcane Meditation (Mage), Reflection (Druid).
    -- TODO: Should also check mage for Mage Armor
    -- There are a handful of talented/trinket/set bonus/etc short-term buffs we could check too, but ehhhhhh
    if (class == AS.CLASSES.Priest) then
        -- check for ranks of Meditation
        local _, _, _, _, ranks, _, _, _ = GetTalentInfo(1, 8);
        return ranks * 5;
    elseif (class == AS.CLASSES.Mage) then
        -- check for ranks of Arcane Meditation
        local _, _, _, _, ranks, _, _, _ = GetTalentInfo(1, 12);
        return ranks * 5;
    elseif (class == AS.CLASSES.Druid) then
        -- check for ranks of Reflection
        local _, _, _, _, ranks, _, _, _ = GetTalentInfo(3, 6);
        return ranks * 5;
    end

    return 0;
end

local function SetMeleeHitFrame(playerLevel, hitChance, hitFrame)
    hitFrame.ValueFrame.Value:SetText(hitChance .. "%");

    local hitRating = GetCombatRating(AS.Ratings.IDs.MeleeHit);
    local hitFromRating = GetCombatRatingBonus(AS.Ratings.IDs.MeleeHit);
    hitFrame.tooltipRow1 = "Hit Chance " .. hitChance .. "%";
    hitFrame.tooltipRow2 =
        "Increases your melee chance to hit a target of level " .. playerLevel .. " by " .. hitChance .. "%" ..
            "\nHit rating: " .. hitRating .. " (+" .. format("%.2F", hitFromRating) .. "% to hit)";
end

local function SetMeleeCritFrame(playerLevel, critChance, critFrame)
    local critRating = GetCombatRating(AS.Ratings.IDs.MeleeCrit);
    local critFromRating = GetCombatRatingBonus(AS.Ratings.IDs.MeleeCrit);
    -- TODO: Get crit for per-weapon talents. Lotta classes have those.
    local critText = format("%.2F", critChance) .. "%";
    critFrame.ValueFrame.Value:SetText(critText);
    critFrame.tooltipRow1 = "Critical Hit Chance " .. critText;
    critFrame.tooltipRow2 = "Increases your melee chance to crit a target of level " .. playerLevel .. " by " ..
                                critText .. "\nCrit rating: " .. critRating .. " (+" .. format("%.2F", critFromRating) ..
                                "% to crit)";
end

local function SetExpertiseFrame(mainhandExpertise, offhandExpertise, hasOffhandWeapon, expertiseFrame)
    -- TODO: Show ranged Expertise?
    local expertiseRating = GetCombatRating(AS.Ratings.IDs.Expertise);

    local expertiseText;
    local expertiseTooltipRow1;
    local expertiseTooltipRow2;

    expertiseText = AS.GetStatValue(mainhandExpertise, 0, 0);
    if (hasOffhandWeapon) then
        expertiseText = expertiseText .. " / " .. AS.GetStatValue(offhandExpertise, 0, 0);
    end

    local expertiseHeader, _ = AS.GetStatTooltipText("Expertise (Main Hand)", mainhandExpertise, 0, 0);
    if (hasOffhandWeapon) then
        expertiseHeader = expertiseHeader .. "\n" .. AS.GetStatTooltipText("Expertise (Offhand)", offhandExpertise, 0, 0);
    end
    expertiseTooltipRow1 = expertiseHeader;

    local mainPercent = format("%.2F", mainhandExpertise * .25) .. "%";
    local offPercent = format("%.2F", offhandExpertise * .25) .. "%";
    expertiseTooltipRow2 = "Reduces the chance that your melee attacks will be dodged or parried by " .. mainPercent;
    if (hasOffhandWeapon) then
        expertiseTooltipRow2 = expertiseTooltipRow2 .. " / " .. offPercent;
    end

    local expertiseFromRating = GetCombatRatingBonus(AS.Ratings.IDs.Expertise);
    expertiseTooltipRow2 = expertiseTooltipRow2 .. "\nExpertise rating: " .. expertiseRating .. " (+" ..
                               expertiseFromRating .. " expertise)";

    expertiseFrame.ValueFrame.Value:SetText(expertiseText);
    expertiseFrame.tooltipRow1 = expertiseTooltipRow1;
    expertiseFrame.tooltipRow2 = expertiseTooltipRow2;
end

local function SetMeleeArmorPenetrationFrame(armorPen, armorPenFrame)
    armorPenFrame.ValueFrame.Value:SetText(armorPen);
    armorPenFrame.tooltipRow1 = "Armor Penetration " .. armorPen;
    armorPenFrame.tooltipRow2 = "Makes your attacks ignore " .. armorPen .. " of an enemy's armor";
end

AS.Ratings = {
    IntPerSpellCrit = INT_PER_SPELLCRIT,
    AgiPerCrit = AGI_PER_CRIT,
    AgiPerDodge = AGI_PER_DODGE,
    IDs = ratingIDs,
    GetPercentRegenWhileCasting = GetPercentRegenWhileCasting,

    SetMeleeHitFrame = SetMeleeHitFrame,
    SetMeleeCritFrame = SetMeleeCritFrame,
    SetWeaponSkillFrame = nil,
    SetExpertiseFrame = SetExpertiseFrame,
    SetMeleeArmorPenetrationFrame = SetMeleeArmorPenetrationFrame,

    SetSpellDamageFrame = SetSpellDamageFrame,
};
