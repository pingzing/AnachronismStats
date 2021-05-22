local addonName, AS = ... -- Get addon name and shared table.
AnachronismStats = AS -- Globalized, so XML can see it

local function HasRanged()
    local hasRelic = UnitHasRelicSlot("player");
    -- Seriously. This is how the official Blizzard PaperDoll does it. It checks for a texture in item slot 18.
    local rangedTexture = GetInventoryItemTexture("player", 18);
    return (not (hasRelic) and rangedTexture);
end

local function FillOutRangedDamageFrame(rangedDamageFrame)

    if (not (HasRanged())) then
        rangedDamageFrame.ValueFrame.Value:SetText("N/A");
        return rangedDamageFrame;
    end

    local rangedAttackSpeed, minDamage, maxDamage, physicalBonusPos, physicalBonusNeg, percent = UnitRangedDamage(
                                                                                                     "player");
    local displayMin = max(floor(minDamage), 1);
    local displayMax = max(ceil(maxDamage), 1);

    minDamage = (minDamage / percent) - physicalBonusPos - physicalBonusNeg;
    maxDamage = (maxDamage / percent) - physicalBonusPos - physicalBonusNeg;

    local baseDamage = (minDamage + maxDamage) * 0.5;
    local fullDamage = (baseDamage + physicalBonusPos + physicalBonusNeg) * percent;
    local totalBonus = (fullDamage - baseDamage);
    local damagePerSecond = (max(fullDamage, 1) / rangedAttackSpeed);
    local tooltip = max(floor(minDamage), 1) .. " - " .. max(ceil(maxDamage), 1);

    if (totalBonus == 0) then
        if ((displayMin < 100) and (displayMax < 100)) then
            rangedDamageFrame.ValueFrame.Value:SetText(displayMin .. " - " .. displayMax);
        else
            rangedDamageFrame.ValueFrame.Value:SetText(displayMin .. "-" .. displayMax);
        end
    else
        local colorPos = "|cff20ff20";
        local colorNeg = "|cffff2020";
        local color;
        if (totalBonus > 0) then
            color = colorPos;
        else
            color = colorNeg;
        end
        if ((displayMin < 100) and (displayMax < 100)) then
            rangedDamageFrame.ValueFrame.Value:SetText(color .. displayMin .. " - " .. displayMax .. "|r");
        else
            rangedDamageFrame.ValueFrame.Value:SetText(color .. displayMin .. "-" .. displayMax .. "|r");
        end
        if (physicalBonusPos > 0) then
            rangedDamageFrame.tooltip = tooltip .. colorPos .. " +" .. physicalBonusPos .. "|r";
        end
        if (physicalBonusNeg < 0) then
            rangedDamageFrame.tooltip = tooltip .. colorNeg .. " " .. physicalBonusNeg .. "|r";
        end
        if (percent > 1) then
            rangedDamageFrame.tooltip = tooltip .. colorPos .. " x" .. floor(percent * 100 + 0.5) .. "%|r";
        elseif (percent < 1) then
            rangedDamageFrame.tooltip = tooltip .. colorNeg .. " x" .. floor(percent * 100 + 0.5) .. "%|r";
        end
        rangedDamageFrame.tooltip = tooltip .. " " .. format(DPS_TEMPLATE, damagePerSecond);
    end

    rangedDamageFrame.attackSpeed = rangedAttackSpeed;
    rangedDamageFrame.damage = tooltip;
    rangedDamageFrame.dps = damagePerSecond;

    return rangedDamageFrame;
end

local function ShowRangedDamageTooltip(self)
    if (not (HasRanged())) then
        return;
    end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText("Ranged Damage", HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(ATTACK_SPEED_COLON, format("%.2F", self.attackSpeed), NORMAL_FONT_COLOR.r,
                              NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g,
                              HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(DAMAGE_COLON, self.damage, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b,
                              HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(DAMAGE_PER_SECOND, format("%.1F", self.dps), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g,
                              NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g,
                              HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:Show();
end

local function GetRangedWeaponSkillDetails(skillBase, skillMod, playerLevel)
    local wepSkillText;
    local wepSkillTooltipRow1;
    local wepSkillTooltipRow2;

    wepSkillText = AS.GetStatValue(skillBase, skillMod, 0)
    wepSkillTooltipRow1 = AS.GetStatTooltipText("Ranged Weapon Skill", skillBase, skillMod, 0);

    local maxSkillForLevel = playerLevel * 5;
    -- These might be negative.
    local bonusSkill = skillBase - maxSkillForLevel;
    local percentBonus = format("%.2F", bonusSkill * .04) .. "%";
    wepSkillTooltipRow2 =
        "Increases the chanec for your ranged attacks chance to hit and crit, and reduces their chance to be blocked by " ..
            percentBonus .. " by a level " .. playerLevel .. " enemy";

    return wepSkillText, wepSkillTooltipRow1, wepSkillTooltipRow2;
end

local function OnUpArrow_Click()
    AS.StatPanel_UpArrow_OnClick(AS_RangedContainerFrame);
end

local function OnDownArrow_Click()
    AS.StatPanel_DownArrow_OnClick(AS_RangedContainerFrame);
end

function AnachronismStats_RangedPanel_OnLoad(self)
    local containerFrame = AS.ContainerFrame;
    self:SetParent(containerFrame);

    AS_RangedHeaderFrame.UpArrow:SetScript("OnClick", OnUpArrow_Click);
    AS_RangedHeaderFrame.DownArrow:SetScript("OnClick", OnDownArrow_Click);
end

function AS.Frame_SetRanged(playerLevel)
    local _, classFileName = UnitClass("player");
    local rangedDamageFrame = AS_RangedLabelFrame1;
    local rangedSpeedFrame = AS_RangedLabelFrame2;
    local rangedPowerFrame = AS_RangedLabelFrame3;
    local rangedHitFrame = AS_RangedLabelFrame4;
    local rangedCritFrame = AS_RangedLabelFrame5;
    local rangedWepSkillFrame = AS_RangedLabelFrame6;

    if (not (HasRanged())) then
        -- Fill out everything with N/A. Druids, Paladins and Shamans off the table immediately.
        rangedDamageFrame.ValueFrame.Value:SetText("N/A");
        rangedSpeedFrame.ValueFrame.Value:SetText("N/A");
        rangedPowerFrame.ValueFrame.Value:SetText("N/A");
        rangedHitFrame.ValueFrame.Value:SetText("N/A");
        rangedCritFrame.ValueFrame.Value:SetText("N/A");
        rangedWepSkillFrame.ValueFrame.Value:SetText("N/A");
        return;
    end

    -- Damage    
    rangedDamageFrame = FillOutRangedDamageFrame(rangedDamageFrame);
    rangedDamageFrame.tooltipSpecialCase = ShowRangedDamageTooltip;

    -- Speed    
    local rangedAttackSpeed, _, _, _, _, _ = UnitRangedDamage("player");
    local hastePercent = GetRangedHaste();
    local speedText = format("%.2F", rangedAttackSpeed);
    if (hastePercent == 0) then
        rangedSpeedFrame.ValueFrame.Value:SetText(speedText);
    elseif (hastePercent > 0) then
        speedText = GREEN_FONT_COLOR_CODE .. speedText .. FONT_COLOR_CODE_CLOSE;
    elseif (hastePercent < 0) then
        speedText = RED_FONT_COLOR_CODE .. speedText .. FONT_COLOR_CODE_CLOSE;
    end
    rangedSpeedFrame.ValueFrame.Value:SetText(speedText);
    rangedSpeedFrame.tooltipRow1 = "Ranged Attack Speed " .. speedText;
    rangedSpeedFrame.tooltipRow2 = "Haste: " .. format("%.2F", hastePercent) .. "%";

    -- Ranged Attack Power    
    -- Mages, Priests and Warlocks use wands, which don't benefit from RAP
    if (classFileName == AS.CLASSES.Warlock or classFileName == AS.CLASSES.Priest or classFileName == AS.CLASSES.Mage) then
        rangedPowerFrame.ValueFrame.Value:SetText("--");
    else
        local base, posBuff, negBuff = UnitRangedAttackPower("player");
        rangedPowerFrame.ValueFrame.Value:SetText(AS.GetStatValue(base, posBuff, negBuff));
        rangedPowerFrame.tooltipRow1, rangedPowerFrame.tooltipRow2 =
            AS.GetStatTooltipText(rangedPowerFrame.name, base, posBuff, negBuff);
    end

    -- Ranged Hit Chance       
    local hitFromGear = GetHitModifier(); -- Seems to be the same API for ranged and melee?
    -- TODO: Get hit from talents and Weapon skill too
    rangedHitFrame.ValueFrame.Value:SetText(hitFromGear .. "%");
    rangedHitFrame.tooltipRow1 = "Ranged Hit Chance " .. hitFromGear .. "%";
    rangedHitFrame.tooltipRow2 = "Increases your ranged chance to hit a target of level " .. playerLevel .. " by " ..
                                     hitFromGear .. "%";

    -- Ranged Crit    
    local rangedCrit = GetRangedCritChance();
    -- TODO: Get crit from weapon skill (and talents? Are there any?)
    local critText = format("%.2F", rangedCrit) .. "%";
    rangedCritFrame.ValueFrame.Value:SetText(critText);
    rangedCritFrame.tooltipRow1 = "Ranged Critical Hit Chance " .. critText;
    rangedCritFrame.tooltipRow2 = "Increases your ranged chance to crit a target of level " .. playerLevel .. " by " ..
                                      critText;

    -- Ranged weapon skill    
    local rangedAttackBase, rangedAttackMod = UnitRangedAttack("player");
    local wepSkillText, wepSkillTooltipRow1, wepSkillTooltipRow2 =
        GetRangedWeaponSkillDetails(rangedAttackBase, rangedAttackMod, playerLevel);
    rangedWepSkillFrame.ValueFrame.Value:SetText(wepSkillText);
    rangedWepSkillFrame.tooltipRow1 = wepSkillTooltipRow1;
    rangedWepSkillFrame.tooltipRow2 = wepSkillTooltipRow2;
end

function AS.GetRangedPanel()
    return AS_RangedContainerFrame;
end
