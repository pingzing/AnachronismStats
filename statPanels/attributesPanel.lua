local addonName, AS = ... -- Get addon name and shared table.
AnachronismStats = AS -- Globalized, so XML can see it

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

local function GetStrengthDetailText(base, current, posBuff, negBuff, playerLevel)
    local _, classFileName = UnitClass("player");
    local stanceNum = GetShapeshiftForm();
    local strengthDetailText = "";
    if (classFileName == AS.CLASSES.Warrior or classFileName == AS.CLASSES.Paladin or classFileName == AS.CLASSES.Shaman) then
        -- TODO Figure out if we need to subtract base strength from 'current' here.
        strengthDetailText = "Increases block value by " .. floor(current / 20) .. "\n"; -- I hope this rounds down. Can stats go negative?
    end
    -- Bears get 2 AP per strength, so check for "Druid && Bear" in addition to Warr or Pally.
    if (classFileName == AS.CLASSES.Warrior or classFileName == AS.CLASSES.Paladin or
        (classFileName == AS.CLASSES.Druid and stanceNum == 1)) then
        strengthDetailText = strengthDetailText .. "Increases melee attack power by " .. (current * 2) .. "\n";
        -- Everyone else gets 1 AP per Str.
    else
        strengthDetailText = strengthDetailText .. "Increases melee attack power by " .. current .. "\n";
    end

    return strtrim(strengthDetailText);
end

local function GetAgilityDetailText(base, current, posBuff, negBuff, playerLevel)
    local _, classFileName = UnitClass("player");
    local stanceNum = GetShapeshiftForm();
    local agiDetailText = "";
    -- 1 AP for Rogues, Hunters, and Cat Druids
    if (classFileName == AS.CLASSES.Rogue or classFileName == AS.CLASSES.Hunter or
        (classFileName == AS.CLASSES.Druid and stanceNum == 3)) then
        agiDetailText = "Increases melee attack power by " .. current .. "\n";
    end
    -- 2 RAP per Agi for hunters. 1 RAP per point for Warrs and Rogues.
    if (classFileName == AS.CLASSES.Hunter) then
        agiDetailText = agiDetailText .. "Increases ranged attack power by " .. (current * 2) .. "\n";
    elseif (classFileName == AS.CLASSES.Warrior or classFileName == AS.CLASSES.Rogue) then
        agiDetailText = agiDetailText .. "Increases ranged attack power by " .. current .. "\n";
    end

    -- Crit chance
    -- The operative guess here is that the level coefficient is just (currLevel / maxLevel) * AGI_PER_CRIT (which is the level 60 value)
    -- That's almost certainly wrong, but it seems to be Good Enough(tm).
    -- TODO: Bet I could dig out an old copy of RatingBuster and see what it did (provided formulas didn't change between 1.12 and 2.4.3)
    local agiPerCrit = (playerLevel / AS.MAX_LEVEL) * AGI_PER_CRIT[classFileName];
    agiDetailText = agiDetailText .. "Increases melee and ranged crit chance by ~" ..
                        format("%.2F", (current / agiPerCrit)) .. "%\n";

    -- Ditto dodge chance.
    local agiPerDodge = (playerLevel / AS.MAX_LEVEL) * AGI_PER_DODGE[classFileName];
    agiDetailText = agiDetailText .. "Increases dodge chance by ~" .. format("%.2F", (current / agiPerDodge)) .. "%\n";

    -- 2 Armor per Agi
    agiDetailText = agiDetailText .. "Increases armor by " .. (current * 2);

    return strtrim(agiDetailText);
end

local function GetStaminaDetailText(base, current, posBuff, negBuff, playerLevel)
    local _, race = UnitRace("player");

    -- Value * 10. (Unless Tauren, then value * 10.5)            
    -- The first 20 points of Stamina grant only 1 health point each.
    local normalStam = current - 20;
    local healthFromStam;
    if (race == "Tauren") then
        healthFromStam = normalStam * 10.5 + 20;
    else
        healthFromStam = normalStam * 10 + 20;
    end
    return "Increases health by " .. healthFromStam;
end

local function GetIntellectDetailText(base, current, posBuff, negBuff, playerLevel)
    local _, classFileName = UnitClass("player");
    -- We could be smart and check to see if the unit has mana, but... Druids. Just do the easy thing.
    if (classFileName == AS.CLASSES.Rogue or classFileName == AS.CLASSES.Warrior) then
        return "";
    end

    local intPerCrit = (playerLevel / AS.MAX_LEVEL) * INT_PER_SPELLCRIT[classFileName];
    local intelDetailText = "Increases your maximum mana by " .. floor(current * 15) .. "\n";
    intelDetailText = intelDetailText .. "Increases your spell crit chance by ~" ..
                          format("%.2F", (current / intPerCrit)) .. "%";
    return strtrim(intelDetailText);
end

-- TODO: This seems to return all zeroes ATM
local function GetSpiritDetailText(base, current, posBuff, negBuff, playerLevel)
    local _, classFileName = UnitClass("player");
    if (classFileName == AS.CLASSES.Rogue or classFileName == AS.CLASSES.Warrior) then
        return "";
    end

    -- GetManaRegen("player") just returns regen at-the-moment, so we 
    -- have to calculate all this ourselves.
    local mp5FromSpirit = AS.GetMp5FromSpirit(current, classFileName);
    local percentWhileCasting = AS.GetPercentRegenWhileCasting(classFileName);
    local spiritDetailText = "Increases your mana regeneration by " .. floor(mp5FromSpirit) ..
                                 " per 5 seconds while not casting\n";
    spiritDetailText = spiritDetailText .. "Increases your mana regeneration by " ..
                           (floor(mp5FromSpirit * (percentWhileCasting / 100))) .. " per 5 seconds while casting";
    return spiritDetailText;
end

local function GetAttributeTooltipDetailText(stat, base, current, posBuff, negBuff, playerLevel)
    if (stat == "STRENGTH") then
        return GetStrengthDetailText(base, current, posBuff, negBuff, playerLevel);
    elseif (stat == "AGILITY") then
        return GetAgilityDetailText(base, current, posBuff, negBuff, playerLevel);
    elseif (stat == "STAMINA") then
        return GetStaminaDetailText(base, current, posBuff, negBuff, playerLevel);
    elseif (stat == "INTELLECT") then
        return GetIntellectDetailText(base, current, posBuff, negBuff, playerLevel);
    elseif (stat == "SPIRIT") then
        return GetSpiritDetailText(base, current, posBuff, negBuff, playerLevel);
    end
end

function AnachronismStats_AttributesPanel_OnLoad(self)
    local containerFrame = AS.ContainerFrame;
    self:SetParent(containerFrame);
end

function AS.GetAttributeTooltipText(tooltipText, stat, base, current, posBuff, negBuff, playerLevel)
    local tooltipRow1 = tooltipText;
    if ((posBuff == 0) and (negBuff == 0)) then
        tooltipRow1 = tooltipRow1 .. current .. FONT_COLOR_CODE_CLOSE;
    else
        tooltipRow1 = tooltipRow1 .. current;
        if (posBuff > 0 or negBuff < 0) then
            tooltipRow1 = tooltipRow1 .. " (" .. (current - posBuff - negBuff) .. FONT_COLOR_CODE_CLOSE;
        end
        if (posBuff > 0) then
            tooltipRow1 = tooltipRow1 .. FONT_COLOR_CODE_CLOSE .. GREEN_FONT_COLOR_CODE .. "+" .. posBuff ..
                              FONT_COLOR_CODE_CLOSE;
        end
        if (negBuff < 0) then
            tooltipRow1 = tooltipRow1 .. RED_FONT_COLOR_CODE .. " " .. negBuff .. FONT_COLOR_CODE_CLOSE;
        end
        if (posBuff > 0 or negBuff < 0) then
            tooltipRow1 = tooltipRow1 .. HIGHLIGHT_FONT_COLOR_CODE .. ")" .. FONT_COLOR_CODE_CLOSE;
        end
    end

    local tooltipRow2 = GetAttributeTooltipDetailText(stat, base, current, posBuff, negBuff, playerLevel);

    return tooltipRow1, tooltipRow2;
end

function AS.Frame_SetAttributes(playerLevel)
    for i = 1, 5 do
        local base, current, posBuff, negBuff = UnitStat("player", i);
        local frame = _G["AS_AttributeLabelFrame" .. i];

        -- Color values in white if there are no bonuses. Green if there are any. Red if there are any debuffs.
        if ((posBuff == 0) and (negBuff == 0)) then
            frame.ValueFrame.Value:SetText(current);
        elseif (negBuff < 0) then
            frame.ValueFrame.Value:SetText(RED_FONT_COLOR_CODE .. current .. FONT_COLOR_CODE_CLOSE);
        else
            frame.ValueFrame.Value:SetText(GREEN_FONT_COLOR_CODE .. current .. FONT_COLOR_CODE_CLOSE);
        end

        frame.tooltipRow1, frame.tooltipRow2 = AS.GetAttributeTooltipText(HIGHLIGHT_FONT_COLOR_CODE ..
                                                                              _G["SPELL_STAT" .. i .. "_NAME"] .. " ",
                                                                          frame.stat, base, current, posBuff, negBuff,
                                                                          playerLevel);
    end
end

function AS.GetAttributesPanel()
    return AS_AttributesContainerFrame;
end
