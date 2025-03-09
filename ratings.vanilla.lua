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

    wepSkillText = AS.GetFormattedStatValue(mainBase, mainMod, 0);
    if (hasOffhand) then
        wepSkillText = wepSkillText .. " / " .. AS.GetFormattedStatValue(offBase, offMod, 0);
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

    expertiseText = AS.GetFormattedStatValue(mainhandExpertise, 0, 0);
    if (hasOffhandWeapon) then
        expertiseText = expertiseText .. " / " .. AS.GetFormattedStatValue(offhandExpertise, 0, 0);
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
    spellHasteFrame.ValueFrame.Value:SetText(spellHastePercent .. "%");
    spellHasteFrame.tooltipRow1 = "Spell Haste " .. format("%.2F", spellHastePercent) .. "%";
    spellHasteFrame.tooltipRow2 = "Increases the speed that you cast your spells by " ..
                                      format("%.2F", spellHastePercent) .. "%";
end

local function SetSpellHitFrame(baseSpellHitPercent, playerLevel, spellHitFrame)
    local totalSpellHit = baseSpellHitPercent; -- TODO: Does the GetSpellHitModifier() we use factor in hit from gear?
    spellHitFrame.ValueFrame.Value:SetText(totalSpellHit .. "%");
    spellHitFrame.tooltipRow1 = "Spell Hit Chance " .. totalSpellHit .. "%";
    spellHitFrame.tooltipRow2 = "Increases your chance to hit a level " .. playerLevel .. " target with spells by " ..
                                    totalSpellHit .. "%";
end

local function SpellCritTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText("Spell Crit Chance " .. self.normalSpellCritPercent .. "%", HIGHLIGHT_FONT_COLOR.r,
                        HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddLine(" "); -- Blank line.
    for i = 2, 7 do
        local schoolCrit = GetSpellCritChance(i);
        GameTooltip:AddDoubleLine(AS.SPELL_SCHOOL_NAMES[i], format("%.2F", schoolCrit) .. "%", NORMAL_FONT_COLOR.r,
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

local function SetArmorFrame(base, armorPosBuff, armorNegBuff, playerLevel, armorFrame)
    local armorText = AS.GetFormattedStatValue(base, armorPosBuff, armorNegBuff);
    armorFrame.ValueFrame.Value:SetText(armorText);
    armorFrame.tooltipRow1 = AS.GetStatTooltipText(armorFrame.name, base, armorPosBuff, armorNegBuff);

    local effectiveArmor = base + armorPosBuff + armorNegBuff;
    -- Some serious magic, taken straight form Blizzard's PaperDoll code
    local armorReduction = effectiveArmor / ((85 * playerLevel) + 400);
    armorReduction = 100 * (armorReduction / (armorReduction + 1));
    armorFrame.tooltipRow2 = "Reduces physical damage taken from level " .. playerLevel .. " enemies by " ..
                                 format("%.2F", armorReduction) .. "%";
end

local function SetDefenseFrame(defenseValue, defenseModifier, playerLevel, defenseFrame)
    -- defenseModifier is a single modifier value, which can be positive or negative.
    local defPosBuff, defNegBuff = 0, 0;
    if (defenseModifier > 0) then
        defPosBuff = defenseModifier;
    elseif (defenseModifier < 0) then
        defNegBuff = defenseModifier;
    end
    local defenseText = AS.GetFormattedStatValue(defenseValue, defPosBuff, defNegBuff);
    defenseFrame.ValueFrame.Value:SetText(defenseText);
    defenseFrame.tooltipRow1 = AS.GetStatTooltipText(defenseFrame.name, defenseValue, defPosBuff, defNegBuff);

    local effectiveDefense = defenseValue + defPosBuff + defNegBuff;
    local maxSkillForLevel = playerLevel * 5;
    local bonusSkill = effectiveDefense - maxSkillForLevel;
    local percentBonusText = format("%.2F", max(0, bonusSkill * .04)) .. "%";
    -- Not certain about the daze .16 value.
    -- LuaFormatter off
    defenseFrame.tooltipRow2 = "Against a level " .. playerLevel .. " enemy:" ..
                                "\n -" .. percentBonusText .." to be hit/crit " ..
                                "\n +" .. percentBonusText .. " Block/Dodge/Parry " ..
                                "\n -" .. format("%.2F", max(0, bonusSkill * .16)) .. "% chance to be dazed";
    -- LuaFormatter on
end

local function SetBlockFrame(blockChance, blockValue, playerLevel, blockFrame)
    local blockChanceText = format("%.2F", blockChance) .. "%";
    blockFrame.ValueFrame.Value:SetText(blockChanceText);
    blockFrame.tooltipRow1 = "Block Chance " .. blockChanceText;
    blockFrame.tooltipRow2 =
        "Increases your chance to block by " .. blockChanceText .. " against level " .. playerLevel .. " targets" ..
            "\nBlock value: " .. blockValue;
end

local function SetDodgeFrame(dodgeChance, playerLevel, dodgeFrame)
    local dodgeChanceText = format("%.2F", dodgeChance) .. "%";
    dodgeFrame.ValueFrame.Value:SetText(dodgeChanceText);
    dodgeFrame.tooltipRow1 = "Dodge Chance " .. dodgeChanceText;
    dodgeFrame.tooltipRow2 =
        "Increases your chance to dodge by " .. dodgeChanceText .. " against level " .. playerLevel .. " targets";
end

local function SetParryFrame(parryChance, playerLevel, parryFrame)
    local parryChanceText = format("%.2F", parryChance) .. "%";
    parryFrame.ValueFrame.Value:SetText(parryChanceText);
    parryFrame.tooltipRow1 = "Parry Chance " .. parryChanceText;
    parryFrame.tooltipRow2 =
        "Increases your chance to parry by " .. parryChanceText .. " against level " .. playerLevel .. " targets";
end

local function SetAvoidanceFrame(defenseValue, defenseModifier, dodgeChance, parryChance, blockChance, playerLevel,
                                 avoidanceFrame)
    local currMaxDefense = playerLevel * 5;
    local missedChance = 5.0 + max(0, ((defenseValue + defenseModifier) - currMaxDefense)) * .04; -- 5% missed is baseline for everyone    
    local totalAvoidance = dodgeChance + parryChance + missedChance;
    local totalMitigation = totalAvoidance + blockChance;
    local crushChance = min(15, 102.4 - totalMitigation);
    local avoidanceChanceText = format("%.2F", totalAvoidance) .. "%";
    local mitigationChanceText = format("%.2F", totalMitigation) .. "%";

    avoidanceFrame.ValueFrame.Value:SetText(avoidanceChanceText);
    avoidanceFrame.tooltipRow1 = "Avoidance " .. avoidanceChanceText;
    avoidanceFrame.tooltipRow2 = "Combined chance to dodge, parry, or be missed by an enemy's attack" ..
                                     "\n\nMitigation (includes Block): " .. mitigationChanceText ..
                                     "\n\nChance to be crushed against a level " .. playerLevel + 3 .. " enemy: " ..
                                     format("%.2F", max(0, crushChance)) .. "%";
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
    SetSpellHealingFrame = SetSpellHealingFrame,
    SetSpellHasteFrame = SetSpellHasteFrame,
    SetSpellHitFrame = SetSpellHitFrame,
    SetSpellCritFrame = SetSpellCritFrame,
    SetManaRegenFrame = SetManaRegenFrame,

    SetArmorFrame = SetArmorFrame,
    SetDefenseFrame = SetDefenseFrame,
    SetBlockFrame = SetBlockFrame,
    SetDodgeFrame = SetDodgeFrame,
    SetParryFrame = SetParryFrame,
    SetAvoidanceFrame = SetAvoidanceFrame,
}
