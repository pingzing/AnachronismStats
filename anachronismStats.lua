local CHARACTERFRAME_SUBFRAMES = { "PaperDollFrame", "PetPaperDollFrame", "ReputationFrame", "SkillFrame", "HonorFrame" };
local base_OnClick = CharacterFrameTab_OnClick;

local function cPrint(text)
    DEFAULT_CHAT_FRAME:AddMessage(text);
end

local function ShowAnachronismStatsFrame()
    -- Hide all other frames...
    for idx, value in pairs(CHARACTERFRAME_SUBFRAMES) do
        _G[value]:Hide();
    end    
    
    -- ...and show ours.
    AnachronismStatsFrame:Show();
end

function CharacterFrameTab6_OnLoad(self)        
    -- Make sure the CharacterFrame iterates through our Frame when doing Tab stuff
    PanelTemplates_SetNumTabs(CharacterFrame, CharacterFrame.numTabs + 1);    

    -- And override the Tab OnClick in CharacterFrame to show our frame.
    CharacterFrameTab_OnClick = function(self, button)
        local name = self:GetName();
        if ( name == "CharacterFrameTab6" ) then
            ShowAnachronismStatsFrame();
        else
            AnachronismStatsFrame:Hide();
        end
    
        base_OnClick(self, button);
    end    
end

function AnachronismStatsFrame_OnLoad(self)
    AnachronismStatsFrame:Hide();    

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
    
    -- Queue one initial update
    self:SetScript("OnUpdate", AnachronismStatsFrame_QueuedUpdate);
end

function AnachronismStatsFrame_OnEvent(self, event, ...)
    local unit = ...;    
    if ( unit ~= "player") then
        return;
    end

    self:SetScript("OnUpdate", AnachronismStatsFrame_QueuedUpdate);
end

-- Make sure we batch event updates to only happen once-per-frame.
function AnachronismStatsFrame_QueuedUpdate(self)
    -- Clear the queued update.
    self:SetScript("OnUpdate", nil);
    AnachronismStatsFrame_UpdateStats();
end

function AnachronismStatsFrame_UpdateStats()
    AnachronismStatsFrame_SetAttributes();
    AnachronismStatsFrame_SetMelee();
    AnachronismStatsFrame_SetRanged();
    AnachronismStatsFrame_SetSpell();
    AnachronismStatsFrame_SetDefenses();
end

function AnachronismStatsFrame_SetAttributes()
    -- Strength
    local base, current, posBuff, negBuff = UnitStat("player", 1);
    StrengthLabelFrame.ValueFrame.Value:SetText(current);
    -- TODO: Mouseover stuff

    -- Agility
    local base, current, posBuff, negBuff = UnitStat("player", 2);
    AgilityLabelFrame.ValueFrame.Value:SetText(current);
    -- TODO: Mouseover stuff

    -- Stamina
    local base, current, posBuff, negBuff = UnitStat("player", 3);
    StaminaLabelFrame.ValueFrame.Value:SetText(current);
    -- TODO: Mouseover stuff

    -- Intellect
    local base, current, posBuff, negBuff = UnitStat("player", 4);
    IntellectLabelFrame.ValueFrame.Value:SetText(current);
    -- TODO: Mouseover stuff

    -- Spirit
    local base, current, posBuff, negBuff = UnitStat("player", 5);
    SpiritLabelFrame.ValueFrame.Value:SetText(current);
    -- TODO: Mouseover stuff
end

function AnachronismStatsFrame_SetMelee()
end

function AnachronismStatsFrame_SetRanged()
end

function AnachronismStatsFrame_SetSpell()
end

function AnachronismStatsFrame_SetDefenses()
end
