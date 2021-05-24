local addonName, AS = ... -- Get addon name and shared table.
AnachronismStats = AS -- Globalized, so XML can see it

local SPELL_SCHOOL_NAMES = {
    [1] = "Physical",
    [2] = "Holy",
    [3] = "Fire",
    [4] = "Nature",
    [5] = "Frost",
    [6] = "Shadow",
    [7] = "Arcane",
};

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
        GameTooltip:AddDoubleLine(SPELL_SCHOOL_NAMES[i], schoolDamage, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g,
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

local function SpellCritTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText("Spell Crit Chance " .. self.normalSpellCritPercent .. "%", HIGHLIGHT_FONT_COLOR.r,
                        HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddLine(" "); -- Blank line.
    for i = 2, 7 do
        local schoolCrit = GetSpellCritChance(i);
        GameTooltip:AddDoubleLine(SPELL_SCHOOL_NAMES[i], format("%.2F", schoolCrit) .. "%", NORMAL_FONT_COLOR.r,
                                  NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r,
                                  HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
        GameTooltip:AddTexture("Interface\\PaperDollInfoFrame\\SpellSchoolIcon" .. i);
    end

    GameTooltip:Show();
end

local function OnUpArrow_Click()
    AS.StatPanel_UpArrow_OnClick(AS_SpellContainerFrame);
end

local function OnDownArrow_Click()
    AS.StatPanel_DownArrow_OnClick(AS_SpellContainerFrame);
end

function AnachronismStats_SpellPanel_OnLoad(self)
    local containerFrame = AS.ContainerFrame;
    self:SetParent(containerFrame);

    AS_SpellHeaderFrame.UpArrow:SetScript("OnClick", OnUpArrow_Click);
    AS_SpellHeaderFrame.DownArrow:SetScript("OnClick", OnDownArrow_Click);
end

function AS.Frame_SetSpell(playerLevel)
    -- Damage
    local spellDamageFrame = AS_SpellLabelFrame1;
    local highestSpellDamage, highestSchoolIndex = 0, 1;
    for i = 2, 7 do
        local schoolDamage = GetSpellBonusDamage(i);
        if (schoolDamage > highestSpellDamage) then
            highestSpellDamage = schoolDamage;
            highestSchoolIndex = i;
        end
    end
    spellDamageFrame.normalSpellDamage = highestSpellDamage;
    spellDamageFrame.ValueFrame.Value:SetText(highestSpellDamage);
    spellDamageFrame.tooltipSpecialCase = SpellDamageTooltip;

    -- Healing
    local healingFrame = AS_SpellLabelFrame2;
    local bonusHealing = GetSpellBonusHealing();
    healingFrame.ValueFrame.Value:SetText(bonusHealing);
    healingFrame.tooltipRow1 = "Bonus Healing " .. bonusHealing
    healingFrame.tooltipRow2 = "Increase your healing by up to " .. bonusHealing;

    -- Spell Hit
    local spellHitFrame = AS_SpellLabelFrame3;
    local baseSpellHitPercent = GetSpellHitModifier();
    local spellHitRating = GetCombatRating(AS.RatingIds.SpellHit);
    local spellHitFromRating = GetCombatRatingBonus(AS.RatingIds.SpellHit);
    local totalSpellHit = baseSpellHitPercent + spellHitFromRating;
    spellHitFrame.ValueFrame.Value:SetText(totalSpellHit .. "%");
    spellHitFrame.tooltipRow1 = "Spell Hit Chance " .. totalSpellHit .. "%";
    spellHitFrame.tooltipRow2 = "Increases your chance to hit a level " .. playerLevel .. " target with spells by " ..
                                    totalSpellHit .. "%" .. "\nSpell Hit rating: " .. spellHitRating .. " (+" ..
                                    format("%.2F", spellHitFromRating) .. "% to hit)";

    -- Spell Crit
    local spellCritFrame = AS_SpellLabelFrame4;
    local normalSpellCritPercent = format("%.2F", GetSpellCritChance(1));
    spellCritFrame.normalSpellCritPercent = normalSpellCritPercent;
    spellCritFrame.ValueFrame.Value:SetText(normalSpellCritPercent .. "%");
    spellCritFrame.tooltipSpecialCase = SpellCritTooltip;

    -- Mana regen    
    local manaRegenFrame = AS_SpellLabelFrame5;
    local _, classFileName = UnitClass("player");
    if (classFileName == AS.CLASSES.Rogue or classFileName == AS.CLASSES.Warrior) then
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

function AS.GetSpellPanel()
    return AS_SpellContainerFrame;
end
