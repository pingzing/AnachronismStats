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
    local percentBonusText = format("%.2F", max(0, bonusSkill * .04)) .. "%";
    local detailText = "Against a level " .. playerLevel .. " enemy:\n" .. "  -" .. percentBonusText ..
                           " to be hit/crit " .. "\n" .. "  +" .. percentBonusText .. " Block/Dodge/Parry ";

    local dazeReductionText = format("%.2F", max(0, bonusSkill * .16)); -- Not certain about this value.
    detailText = detailText .. "\n  -" .. dazeReductionText .. "% chance to be dazed";
    return detailText;
end

function AnachronismStats_DefensePanel_OnLoad(self)
    local containerFrame = AS.ContainerFrame;
    self:SetParent(containerFrame);
end

function AS.Frame_SetDefenses(playerLevel)

    -- Armor
    local armorFrame = AS_DefensesLabelFrame1;
    local base, effectiveArmor, armor, posBuff, negBuff = UnitArmor("player");
    local armorText = AS.GetStatValue(base, posBuff, negBuff);
    armorFrame.ValueFrame.Value:SetText(armorText);
    armorFrame.tooltipRow1, armorFrame.tooltipRow2 = AS.GetStatTooltipText(armorFrame.name, base, posBuff, negBuff);

    -- Defense
    local defenseFrame = AS_DefensesLabelFrame2;
    local defenseValue, defenseModifier = UnitDefense("player");
    local defenseText = AS.GetStatValue(defenseValue, defenseModifier, 0);
    defenseFrame.ValueFrame.Value:SetText(defenseText);
    defenseFrame.tooltipRow1, defenseFrame.tooltipRow2 = AS.GetStatTooltipText(defenseFrame.name, defenseValue,
                                                                               defenseModifier, 0);

    -- Block
    local blockFrame = AS_DefensesLabelFrame3;
    local blockChance = GetBlockChance();
    local blockChanceText = format("%.2F", blockChance) .. "%";
    local blockValue = GetShieldBlock();
    blockFrame.ValueFrame.Value:SetText(blockChanceText);
    blockFrame.tooltipRow1 = "Block Chance " .. blockChanceText;
    blockFrame.tooltipRow2 = "Increases your chance to block " .. blockValue .. " damage by " .. blockChanceText ..
                                 " against level " .. playerLevel .. " targets";

    -- Dodge
    local dodgeFrame = AS_DefensesLabelFrame4;
    local dodgeChance = GetDodgeChance();
    local dodgeChanceText = format("%.2F", dodgeChance) .. "%";
    dodgeFrame.ValueFrame.Value:SetText(dodgeChanceText);
    dodgeFrame.tooltipRow1 = "Dodge Chance " .. dodgeChanceText;
    dodgeFrame.tooltipRow2 =
        "Increases your chance to dodge by " .. dodgeChanceText .. " against level " .. playerLevel .. " targets";

    -- Parry
    local parryFrame = AS_DefensesLabelFrame5;
    local parryChance = GetParryChance();
    local parryChanceText = format("%.2F", parryChance) .. "%";
    parryFrame.ValueFrame.Value:SetText(parryChanceText);
    parryFrame.tooltipRow1 = "Parry Chance " .. parryChanceText;
    parryFrame.tooltipRow2 =
        "Increases your chance to parry by " .. parryChanceText .. " against level " .. playerLevel .. " targets";

end
