local addonName, AS = ...; -- Get addon name and shared table.

-- Ratings
-- Helper functions for dealing with various stat and rating calculations

AS.MAX_LEVEL = 70;
AS.CLASSES = {
    Warrior = "WARRIOR",
    Rogue = "ROGUE",
    Paladin = "PALADIN",
    Warlock = "WARLOCK",
    Mage = "MAGE",
    Shaman = "SHAMAN",
    Druid = "DRUID",
    Priest = "PRIEST",
    Hunter = "HUNTER",
};

-- Effectively a skill name -> ID conversion table.
local RatingIdToConvertedStat = {
	"WEAPON_SKILL",
	"DEFENSE",
	"DODGE",
	"PARRY",
	"BLOCK",
	"MELEE_HIT",
	"RANGED_HIT",
	"SPELL_HIT",
	"MELEE_CRIT",
	"RANGED_CRIT",
	"SPELL_CRIT",
	"MELEE_HIT_AVOID",
	"RANGED_HIT_AVOID",
	"SPELL_HIT_AVOID",
	"MELEE_CRIT_AVOID",
	"RANGED_CRIT_AVOID",
	"SPELL_CRIT_AVOID",
	"MELEE_HASTE",
	"RANGED_HASTE",
	"SPELL_HASTE",
	"WEAPON_SKILL",
	"WEAPON_SKILL",
	"WEAPON_SKILL",
	"EXPERTISE",
}

local RatingIdToName = {
	[CR_WEAPON_SKILL] = "WEAPON_RATING",
	[CR_DEFENSE_SKILL] = "DEFENSE_RATING",
	[CR_DODGE] = "DODGE_RATING",
	[CR_PARRY] = "PARRY_RATING",
	[CR_BLOCK] = "BLOCK_RATING",
	[CR_HIT_MELEE] = "MELEE_HIT_RATING",
	[CR_HIT_RANGED] = "RANGED_HIT_RATING",
	[CR_HIT_SPELL] = "SPELL_HIT_RATING",
	[CR_CRIT_MELEE] = "MELEE_CRIT_RATING",
	[CR_CRIT_RANGED] = "RANGED_CRIT_RATING",
	[CR_CRIT_SPELL] = "SPELL_CRIT_RATING",
	[CR_HASTE_MELEE] = "MELEE_HASTE_RATING",
	[CR_HASTE_RANGED] = "RANGED_HASTE_RATING",
	[CR_HASTE_SPELL] = "SPELL_HASTE_RATING",
	[CR_EXPERTISE] = "EXPERTISE_RATING",
};

local RatingNameToId = {
	["DEFENSE_RATING"] = CR_DEFENSE_SKILL,
	["DODGE_RATING"] = CR_DODGE,
	["PARRY_RATING"] = CR_PARRY,
	["BLOCK_RATING"] = CR_BLOCK,
	["MELEE_HIT_RATING"] = CR_HIT_MELEE,
	["RANGED_HIT_RATING"] = CR_HIT_RANGED,
	["SPELL_HIT_RATING"] = CR_HIT_SPELL,
	["MELEE_CRIT_RATING"] = CR_CRIT_MELEE,
	["RANGED_CRIT_RATING"] = CR_CRIT_RANGED,
	["SPELL_CRIT_RATING"] = CR_CRIT_SPELL,
	["MELEE_HASTE_RATING"] = CR_HASTE_MELEE,
	["RANGED_HASTE_RATING"] = CR_HASTE_RANGED,
	["SPELL_HASTE_RATING"] = CR_HASTE_SPELL,
	["DAGGER_WEAPON_RATING"] = CR_WEAPON_SKILL,
	["SWORD_WEAPON_RATING"] = CR_WEAPON_SKILL,
	["2H_SWORD_WEAPON_RATING"] = CR_WEAPON_SKILL,
	["AXE_WEAPON_RATING"] = CR_WEAPON_SKILL,
	["2H_AXE_WEAPON_RATING"] = CR_WEAPON_SKILL,
	["MACE_WEAPON_RATING"] = CR_WEAPON_SKILL,
	["2H_MACE_WEAPON_RATING"] = CR_WEAPON_SKILL,
	["GUN_WEAPON_RATING"] = CR_WEAPON_SKILL,
	["CROSSBOW_WEAPON_RATING"] = CR_WEAPON_SKILL,
	["BOW_WEAPON_RATING"] = CR_WEAPON_SKILL,
	["FERAL_WEAPON_RATING"] = CR_WEAPON_SKILL,
	["FIST_WEAPON_RATING"] = CR_WEAPON_SKILL,
	["WEAPON_RATING"] = CR_WEAPON_SKILL,
	["EXPERTISE_RATING"] = CR_EXPERTISE,
};

AS.RatingIds = {
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

-- Formula reverse engineered by Whitetooth@Cenarius(US) (hotdogee [at] gmail [dot] com)
--  Parry Rating, Defense Rating, and Block Rating: Low-level players 
--   will now convert these ratings into their corresponding defensive 
--   stats at the same rate as level 34 players.
function AS.GetEffectFromRating(id, rating, level)
	-- if id is stringID then convert to numberID
	if type(id) == "string" and RatingNameToId[id] then
		id = RatingNameToId[id]
	end
	-- check for invalid input
	if type(rating) ~= "number" or id < 1 or id > 24 then return 0 end
	-- defaults to player level if not given
	level = level or UnitLevel("player")
	--2.4.3  Parry Rating, Defense Rating, and Block Rating: Low-level players 
	--   will now convert these ratings into their corresponding defensive 
	--   stats at the same rate as level 34 players.
	if (id == CR_DEFENSE_SKILL or id == CR_PARRY or id == CR_BLOCK) and level < 34 then
		level = 34
	end
	if level >= 60 then
		return rating/RatingBase[id]*((-3/82)*level+(131/41)), RatingIdToConvertedStat[id]
	elseif level >= 10 then
		return rating/RatingBase[id]/((1/52)*level-(8/52)), RatingIdToConvertedStat[id]
	else
		return rating/RatingBase[id]/((1/52)*10-(8/52)), RatingIdToConvertedStat[id]
	end
end

-- TODO: Update for BC
function AS.GetMp5FromSpirit(spirit, class)
    -- Priests and mages: 13 + (spirit / 4) mana per tick
    if (class == AS.CLASSES.Priest or class == AS.CLASSES.Mage) then
        return (13 + (spirit / 4)) * 2.5; -- Multiplied by 2.5 as these values are per tick, and ticks are 2s each.
        -- Druids, shamans, paladins, hunters: 15 + (spirit / 5) mana per tick
    elseif (class == AS.CLASSES.Druid or class == AS.CLASSES.Shaman or class == AS.CLASSES.Paladin or class ==
        AS.CLASSES.Hunter) then
        return (15 + (spirit / 5)) * 2.5;
        -- Warlocks: 12 + (spirit / 4) mana per tick (Historical data claims 8 + spir..., but actual testing seems to imply 12? maybe it changes at level 60)
    elseif (class == AS.CLASSES.Warlock) then
        return (12 + (spirit / 4)) * 2.5;
    else
        return 0;
    end
end

-- TODO: Update for BC
function AS.GetPercentRegenWhileCasting(class)
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