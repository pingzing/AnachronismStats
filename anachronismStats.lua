local addonName, AS = ...; -- Get addon name and shared table.

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
AS.ContainerFrame = nil; -- Gets set in OnLoad.

local base_ShowSubFrame = CharacterFrame_ShowSubFrame;
local isOpen = false;

-- //// GLOBAL FUNCTIONS ////

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

local equipmentSlots = {
    1, -- head
    2, -- neck
    3, -- shoulders
    15, -- cloak
    5, -- chest
    9, -- bracers
    10, -- gloves
    6, -- belt
    7, -- pants
    8, -- boots
    11, -- ring 1
    12, -- ring 2
    13, -- trinket 1
    14, -- trinket 2
    16, -- main hand
    17, -- off hand
    18, -- ranged slot
}
function AS.GetMp5FromEquippedItems()
    local summedMp5 = 0;
    for _, slotId in ipairs(equipmentSlots) do
        local itemId = GetInventoryItemID("player", slotId);
        if (itemId ~= nil) then
            local statsTable = {}; -- need an empty table here, because GetItemStats() won't clear it for us
            GetItemStats("item:" .. itemId, statsTable); -- this fills the stats table
            local mp5Value = statsTable["ITEM_MOD_POWER_REGEN0_SHORT"]; -- aka MP5
            if (mp5Value ~= nil) then
                summedMp5 = summedMp5 + mp5Value + 1; -- for some reason, MP5 values are returned as 1 less than actual, so add 1
            end
        end
    end

    return summedMp5;
end

function AS.GetStatValue(base, posBuff, negBuff)
    local effective = max(0, base + posBuff + negBuff);
    if ((posBuff == 0) and (negBuff == 0)) then
        return effective;
    else
        -- if there is a negative buff then show the main number in red, even if there are
        -- positive buffs. Otherwise show the number in green
        if (negBuff < 0) then
            return RED_FONT_COLOR_CODE .. effective .. FONT_COLOR_CODE_CLOSE;
        else
            return GREEN_FONT_COLOR_CODE .. effective .. FONT_COLOR_CODE_CLOSE;
        end
    end
end

function AS.GetStatTooltipText(name, base, posBuff, negBuff)
    local effective = max(0, base + posBuff + negBuff);
    local tooltipRow1 = HIGHLIGHT_FONT_COLOR_CODE .. name .. " " .. effective;
    if ((posBuff == 0) and (negBuff == 0)) then
        tooltipRow1 = tooltipRow1 .. FONT_COLOR_CODE_CLOSE;
    else
        if (posBuff > 0 or negBuff < 0) then
            tooltipRow1 = tooltipRow1 .. " (" .. base .. FONT_COLOR_CODE_CLOSE;
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

    local tooltipRow2;
    if (name == "Attack Power") then
        tooltipRow2 = "Increases your damage with melee weapons by " ..
                          format("%.1F", ((base + posBuff + negBuff) / 14)) .. " damage per second";
    elseif (name == "Armor") then
        tooltipRow2 = GetArmorDetailText(base, posBuff, negBuff);
    elseif (name == "Defense") then
        tooltipRow2 = GetDefenseDetailText(base, posBuff, negBuff);
    elseif (name == "Ranged Attack Power") then
        tooltipRow2 = "Increases your damage with ranged weapons by " ..
                          format("%.1F", ((base + posBuff + negBuff) / 14)) .. " damage per second";
    end

    return tooltipRow1, tooltipRow2;
end

function AS.ShowStatTooltip(self)
    if (not (self.tooltipRow1) and not (self.tooltipSpecialCase)) then
        return;
    end

    -- If the tooltip is super special, it can handle its own nonsense. Let it take over and bail out.
    if (self.tooltipSpecialCase) then
        self.tooltipSpecialCase(self);
        return;
    end

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(self.tooltipRow1, 1.0, 1.0, 1.0);
    if (self.tooltipRow2) then
        GameTooltip:AddLine(self.tooltipRow2, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
    end
    GameTooltip:Show();
end

local function SetMainFrameVisible(visible)
    if (visible) then
        AnachronismStatsFrame:Show();
        SquareButton_SetIcon(AS_OpenStats, "LEFT");
        isOpen = true;
    else
        AnachronismStatsFrame:Hide();
        SquareButton_SetIcon(AS_OpenStats, "RIGHT");
        isOpen = false;
    end
end

-- //// END GLOBAL FUNCTIONS ////

-- //// EVENT HANDLERS ////

function AnachronismStats_OpenStats_OnClick()
    if (isOpen) then
        SetMainFrameVisible(false);
    else
        SetMainFrameVisible(true);
    end
end

function AnachronismStats_OpenStats_OnLoad(self)
    SquareButton_SetIcon(self, "RIGHT");
end

function AnachronismStats_OpenStats_OnHide()
    -- Make sure we're not sitting in the background if this tab has focus
    -- when the character frame is closed.
    SetMainFrameVisible(false);
end

function AnachronismStats_Frame_OnMouseWheel(self, delta)
    local current = AnachronismStatsScrollFrame_VSlider:GetValue();
    local _, maxValue = AnachronismStatsScrollFrame_VSlider:GetMinMaxValues();
    if (delta < 0) and (current < maxValue) then
        AnachronismStatsScrollFrame_VSlider:SetValue(current + 5);
    elseif (delta > 0) and (current > 1) then
        AnachronismStatsScrollFrame_VSlider:SetValue(current - 5);
    end
end

function AnachronismStats_Frame_OnLoad(self)
    print("AnachronismStats Loaded!");
    SetMainFrameVisible(false);
    AS.ContainerFrame = AnachronismStatsContent;

    self:RegisterEvent("UNIT_RESISTANCES");
    self:RegisterEvent("UNIT_STATS");
    self:RegisterEvent("UNIT_DAMAGE");
    self:RegisterEvent("UNIT_RANGEDDAMAGE");
    self:RegisterEvent("PLAYER_DAMAGE_DONE_MODS");
    self:RegisterEvent("UNIT_ATTACK_SPEED");
    self:RegisterEvent("UNIT_ATTACK_POWER");
    self:RegisterEvent("UNIT_RANGED_ATTACK_POWER");
    self:RegisterEvent("UNIT_ATTACK");
    self:RegisterEvent("SKILL_LINES_CHANGED");
    self:RegisterEvent("UPDATE_SHAPESHIFT_FORMS");
    self:RegisterEvent("UNIT_AURA");
    self:RegisterEvent("UNIT_POWER_UPDATE");

    -- Queue one initial update
    self:SetScript("OnUpdate", AnachronismStats_Frame_QueuedUpdate);

    -- Hook ShowSubFrame so that we get closed if any other tab gets opened.
    CharacterFrame_ShowSubFrame = function(frameName)
        if (frameName ~= "PaperDollItemsFrame") then
            SetMainFrameVisible(false);
        end
        base_ShowSubFrame(frameName);
    end
end

function AnachronismStats_Frame_OnEvent(self, event, ...)
    self:SetScript("OnUpdate", AnachronismStats_Frame_QueuedUpdate);
end

local function UpdateStatFrames()
    local playerLevel = UnitLevel("player");
    AS.Frame_SetAttributes(playerLevel);
    AS.Frame_SetMelee(playerLevel);
    AS.Frame_SetRanged(playerLevel);
    AS.Frame_SetSpell(playerLevel);
    AS.Frame_SetDefenses(playerLevel);
end

-- Make sure we batch event updates to only happen once-per-frame.
function AnachronismStats_Frame_QueuedUpdate(self)
    -- Clear the queued update.
    self:SetScript("OnUpdate", nil);
    UpdateStatFrames();
end

-- //// END EVENT HANDLERS ////
