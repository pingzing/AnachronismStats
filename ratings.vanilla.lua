local addonName, AS = ...; -- Get addon name and shared table.

-- Ratings.vanilla
-- Vanilla-specific helper functions and tbles for dealing with stat and rating calculations and tooltips

AS.MAX_LEVEL = 60;

-- All these tables assume level 60.
local INT_PER_SPELLCRIT = {
    PALADIN = 54, -- This is controversial. Some old posts claim 29.5, but I'm skeptical.
    WARLOCK = 60.6,
    DRUID = 60.0,
    SHAMAN = 59.5,
    MAGE = 59.5,
    PRIEST = 59.2,
};

local AGI_PER_CRIT = {
    WARRIOR = 20,
    ROGUE = 29,
    PALADIN = 20,
    WARLOCK = 20,
    MAGE = 20,
    SHAMAN = 20,
    DRUID = 20,
    PRIEST = 20,
    HUNTER = 53,
};

local AGI_PER_DODGE = {
    WARRIOR = 20,
    ROGUE = 14.5,
    PALADIN = 20,
    WARLOCK = 20,
    MAGE = 20,
    SHAMAN = 20,
    DRUID = 20,
    PRIEST = 20,
    HUNTER = 26.5,
}

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

    hitFrame.tooltipRow1 = "Hit Chance " .. hitChance .. "%";
    hitFrame.tooltipRow2 =
        "Increases your melee chance to hit a target of level " .. playerLevel .. " by " .. hitChance .. "%";
end

local function SetMeleeCritFrame(playerLevel, critChance, critFrame)
    -- TODO: Get crit for per-weapon talents. Lotta classes have those.
    local critText = format("%.2F", critChance) .. "%";
    critFrame.ValueFrame.Value:SetText(critText);
    critFrame.tooltipRow1 = "Critical Hit Chance " .. critText;
    critFrame.tooltipRow2 = "Increases your melee chance to crit a target of level " .. playerLevel .. " by " ..
                                critText;
end

local function SetWeaponSkillFrame(playerLevel, hasOffhand, wepSkillFrame)
    local mainBase, mainMod, offBase, offMod = UnitAttackBothHands("player");
    local wepSkillText;
    local wepSkillTooltipRow1;
    local wepSkillTooltipRow2;

    wepSkillText = AS.GetStatValue(mainBase, mainMod, 0);
    if (hasOffhand) then
        wepSkillText = wepSkillText .. " / " .. AS.GetStatValue(offBase, offMod, 0);
    end

    local wepSkillHeader, _ = AS.GetStatTooltipText("Weapon Skill (Main)", mainBase, mainMod, 0);
    if (hasOffhand) then
        wepSkillHeader = wepSkillHeader .. "\n" .. AS.GetStatTooltipText("Weapon Skill (Off)", offBase, offMod, 0);
    end

    wepSkillTooltipRow1 = wepSkillHeader;
    local maxSkillForLevel = playerLevel * 5;

    -- These might be negative.
    local bonusSkillMain = mainBase - maxSkillForLevel;
    local bonusSkillOff = offBase - maxSkillForLevel;
    local mainPercentBonus = format("%.2F", max(0, bonusSkillMain * .04)) .. "%";
    local offPercentBonus = format("%.2F", max(0, bonusSkillOff * .04)) .. "%";
    wepSkillTooltipRow2 =
        "Increases your chance to hit and crit, and reduce chance to be blocked, dodged or parried by " ..
            mainPercentBonus;
    if (hasOffhand) then
        wepSkillTooltipRow2 = wepSkillTooltipRow2 .. " / " .. offPercentBonus;
    end

    wepSkillTooltipRow2 = wepSkillTooltipRow2 .. " by a level " .. playerLevel .. " enemy";
    wepSkillTooltipRow2 = wepSkillTooltipRow2 ..
                              "\nAlso reduces Glancing Blow damage penalty against higher-level enemies by " ..
                              (max(0, bonusSkillMain * 3)) .. "%";

    if (hasOffhand) then
        wepSkillTooltipRow2 = wepSkillTooltipRow2 .. " / " .. (max(0, bonusSkillOff * 3)) .. "%";
    end

    wepSkillFrame.ValueFrame.Value:SetText(wepSkillText);
    wepSkillFrame.tooltipRow1 = wepSkillTooltipRow1;
    wepSkillFrame.tooltipRow2 = wepSkillTooltipRow2;
end

local function SetExpertiseFrame(mainhandExpertise, offhandExpertise, hasOffhandWeapon, expertiseFrame)
    -- TODO: Show ranged Expertise?
    local expertiseText;
    local expertiseTooltipRow1;
    local expertiseTooltipRow2;

    expertiseText = AS.GetStatValue(mainhandExpertise, 0, 0);
    if (hasOffhandWeapon) then
        expertiseText = expertiseText .. " / " .. AS.GetStatValue(offhandExpertise, 0, 0);
    end

    local expertiseHeader, _ = AS.GetStatTooltipText("Expertise (Main Hand)", mainhandExpertise, 0, 0);
    if (hasOffhandWeapon) then
        expertiseHeader = expertiseHeader .. "\n" ..
        AS.GetStatTooltipText("Expertise (Offhand)", offhandExpertise, 0, 0);
    end
    expertiseTooltipRow1 = expertiseHeader;

    local mainPercent = format("%.2F", mainhandExpertise * .25) .. "%";
    local offPercent = format("%.2F", offhandExpertise * .25) .. "%";
    expertiseTooltipRow2 = "Reduces the chance that your melee attacks will be dodged or parried by " .. mainPercent;
    if (hasOffhandWeapon) then
        expertiseTooltipRow2 = expertiseTooltipRow2 .. " / " .. offPercent;
    end

    expertiseFrame.ValueFrame.Value:SetText(expertiseText);
    expertiseFrame.tooltipRow1 = expertiseTooltipRow1;
    expertiseFrame.tooltipRow2 = expertiseTooltipRow2;
end

local function SetMeleeArmorPenetrationFrame(armorPen, armorPenFrame)
    armorPenFrame.ValueFrame.Value:SetText(armorPen);
    armorPenFrame.tooltipRow1 = "Armor Penetration " .. armorPen;
    armorPenFrame.tooltipRow2 = "Makes your attacks ignore " .. armorPen .. " of an enemy's armor";
end

local function SetSpellDamageFrame()
end

AS.Ratings = {
    IntPerSpellCrit = INT_PER_SPELLCRIT,
    AgiPerCrit = AGI_PER_CRIT,
    AgiPerDodge = AGI_PER_DODGE,
    IDs = nil,
    GetPercentRegenWhileCasting = GetPercentRegenWhileCasting,

    SetMeleeHitFrame = SetMeleeHitFrame,
    SetMeleeCritFrame = SetMeleeCritFrame,
    SetWeaponSkillFrame = SetWeaponSkillFrame,
    SetExpertiseFrame = SetExpertiseFrame,
    SetMeleeArmorPenetrationFrame = SetMeleeArmorPenetrationFrame,

    SetSpellDamageFrame = SetSpellDamageFrame,
}
