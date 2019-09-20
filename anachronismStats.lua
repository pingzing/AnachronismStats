local DEFAULT_SUBFRAMES = { "PaperDollFrame", "PetPaperDollFrame", "ReputationFrame", "SkillFrame", "HonorFrame" };
local base_OnClick = CharacterFrameTab_OnClick;

local function cPrint(text)
    DEFAULT_CHAT_FRAME:AddMessage(text);
end

local function ShowAnachronismStatsFrame()
    -- Hide all other frames...
    for _, value in pairs(DEFAULT_SUBFRAMES) do
        _G[value]:Hide();
    end    
    
    -- ...and show ours.
    AnachronismStatsFrame:Show();
end

local function GetStrengthDetailText(base, current, posBuff, negBuff)
    -- Todo: If Warrior, Paladin or Shaman, get block value (Str / 20 (minus base str?))
    -- If Warrior or Paladin (or Bear druid?), Get Str * 2 for AP
    -- Else, get Str * 1 for AP
end

local function GetAgilityDetailText(base, current, posBuff, negBuff)
    -- Todo: 1 AP for Rogues, Cat? Druids, Hunters
    -- 2 Armor per Agi
    -- 2 RAP per Agi for hunters. 1 RAP per point for Warrs and Rogues.
    -- Crit chance (little different for everyone)
    -- Dodge chance (ditto)
end

local function GetStaminaDetailText(base, current, posBuff, negBuff)
    -- Value * 10. (Unless Tauren, then value * 10.5)    
    -- The first 20 points of Stamina grants only 1 health point.
end

local function GetIntellectDetailText(base, current, posBuff, negBuff)
    -- Value * 15 for Mana
    -- Spellcrit (different for everyone) (per-level?)
end

local function GetSpiritDetailText(base, current, posBuff, negBuff)
    -- MP5 while casting (account for things like Meditation) (per-level?)
    -- MP5 while not casting (per-level?)
    -- HP5 while not in combat (per-level?)
end

local function GetTooltipDetailText(stat, base, current, posBuff, negBuff)
    if (stat == "STRENGTH") then
        return GetStrengthDetailText(base, current, posBuff, negBuff);
    elseif (stat == "AGILITY") then
        return GetAgilityDetailText(base, current, posBuff, negBuff);
    elseif (stat == "STAMINA") then
        return GetStaminaDetailText(base, current, posBuff, negBuff);
    elseif (stat == "INTELLECT") then
        return GetIntellectDetailText(base, current, posBuff, negBuff);
    elseif (stat == "SPIRIT") then
        return GetSpiritDetailText(base, current, posBuff, negBuff);
    end
end

local function GetTooltipText(tooltipText, stat, base, current, posBuff, negBuff)
    local tooltipRow1 = tooltipText;
    if ( ( posBuff == 0 ) and ( negBuff == 0 ) ) then
        tooltipRow1 = tooltipRow1..current..FONT_COLOR_CODE_CLOSE;        
    else 
        tooltipRow1 = tooltipRow1..current;
        if ( posBuff > 0 or negBuff < 0 ) then
            tooltipRow1 = tooltipRow1.." ("..(stat - posBuff - negBuff)..FONT_COLOR_CODE_CLOSE;
        end
        if ( posBuff > 0 ) then
            tooltipRow1 = tooltipRow1..FONT_COLOR_CODE_CLOSE..GREEN_FONT_COLOR_CODE.."+"..posBuff..FONT_COLOR_CODE_CLOSE;
        end
        if ( negBuff < 0 ) then
            tooltipRow1 = tooltipRow1..RED_FONT_COLOR_CODE.." "..negBuff..FONT_COLOR_CODE_CLOSE;
        end
        if ( posBuff > 0 or negBuff < 0 ) then
            tooltipRow1 = tooltipRow1..HIGHLIGHT_FONT_COLOR_CODE..")"..FONT_COLOR_CODE_CLOSE;
        end        
    end  

    local tooltipRow2 = GetTooltipDetailText(stat, base, current, posBuff, negBuff);

    return tooltipRow1, tooltipRow2;
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
    for i=1, 5 do
        local base, current, posBuff, negBuff = UnitStat("player", i);
        local frame = _G["AS_AttributeLabelFrame"..i];

        -- Color values in white if there are no bonuses. Green if there are any. Red if there are any debuffs.
        if ( ( posBuff == 0 ) and ( negBuff == 0 ) ) then
            frame.ValueFrame.Value:SetText(current);
        elseif ( negBuff < 0 ) then
            frame.ValueFrame.Value:SetText(RED_FONT_COLOR_CODE..current..FONT_COLOR_CODE_CLOSE);
        else
            frame.ValueFrame.Value:SetText(GREEN_FONT_COLOR_CODE..current..FONT_COLOR_CODE_CLOSE);
        end

        frame.tooltipRow1, frame.tooltipRow2 = GetTooltipText(HIGHLIGHT_FONT_COLOR_CODE.._G["SPELL_STAT"..i.."_NAME"].." ", frame.stat, base, current, posBuff, negBuff);        
    end
end

function AnachronismStatsFrame_SetMelee()
end

function AnachronismStatsFrame_SetRanged()
end

function AnachronismStatsFrame_SetSpell()
end

function AnachronismStatsFrame_SetDefenses()
end

function AS_ShowStatTooltip(self)
    if (not (self.tooltip)) then
        return;
    end

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(self.tooltip, 1.0, 1.0, 1.0);
    GameTooltip:Show();
end
