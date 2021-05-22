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

local function SpellSpellDamageTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText("Bonus Damage " .. self.normalSpellDamage, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g,
                        HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddLine(" "); -- Blank line.
    for i = 2, 7 do
        local schoolDamage = GetSpellBonusDamage(i);
        GameTooltip:AddDoubleLine(SPELL_SCHOOL_NAMES[i], schoolDamage, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g,
                                  NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g,
                                  HIGHLIGHT_FONT_COLOR.b);
    end
    GameTooltip:Show();
end

local function SpellSpellCritTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText("Spell Crit Chance " .. self.normalSpellCritPercent .. "%", HIGHLIGHT_FONT_COLOR.r,
                        HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddLine(" "); -- Blank line.
    for i = 2, 7 do
        local schoolCrit = GetSpellCritChance(i);
        GameTooltip:AddDoubleLine(SPELL_SCHOOL_NAMES[i], format("%.2F", schoolCrit) .. "%", NORMAL_FONT_COLOR.r,
                                  NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r,
                                  HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    end
    GameTooltip:Show();
end

function AnachronismStats_SpellPanel_OnLoad(self)
    local containerFrame = AS.ContainerFrame;
    self:SetParent(containerFrame);
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
    spellDamageFrame.tooltipSpecialCase = SpellSpellDamageTooltip;

    -- Healing
    local healingFrame = AS_SpellLabelFrame2;
    local bonusHealing = GetSpellBonusHealing();
    healingFrame.ValueFrame.Value:SetText(bonusHealing);
    healingFrame.tooltipRow1 = "Bonus Healing " .. bonusHealing
    healingFrame.tooltipRow2 = "Increase your healing by up to " .. bonusHealing;

    -- Spell Hit
    local spellHitFrame = AS_SpellLabelFrame3;
    local spellHitPercent = GetSpellHitModifier();
    spellHitFrame.ValueFrame.Value:SetText(spellHitPercent .. "%");
    spellHitFrame.tooltipRow1 = "Spell Hit Chance " .. spellHitPercent .. "%";
    spellHitFrame.tooltipRow2 = "Increases your chance to hit a level " .. playerLevel .. " target with spells by " ..
                                    spellHitPercent .. "%";

    -- Spell Crit
    local spellCritFrame = AS_SpellLabelFrame4;
    local normalSpellCritPercent = format("%.2F", GetSpellCritChance(1));
    spellCritFrame.normalSpellCritPercent = normalSpellCritPercent;
    spellCritFrame.ValueFrame.Value:SetText(normalSpellCritPercent .. "%");
    spellCritFrame.tooltipSpecialCase = SpellSpellCritTooltip;

    -- Mana regen
    -- Note that this is "Regen right this second", as retreived by GetManaRegen("player").
    local manaRegenFrame = AS_SpellLabelFrame5;
    local _, classFileName = UnitClass("player");
    if (classFileName == AS.CLASSES.Rogue or classFileName == AS.CLASSES.Warrior) then
        manaRegenFrame.ValueFrame.Value:SetText("--");
        manaRegenFrame.tooltipRow1 = "Mana Regeneration 0";
        manaRegenFrame.tooltipRow2 = "You have no mana. Why are you here?";
    else
        -- GetManaRegen("player") just returns regen at-the-moment, so we have to calculate all this ourselves.
        -- Also note: GetManaRegen() does not seem to include temporary regen-while-casting buffs, like Soul Siphon from Improved Drain Soul
        -- Possible TODO: Somehow calculate all other sources of MP5. How? Manual list of whitelisted buff IDs?
        -- Would need all possible short-term +Mana Regen, "Allow regen while casting" and +MP5 buffs. Eugh.
        local _, spirit, _, _ = UnitStat("player", 5);
        local mp5FromItems = AS.GetMp5FromEquippedItems();
        local _, mp5RightNow = GetManaRegen("player"); -- Returns Mana Per 1, instead of Mana per 5
        mp5RightNow = mp5RightNow * 5; -- Correct for MP1
        mp5RightNow = mp5RightNow + mp5FromItems; -- Add in item contribution
        local mp5RightNowText = format("%.0F", mp5RightNow);
        local mp5FromSpirit = floor(AS.GetMp5FromSpirit(spirit, classFileName));
        local percentWhileCasting = AS.GetPercentRegenWhileCasting(classFileName);
        manaRegenFrame.ValueFrame.Value:SetText(mp5RightNowText);
        manaRegenFrame.tooltipRow1 = "Mana Regeneration " .. mp5RightNowText;
        manaRegenFrame.tooltipRow2 =
            mp5RightNowText .. " mana regen every 5 seconds at this moment\n" .. mp5FromSpirit ..
                " mana regenerated every 5 seconds while not casting (from Spirit)\n" ..
                (floor(mp5FromSpirit * (percentWhileCasting / 100))) ..
                " mana regenerated every 5 seconds while casting (from Spirit)";
    end
end
