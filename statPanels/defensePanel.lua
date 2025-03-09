local addonName, AS = ... -- Get addon name and shared table.
AnachronismStats = AS -- Globalized, so XML can see it

function GetDefenseDetailText(base, posBuff, negBuff)

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
    AS.Ratings.SetArmorFrame(base, armorPosBuff, armorNegBuff, playerLevel, armorFrame);

    -- Defense
    local defenseFrame = AS_DefensesLabelFrame2;
    local defenseValue, defenseModifier = UnitDefense("player");
    AS.Ratings.SetDefenseFrame(defenseValue, defenseModifier, playerLevel, defenseFrame);

    -- Block
    local blockFrame = AS_DefensesLabelFrame3;
    local blockChance = GetBlockChance();
    local blockValue = GetShieldBlock();
    AS.Ratings.SetBlockFrame(blockChance, blockValue, playerLevel, blockFrame);

    -- Dodge
    local dodgeFrame = AS_DefensesLabelFrame4;
    local dodgeChance = GetDodgeChance();
    AS.Ratings.SetDodgeFrame(dodgeChance, playerLevel, dodgeFrame);

    -- Parry
    local parryFrame = AS_DefensesLabelFrame5;
    local parryChance = GetParryChance();
    AS.Ratings.SetParryFrame(parryChance, playerLevel, parryFrame);

    -- Avoidance and Mitigation
    local avoidanceFrame = AS_DefensesLabelFrame6;
    AS.Ratings.SetAvoidanceFrame(defenseValue, defenseModifier, dodgeChance, parryChance, blockChance, playerLevel,
                                 avoidanceFrame);
end

function AS.GetDefensePanel()
    return AS_DefensesContainerFrame;
end
