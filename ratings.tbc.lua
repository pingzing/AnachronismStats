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

    expertiseText = AS.GetFormattedStatValue(mainhandExpertise, 0, 0);
    if (hasOffhandWeapon) then
        expertiseText = expertiseText .. " / " .. AS.GetFormattedStatValue(offhandExpertise, 0, 0);
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

-- Pet scaling:
HUNTER_PET_BONUS = {};
HUNTER_PET_BONUS["PET_BONUS_RAP_TO_AP"] = 0.22;
HUNTER_PET_BONUS["PET_BONUS_RAP_TO_SPELLDMG"] = 0.1287;
HUNTER_PET_BONUS["PET_BONUS_STAM"] = 0.3;
HUNTER_PET_BONUS["PET_BONUS_RES"] = 0.4;
HUNTER_PET_BONUS["PET_BONUS_ARMOR"] = 0.35;
HUNTER_PET_BONUS["PET_BONUS_SPELLDMG_TO_SPELLDMG"] = 0.0;
HUNTER_PET_BONUS["PET_BONUS_SPELLDMG_TO_AP"] = 0.0;
HUNTER_PET_BONUS["PET_BONUS_INT"] = 0.0;

WARLOCK_PET_BONUS = {};
WARLOCK_PET_BONUS["PET_BONUS_RAP_TO_AP"] = 0.0;
WARLOCK_PET_BONUS["PET_BONUS_RAP_TO_SPELLDMG"] = 0.0;
WARLOCK_PET_BONUS["PET_BONUS_STAM"] = 0.3;
WARLOCK_PET_BONUS["PET_BONUS_RES"] = 0.4;
WARLOCK_PET_BONUS["PET_BONUS_ARMOR"] = 0.35;
WARLOCK_PET_BONUS["PET_BONUS_SPELLDMG_TO_SPELLDMG"] = 0.15;
WARLOCK_PET_BONUS["PET_BONUS_SPELLDMG_TO_AP"] = 0.57;
WARLOCK_PET_BONUS["PET_BONUS_INT"] = 0.3;

local function CalculatePetBonus(stat, value, class)
    if (class == AS.CLASSES.Warlock) then
        if (WARLOCK_PET_BONUS[stat]) then
            return value * WARLOCK_PET_BONUS[stat];
        end
    elseif (class == AS.CLASSES.Hunter) then
        if (HUNTER_PET_BONUS[stat]) then
            return value * HUNTER_PET_BONUS[stat];
        end
    end

    return 0
end

local function SpellDamageTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText("Bonus Damage " .. self.normalSpellDamage, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g,
                        HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddLine(" "); -- Blank line.
    for i = 2, 7 do
        local schoolDamage = GetSpellBonusDamage(i);
        GameTooltip:AddDoubleLine(AS.SPELL_SCHOOL_NAMES[i], schoolDamage, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g,
                                  NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g,
                                  HIGHLIGHT_FONT_COLOR.b);
        GameTooltip:AddTexture("Interface\\PaperDollInfoFrame\\SpellSchoolIcon" .. i);
    end

    -- Warlock-specific stuff
    local _, classFileName = UnitClass("player");
    if (classFileName == AS.CLASSES.Warlock) then
        local fireDamage = GetSpellBonusDamage(3);
        local shadowDamage = GetSpellBonusDamage(6);
        local petString, highestDamageValue;
        if shadowDamage > fireDamage then
            petString = PET_BONUS_TOOLTIP_WARLOCK_SPELLDMG_SHADOW; -- Magic global format string
            highestDamageValue = shadowDamage;
        else
            petString = PET_BONUS_TOOLTIP_WARLOCK_SPELLDMG_FIRE -- Other magic global format string
            highestDamageValue = fireDamage;
        end

        local petBonusAP = CalculatePetBonus("PET_BONUS_SPELLDMG_TO_AP", highestDamageValue, AS.CLASSES.Warlock);
        local petBonusSpellDamage = CalculatePetBonus("PET_BONUS_SPELLDMG_TO_SPELLDMG", highestDamageValue,
                                                      AS.CLASSES.Warlock);
        if (petBonusAP > 0 or petBonusSpellDamage > 0) then
            GameTooltip:AddLine("\n" .. format(petString, petBonusAP, petBonusSpellDamage), nil, nil, nil, 1);
        end
    end

    GameTooltip:Show();
end

local function SetSpellDamageFrame(highestSpellDamage, spellDamageFrame)
    spellDamageFrame.normalSpellDamage = highestSpellDamage;
    spellDamageFrame.ValueFrame.Value:SetText(highestSpellDamage);
    spellDamageFrame.tooltipSpecialCase = SpellDamageTooltip;
end

local function SetSpellHealingFrame(bonusHealing, healingFrame)
    healingFrame.ValueFrame.Value:SetText(bonusHealing);
    healingFrame.tooltipRow1 = "Bonus Healing " .. bonusHealing
    healingFrame.tooltipRow2 = "Increase your healing by up to " .. bonusHealing;
end

local function SetSpellHasteFrame(spellHastePercent, spellHasteFrame)
    local spellHasteRating = GetCombatRating(AS.Ratings.IDs.SpellHaste);
    spellHasteFrame.ValueFrame.Value:SetText(spellHastePercent .. "%");
    spellHasteFrame.tooltipRow1 = "Spell Haste " .. format("%.2F", spellHastePercent) .. "%";
    spellHasteFrame.tooltipRow2 = "Increases the speed that you cast your spells by " ..
                                      format("%.2F", spellHastePercent) .. "%" .. "\nSpell haste rating: " ..
                                      spellHasteRating .. " (+" .. format("%.2F", spellHastePercent) .. "%)";
end

local function SetSpellHitFrame(baseSpellHitPercent, playerLevel, spellHitFrame)
    local spellHitRating = GetCombatRating(AS.Ratings.IDs.SpellHit);
    local spellHitFromRating = GetCombatRatingBonus(AS.Ratings.IDs.SpellHit);
    local totalSpellHit = baseSpellHitPercent + spellHitFromRating;
    spellHitFrame.ValueFrame.Value:SetText(totalSpellHit .. "%");
    spellHitFrame.tooltipRow1 = "Spell Hit Chance " .. totalSpellHit .. "%";
    spellHitFrame.tooltipRow2 = "Increases your chance to hit a level " .. playerLevel .. " target with spells by " ..
                                    totalSpellHit .. "%" .. "\nSpell Hit rating: " .. spellHitRating .. " (+" ..
                                    format("%.2F", spellHitFromRating) .. "% to hit)";
end

local function SpellCritTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText("Spell Crit Chance " .. self.normalSpellCritPercent .. "%", HIGHLIGHT_FONT_COLOR.r,
                        HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddLine(" "); -- Blank line.
    for i = 2, 7 do
        local schoolCrit = GetSpellCritChance(i);
        GameTooltip:AddDoubleLine(AS.Ratings.SPELL_SCHOOL_NAMES[i], format("%.2F", schoolCrit) .. "%", NORMAL_FONT_COLOR.r,
                                  NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r,
                                  HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
        GameTooltip:AddTexture("Interface\\PaperDollInfoFrame\\SpellSchoolIcon" .. i);
    end

    GameTooltip:Show();
end

local function SetSpellCritFrame(normalSpellCritPercent, spellCritFrame)
    spellCritFrame.ValueFrame.Value:SetText(normalSpellCritPercent .. "%");
    spellCritFrame.tooltipSpecialCase = SpellCritTooltip;
end

local function SetManaRegenFrame(className, manaRegenFrame)
    if (className == AS.CLASSES.Rogue or className == AS.CLASSES.Warrior) then
        manaRegenFrame.ValueFrame.Value:SetText("--");
        manaRegenFrame.tooltipRow1 = "Mana Regeneration 0";
        manaRegenFrame.tooltipRow2 = "You have no mana. Why are you here?";
    else
        local notCasting, casting = GetManaRegen("player"); -- Returns MP1, not MP5
        local notCastingP5 = format("%.0F", notCasting * 5.0);
        local castingP5 = format("%.0F", casting * 5.0);
        local mp5Text = notCastingP5 .. " / " .. castingP5;
        manaRegenFrame.ValueFrame.Value:SetText(mp5Text);
        manaRegenFrame.tooltipRow1 = "Mana Regeneration " .. mp5Text;
        manaRegenFrame.tooltipRow2 = notCastingP5 .. " MP/5 while not casting" .. "\n" .. castingP5 ..
                                         " MP/5 while casting";

    end
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
    SetSpellHealingFrame = SetSpellHealingFrame,
    SetSpellHasteFrame = SetSpellHasteFrame,
    SetSpellHitFrame = SetSpellHitFrame,
    SetSpellCritFrame = SetSpellCritFrame,
    SetManaRegenFrame = SetManaRegenFrame,
};
