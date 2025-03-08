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

local function GetMeleeHitTooltipLine2(playerLevel, hitChance)
    return  "Increases your melee chance to hit a target of level " .. playerLevel .. " by " .. hitChance .. "%";
end

AS.Ratings = {
    IntPerSpellCrit = INT_PER_SPELLCRIT,
    AgiPerCrit = AGI_PER_CRIT,
    AgiPerDodge = AGI_PER_DODGE,
    IDs = nil,
    GetPercentRegenWhileCasting = GetPercentRegenWhileCasting,
    GetMeleeHitTooltipLine2 = GetMeleeHitTooltipLine2,
}