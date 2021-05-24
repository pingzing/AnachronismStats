local addonName, AS = ...; -- Get addon name and shared table.

AS.ContainerFrame = nil; -- Gets set in OnLoad.

-- Keys are integer position, value is string name of panel.
-- Persisted between sessions via SavedVariablesPerCharacter
AnachronismStats_PanelPositions = nil;

local _isOpen = false;

-- Keys are names, values are references to panels
local _panelReferences = nil;

-- //// PANEL POSITION HANDLING ////

local function GetOrLoadPanelPositions()
    if AnachronismStats_PanelPositions then
        return AnachronismStats_PanelPositions;
    end

    -- No saved variables? Generate inital positions
    local attrPanel = AS.GetAttributesPanel();
    local meleePanel = AS.GetMeleePanel();
    local spellPanel = AS.GetSpellPanel();
    local defensesPanel = AS.GetDefensePanel();
    local rangedPanel = AS.GetRangedPanel();
    AnachronismStats_PanelPositions = {};
    AnachronismStats_PanelPositions[1] = attrPanel:GetName();
    AnachronismStats_PanelPositions[2] = meleePanel:GetName();
    AnachronismStats_PanelPositions[3] = spellPanel:GetName();
    AnachronismStats_PanelPositions[4] = defensesPanel:GetName();
    AnachronismStats_PanelPositions[5] = rangedPanel:GetName();

    return AnachronismStats_PanelPositions;
end

local function ArrangePanels(panelPositions)
    for i, v in ipairs(panelPositions) do
        local currPanel = _panelReferences[v];
        if i == 1 then
            -- Special case for the first panel, as it gets positioned relative to the root frame
            currPanel:SetPoint("TOPLEFT", AnachronismStatsContent, "TOPLEFT", 5, 0);
        else
            -- Everything else will be relative to the frame above itself
            local prevPanel = _panelReferences[panelPositions[i - 1]];
            local prevPanelHeight = prevPanel:GetHeight();
            currPanel:SetPoint("TOPLEFT", prevPanel, "TOPLEFT", 0, -prevPanelHeight);
        end
    end
end

local function GetPanelPosition(panelPositions, panelName)
    for i, v in ipairs(panelPositions) do
        if v == panelName then
            return i;
        end
    end
    return -1;
end

local function SwapPanelPositions(panelPositions, i1, i2)
    local panelAt1 = panelPositions[i1];
    panelPositions[i1] = panelPositions[i2];
    panelPositions[i2] = panelAt1;
end

-- //// END PANEL POSITION HANDLING ////

-- //// GLOBAL FUNCTIONS ////

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

    return tooltipRow1;
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

function AS.StatPanel_UpArrow_OnClick(panel)
    local panelPositions = GetOrLoadPanelPositions();
    local panelPosition = GetPanelPosition(panelPositions, panel:GetName());
    if (panelPosition == 1 or panelPosition == -1) then
        -- We're either at the top, or we got an invalid position
        return;
    end

    SwapPanelPositions(panelPositions, panelPosition, panelPosition - 1);

    ArrangePanels(panelPositions);
end

function AS.StatPanel_DownArrow_OnClick(panel)
    local panelPositions = GetOrLoadPanelPositions();
    local panelPosition = GetPanelPosition(panelPositions, panel:GetName());
    if (panelPosition == -1 or panelPosition == 5) then
        -- We're either at the bottom, or got an invalid position
        return;
    end

    SwapPanelPositions(panelPositions, panelPosition, panelPosition + 1);

    ArrangePanels(panelPositions);
end

local function SetMainFrameVisible(visible)
    if (visible) then
        AnachronismStatsFrame:Show();
        SquareButton_SetIcon(AS_OpenStats, "LEFT");
        _isOpen = true;
    else
        AnachronismStatsFrame:Hide();
        SquareButton_SetIcon(AS_OpenStats, "RIGHT");
        _isOpen = false;
    end
end

-- //// END GLOBAL FUNCTIONS ////

-- //// EVENT HANDLERS ////

function AnachronismStats_OpenStats_OnClick()
    if (_isOpen) then
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
    AS.ContainerFrame = AnachronismStatsContent;

    self:RegisterEvent("ADDON_LOADED");

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
end

local function LoadCompleted()
    SetMainFrameVisible(false);

    local attrPanel = AS.GetAttributesPanel();
    local meleePanel = AS.GetMeleePanel();
    local spellPanel = AS.GetSpellPanel();
    local defensesPanel = AS.GetDefensePanel();
    local rangedPanel = AS.GetRangedPanel();
    _panelReferences = {};
    _panelReferences[attrPanel:GetName()] = attrPanel;
    _panelReferences[meleePanel:GetName()] = meleePanel;
    _panelReferences[spellPanel:GetName()] = spellPanel;
    _panelReferences[defensesPanel:GetName()] = defensesPanel;
    _panelReferences[rangedPanel:GetName()] = rangedPanel;

    local panelPositions = GetOrLoadPanelPositions();
    ArrangePanels(panelPositions);

    print("AnachronismStats loaded!");
end

function AnachronismStats_Frame_OnEvent(self, event, ...)
    if (event == "ADDON_LOADED" and ... == "AnachronismStats") then
        LoadCompleted();
    else
        self:SetScript("OnUpdate", AnachronismStats_Frame_QueuedUpdate);
    end
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

-- //// DEBUG HELPERS ////
--[[ rPrint(struct, [limit], [indent])   Recursively print arbitrary data. 
	Set limit (default 100) to stanch infinite loops.
	Indents tables as [KEY] VALUE, nested tables as [KEY] [KEY]...[KEY] VALUE
	Set indent ("") to prefix each line:    Mytable [KEY] [KEY]...[KEY] VALUE
--]]
function AS.DebugPrintTable(s, l, i) -- recursive Print (structure, limit, indent)
    l = (l) or 100;
    i = i or ""; -- default item limit, indent string
    if (l < 1) then
        print "ERROR: Item limit reached.";
        return l - 1
    end
    local ts = type(s);
    if (ts ~= "table") then
        print(i, ts, s);
        return l - 1
    end
    print(i, ts); -- print "table"
    for k, v in pairs(s) do -- print "[KEY] VALUE"
        l = AS.DebugPrintTable(v, l, i .. "  [" .. tostring(k) .. "]");
        if (l < 0) then
            break
        end
    end
    return l
end
