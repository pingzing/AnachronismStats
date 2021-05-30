local addonName, AS = ... -- Get addon name and shared table.
AnachronismStats = AS -- Globalized, so XML can see it

function GetArmorDetailText(base, posBuff, negBuff)
    local playerLevel = UnitLevel("player");
    local effectiveArmor = base + posBuff + negBuff;
    -- Some serious magic, taken straight form Blizzard's PaperDoll code
    local armorReduction = effectiveArmor / ((85 * playerLevel) + 400);
    armorReduction = 100 * (armorReduction / (armorReduction + 1));
    return "Reduces physical damage taken from level " .. playerLevel .. " enemies by " ..
               format("%.2F", armorReduction) .. "%";
end

function GetDefenseDetailText(base, posBuff, negBuff)
    local playerLevel = UnitLevel("player");
    local effectiveDefense = base + posBuff + negBuff;

    local maxSkillForLevel = playerLevel * 5;
    local bonusSkill = effectiveDefense - maxSkillForLevel;
    local defenseRating = GetCombatRating(AS.RatingIds.Defense);
    local defenseFromRating = GetCombatRatingBonus(AS.RatingIds.Defense);
    local percentBonusText = format("%.2F", max(0, bonusSkill * .04)) .. "%";
    -- Not certain about the daze .16 value.
    local detailText = "Against a level " .. playerLevel .. " enemy:\n" .. "  -" .. percentBonusText ..
                           " to be hit/crit " .. "\n" .. "  +" .. percentBonusText .. " Block/Dodge/Parry " .. "\n-" ..
                           format("%.2F", max(0, bonusSkill * .16)) .. "% chance to be dazed" .. "\nDefense rating: " ..
                           defenseRating .. " (+" .. defenseFromRating .. " defense)";

    return detailText;
end

local function OnUpArrow_Click()
    AS.StatPanel_UpArrow_OnClick(AS_DefensesContainerFrame);
end

local function OnDownArrow_Click()
    AS.StatPanel_DownArrow_OnClick(AS_DefensesContainerFrame);
end

function AnachronismStats_DefensePanel_OnLoad(self)
    local containerFrame = AS.ContainerFrame;
    self:SetParent(containerFrame);

    AS_DefensesHeaderFrame.UpArrow:SetScript("OnClick", OnUpArrow_Click);
    AS_DefensesHeaderFrame.DownArrow:SetScript("OnClick", OnDownArrow_Click);
end

function AS.Frame_SetDefenses(playerLevel)
    -- Armor
    local armorFrame = AS_DefensesLabelFrame1;
    local base, _, _, armorPosBuff, armorNegBuff = UnitArmor("player");
    local armorText = AS.GetStatValue(base, armorPosBuff, armorNegBuff);
    armorFrame.ValueFrame.Value:SetText(armorText);
    armorFrame.tooltipRow1 = AS.GetStatTooltipText(armorFrame.name, base, armorPosBuff, armorNegBuff);
    armorFrame.tooltipRow2 = GetArmorDetailText(base, armorPosBuff, armorNegBuff);

    -- Defense
    local defenseFrame = AS_DefensesLabelFrame2;
    local defenseValue, defenseModifier = UnitDefense("player");
    -- UnitDefense gives us a single modifier value, which can be positive or negative.
    local defPosBuff, defNegBuff = 0, 0;
    if (defenseModifier > 0) then
        defPosBuff = defenseModifier;
    elseif (defenseModifier < 0) then
        defNegBuff = defenseModifier;
    end
    local defenseText = AS.GetStatValue(defenseValue, defPosBuff, defNegBuff);
    defenseFrame.ValueFrame.Value:SetText(defenseText);
    defenseFrame.tooltipRow1 = AS.GetStatTooltipText(defenseFrame.name, defenseValue, defPosBuff, defNegBuff);
    defenseFrame.tooltipRow2 = GetDefenseDetailText(defenseValue, defPosBuff, defNegBuff);

    -- Block
    local blockFrame = AS_DefensesLabelFrame3;
    local blockChance = GetBlockChance();
    local blockChanceText = format("%.2F", blockChance) .. "%";
    local blockValue = GetShieldBlock();
    local blockRating = GetCombatRating(AS.RatingIds.Block);
    local blockPercentFromRating = GetCombatRatingBonus(AS.RatingIds.Block);
    blockFrame.ValueFrame.Value:SetText(blockChanceText);
    blockFrame.tooltipRow1 = "Block Chance " .. blockChanceText;
    blockFrame.tooltipRow2 =
        "Increases your chance to block by " .. blockChanceText .. " against level " .. playerLevel .. " targets" ..
            "\nBlock value: " .. blockValue .. "\nBlock rating: " .. blockRating .. " (+" .. blockPercentFromRating ..
            "% to block)";

    -- Dodge
    local dodgeFrame = AS_DefensesLabelFrame4;
    local dodgeChance = GetDodgeChance();
    local dodgeChanceText = format("%.2F", dodgeChance) .. "%";
    local dodgeRating = GetCombatRating(AS.RatingIds.Dodge);
    local dodgePercentFromRating = GetCombatRatingBonus(AS.RatingIds.Dodge);
    dodgeFrame.ValueFrame.Value:SetText(dodgeChanceText);
    dodgeFrame.tooltipRow1 = "Dodge Chance " .. dodgeChanceText;
    dodgeFrame.tooltipRow2 =
        "Increases your chance to dodge by " .. dodgeChanceText .. " against level " .. playerLevel .. " targets" ..
            "\nDodge rating: " .. dodgeRating .. " (+" .. dodgePercentFromRating .. "% to dodge)";

    -- Parry
    local parryFrame = AS_DefensesLabelFrame5;
    local parryChance = GetParryChance();
    local parryChanceText = format("%.2F", parryChance) .. "%";
    local parryRating = GetCombatRating(AS.RatingIds.Parry);
    local parryPercentFromRating = GetCombatRatingBonus(AS.RatingIds.Parry);
    parryFrame.ValueFrame.Value:SetText(parryChanceText);
    parryFrame.tooltipRow1 = "Parry Chance " .. parryChanceText;
    parryFrame.tooltipRow2 =
        "Increases your chance to parry by " .. parryChanceText .. " against level " .. playerLevel .. " targets" ..
            "\nParry rating: " .. parryRating .. " (+" .. parryPercentFromRating .. "% to parry)";

    -- Avoidance and Mitigation
    local avoidanceFrame = AS_DefensesLabelFrame6;
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

function AS.GetDefensePanel()
    return AS_DefensesContainerFrame;
end
