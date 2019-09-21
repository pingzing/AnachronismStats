local DEFAULT_SUBFRAMES = { "PaperDollFrame", "PetPaperDollFrame", "ReputationFrame", "SkillFrame", "HonorFrame" };
local MAX_LEVEL = 60;
local CLASSES = { 
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

local base_OnClick = CharacterFrameTab_OnClick;
local base_ShowSubFrame = CharacterFrame_ShowSubFrame;

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

local function GetMp5FromSpirit(spirit, class)
    --Priests and mages: 13 + (spirit / 4) mana per tick
    if (class == CLASSES.Priest or class == CLASSES.Mage) then
        return (13 + (spirit / 4)) * 2.5; -- Multiplied by 2.5 as these values are per tick, and ticks are 2s each.
    --Druids, shamans, paladins, hunters: 15 + (spirit / 5) mana per tick
    elseif (class == CLASSES.Druid or class == CLASSES.Shaman or class == CLASSES.Paladin or class == CLASSES.Hunter) then
        return (15 + (spirit / 5)) * 2.5;
    --Warlocks: 8 + (spirit / 4) mana per tick
    elseif (class == CLASSES.Warlock) then
        return (8 + (spirit / 4)) * 2.5;
    else
        return 0;
    end
end

local function OffhandHasWeapon()
    local link = GetInventoryItemLink("player", 17);
    if (not(link)) then
        return false;
    end

    local _,_,_,_,itemType = GetItemInfo(link);
    return itemType=="Weapon";
end

local function GetPercentRegenWhileCasting(class)
    -- We need to check three possible talents:
    -- Meditation (Priest), Arcane Meditation (Mage), Reflection (Druid).
    -- There are a handful of talented short-term buffs we could check too, but ehhhhhh
    if (class == CLASSES.Priest) then
        -- check for ranks of Meditation
        local _, _, _, _, ranks, _, _, _ = GetTalentInfo(1, 8);
        return ranks * 5;
    elseif (class == CLASSES.Mage) then
        -- check for ranks of Arcane Meditation
        local _, _, _, _, ranks, _, _, _ = GetTalentInfo(1, 12);
        return ranks * 5;
    elseif (class == CLASSES.Druid) then
        -- check for ranks of Reflection
        local _, _, _, _, ranks, _, _, _ = GetTalentInfo(3, 6);
        return ranks * 5;
    end    

    return 0;
end

local function GetDefenseValues()
    
    -- UnitDefense("player") is broken, use the below instead
    local numSkills = GetNumSkillLines();
	local skillIndex = 0;

	for i = 1, numSkills do
		local skillName = select(1, GetSkillLineInfo(i));

		if (skillName == DEFENSE) then
			skillIndex = i;
			break;
		end
	end

	local skillRank, skillModifier;
	if (skillIndex > 0) then
		skillRank = select(4, GetSkillLineInfo(skillIndex));
		skillModifier = select(6, GetSkillLineInfo(skillIndex));
    end
    
    return skillRank, skillModifier;
end

local function GetStatValue(base, posBuff, negBuff)
    local effective = max(0,base + posBuff + negBuff);	
	if ( ( posBuff == 0 ) and ( negBuff == 0 ) ) then		
		return effective;
	else 
		-- if there is a negative buff then show the main number in red, even if there are
		-- positive buffs. Otherwise show the number in green
		if ( negBuff < 0 ) then
			return RED_FONT_COLOR_CODE..effective..FONT_COLOR_CODE_CLOSE;
		else
			return GREEN_FONT_COLOR_CODE..effective..FONT_COLOR_CODE_CLOSE;
		end
	end	
end

local function GetStatTooltipText(name, base, posBuff, negBuff)
	local effective = max(0,base + posBuff + negBuff);
	local tooltipRow1 = HIGHLIGHT_FONT_COLOR_CODE..name.." "..effective;
	if ( ( posBuff == 0 ) and ( negBuff == 0 ) ) then
		tooltipRow1 = tooltipRow1..FONT_COLOR_CODE_CLOSE;		
	else 
		if ( posBuff > 0 or negBuff < 0 ) then
			tooltipRow1 = tooltipRow1.." ("..base..FONT_COLOR_CODE_CLOSE;
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
    
    local tooltipRow2 = AS_GetStatTooltipDetailText(name, base, posBuff, negBuff);
	return tooltipRow1, tooltipRow2;
end

-- ///////////ATTRIBUTE SPECIFIC STUFF///////////

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
    if (classFileName == CLASSES.Warrior or classFileName == CLASSES.Paladin or classFileName == CLASSES.Shaman) then
        -- TODO Figure out if we need to subtract base strength from 'current' here.
        strengthDetailText = "Increases block value by "..floor(current / 20).."\n"; -- I hope this rounds down. Can stats go negative?
    end    
    -- Bears get 2 AP per strength, so check for "Druid && Bear" in addition to Warr or Pally.
    if (classFileName == CLASSES.Warrior or classFileName == CLASSES.Paladin or ( classFileName == CLASSES.Druid and stanceNum == 1 )) then
        strengthDetailText = strengthDetailText.."Increases melee attack power by ".. (current * 2).."\n";
        -- Everyone else gets 1 AP per Str.
    else
        strengthDetailText = strengthDetailText.."Increases melee attack power by ".. current.."\n";
    end

    return strtrim(strengthDetailText);
end

local function GetAgilityDetailText(base, current, posBuff, negBuff, playerLevel)
    local _, classFileName = UnitClass("player");
    local stanceNum = GetShapeshiftForm();
    local agiDetailText = "";    
    -- 1 AP for Rogues, Hunters, and Cat Druids
    if (classFileName == CLASSES.Rogue or classFileName == CLASSES.Hunter or ( classFileName == CLASSES.Druid and stanceNum == 3 ) ) then
        agiDetailText = "Increases melee attack power by "..current.."\n";
    end
    -- 2 RAP per Agi for hunters. 1 RAP per point for Warrs and Rogues.
    if (classFileName == CLASSES.Hunter) then
        agiDetailText = agiDetailText.. "Increases ranged attack power by ".. (current * 2).."\n";
    elseif (classFileName == CLASSES.Warrior or classFileName == CLASSES.Rogue) then
        agiDetailText = agiDetailText.. "Increases ranged attack power by "..current.."\n";
    end

    -- Crit chance
    -- The operative guess here is that the level coefficient is just (currLevel / maxLevel) * AGI_PER_CRIT (which is the level 60 value)
    -- That's almost certainly wrong, but it seems to be Good Enough(tm).
    local agiPerCrit = (playerLevel / MAX_LEVEL) * AGI_PER_CRIT[classFileName];
    agiDetailText = agiDetailText.."Increases melee and ranged crit chance by ~"..format("%.2F", (current / agiPerCrit)).."%\n";

    -- Ditto dodge chance.
    local agiPerDodge = (playerLevel / MAX_LEVEL) * AGI_PER_DODGE[classFileName];
    agiDetailText = agiDetailText.."Increases dodge chance by ~"..format("%.2F", (current / agiPerDodge)).."%\n";

    -- 2 Armor per Agi
    agiDetailText = agiDetailText.."Increases armor by "..(current * 2);

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
    return "Increases health by "..healthFromStam;
end

local function GetIntellectDetailText(base, current, posBuff, negBuff, playerLevel)
    local _, classFileName = UnitClass("player");
    -- We could be smart and check to see if the unit has mana, but... Druids. Just do the easy thing.
    if (classFileName == CLASSES.Rogue or classFileName == CLASSES.Warrior) then
        return "";
    end

    local intPerCrit = (playerLevel / MAX_LEVEL) * INT_PER_SPELLCRIT[classFileName];
    local intelDetailText = "Increases your maximum mana by "..floor(current * 15).."\n";
    intelDetailText = intelDetailText.."Increases your spell crit chance by ~"..format("%.2F", (current / intPerCrit)).."%";
    return strtrim(intelDetailText);
end

local function GetSpiritDetailText(base, current, posBuff, negBuff, playerLevel)
    local _, classFileName = UnitClass("player");
    if (classFileName == CLASSES.Rogue or classFileName == CLASSES.Warrior) then
        return "";
    end

    -- GetManaRegen("player") just returns regen at-the-moment, so we 
    -- have to calculate all this ourselves.
    local mp5FromSpirit = GetMp5FromSpirit(current, classFileName);
    local percentWhileCasting = GetPercentRegenWhileCasting(classFileName);
    local spiritDetailText = "Increases your mana regeneration by "..floor(mp5FromSpirit).." per 5 seconds while not casting\n";
    spiritDetailText = spiritDetailText.."Increases your mana regeneration by "..(floor(mp5FromSpirit * (percentWhileCasting / 100))).." per 5 seconds while casting";
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

local function GetAttributeTooltipText(tooltipText, stat, base, current, posBuff, negBuff, playerLevel)
    local tooltipRow1 = tooltipText;
    if ( ( posBuff == 0 ) and ( negBuff == 0 ) ) then
        tooltipRow1 = tooltipRow1..current..FONT_COLOR_CODE_CLOSE;        
    else 
        tooltipRow1 = tooltipRow1..current;
        if ( posBuff > 0 or negBuff < 0 ) then
            tooltipRow1 = tooltipRow1.." ("..(current - posBuff - negBuff)..FONT_COLOR_CODE_CLOSE;
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
    
    local tooltipRow2 = GetAttributeTooltipDetailText(stat, base, current, posBuff, negBuff, playerLevel);

    return tooltipRow1, tooltipRow2;
end

-- ///////////END ATTRIBUTE SPECIFIC STUFF///////////

-- ///////////MELEE SPECIFIC STUFF///////////

local function ShowMeleeTooltip(self)
    -- Main hand weapon
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetText(INVTYPE_WEAPONMAINHAND, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddDoubleLine(ATTACK_SPEED_COLON, format("%.2F", self.attackSpeed), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddDoubleLine(DAMAGE_COLON, self.damage, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	GameTooltip:AddDoubleLine(DAMAGE_PER_SECOND, format("%.1F", self.dps), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	-- Check for offhand weapon
	if ( self.offhandAttackSpeed ) then
		GameTooltip:AddLine(" "); -- Blank line.
		GameTooltip:AddLine(INVTYPE_WEAPONOFFHAND, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
		GameTooltip:AddDoubleLine(ATTACK_SPEED_COLON, format("%.2F", self.offhandAttackSpeed), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
		GameTooltip:AddDoubleLine(DAMAGE_COLON, self.offhandDamage, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
		GameTooltip:AddDoubleLine(DAMAGE_PER_SECOND, format("%.1F", self.offhandDps), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	end
	GameTooltip:Show();
end

local function FillOutMeleeDamageFrame(frame)
    local speed, offhandSpeed = UnitAttackSpeed("player");
	local minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, physicalBonusPos, physicalBonusNeg, percent = UnitDamage("player");
	local displayMin = max(floor(minDamage),1);
	local displayMax = max(ceil(maxDamage),1);

	minDamage = (minDamage / percent) - physicalBonusPos - physicalBonusNeg;
	maxDamage = (maxDamage / percent) - physicalBonusPos - physicalBonusNeg;

	local baseDamage = (minDamage + maxDamage) * 0.5;
	local fullDamage = (baseDamage + physicalBonusPos + physicalBonusNeg) * percent;
	local totalBonus = (fullDamage - baseDamage);
	local damagePerSecond = (max(fullDamage,1) / speed);
	local damageTooltip = max(floor(minDamage),1).." - "..max(ceil(maxDamage),1);
	
	local colorPos = "|cff20ff20";
	local colorNeg = "|cffff2020";
	if ( totalBonus == 0 ) then
		if ( ( displayMin < 100 ) and ( displayMax < 100 ) ) then 
			frame.ValueFrame.Value:SetText(displayMin.." - "..displayMax);	
		else
			frame.ValueFrame.Value:SetText(displayMin.."-"..displayMax);
		end
	else
		
		local color;
		if ( totalBonus > 0 ) then
			color = colorPos;
		else
			color = colorNeg;
		end
		if ( ( displayMin < 100 ) and ( displayMax < 100 ) ) then 
			frame.ValueFrame.Value:SetText(color..displayMin.." - "..displayMax.."|r");	
		else
			frame.ValueFrame.Value:SetText(color..displayMin.."-"..displayMax.."|r");
		end
		if ( physicalBonusPos > 0 ) then
			damageTooltip = damageTooltip..colorPos.." +"..physicalBonusPos.."|r";
		end
		if ( physicalBonusNeg < 0 ) then
			damageTooltip = damageTooltip..colorNeg.." "..physicalBonusNeg.."|r";
		end
		if ( percent > 1 ) then
			damageTooltip = damageTooltip..colorPos.." x"..floor(percent*100+0.5).."%|r";
		elseif ( percent < 1 ) then
			damageTooltip = damageTooltip..colorNeg.." x"..floor(percent*100+0.5).."%|r";
		end
		
	end
	frame.damage = damageTooltip;
	frame.attackSpeed = speed;
	frame.dps = damagePerSecond;
	
	-- If there's an offhand speed then add the offhand info to the tooltip
	if ( offhandSpeed ) then
		minOffHandDamage = (minOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg;
		maxOffHandDamage = (maxOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg;

		local offhandBaseDamage = (minOffHandDamage + maxOffHandDamage) * 0.5;
		local offhandFullDamage = (offhandBaseDamage + physicalBonusPos + physicalBonusNeg) * percent;
		local offhandDamagePerSecond = (max(offhandFullDamage,1) / offhandSpeed);
		local offhandDamageTooltip = max(floor(minOffHandDamage),1).." - "..max(ceil(maxOffHandDamage),1);
		if ( physicalBonusPos > 0 ) then
			offhandDamageTooltip = offhandDamageTooltip..colorPos.." +"..physicalBonusPos.."|r";
		end
		if ( physicalBonusNeg < 0 ) then
			offhandDamageTooltip = offhandDamageTooltip..colorNeg.." "..physicalBonusNeg.."|r";
		end
		if ( percent > 1 ) then
			offhandDamageTooltip = offhandDamageTooltip..colorPos.." x"..floor(percent*100+0.5).."%|r";
		elseif ( percent < 1 ) then
			offhandDamageTooltip = offhandDamageTooltip..colorNeg.." x"..floor(percent*100+0.5).."%|r";
		end
		frame.offhandDamage = offhandDamageTooltip;
		frame.offhandAttackSpeed = offhandSpeed;
		frame.offhandDps = offhandDamagePerSecond;
	else
		frame.offhandAttackSpeed = nil;
    end

    return frame;
end

local function GetWeaponSkillDetails(mainBase, mainMod, hasOffhand, offBase, offMod, playerLevel)
    local wepSkillText;
    local wepSkillTooltipRow1;
    local wepSkillTooltipRow2;

    wepSkillText = GetStatValue(mainBase, mainMod, 0);
    if (hasOffhand) then
        wepSkillText = wepSkillText.." / "..GetStatValue(offBase, offMod, 0);
    end    
        
    local wepSkillHeader, _ = GetStatTooltipText("Weapon Skill (Main)", mainBase, mainMod, 0);
    if (hasOffhand) then
        wepSkillHeader = wepSkillHeader.."\n"..GetStatTooltipText("Weapon Skill (Off)", offBase, offMod, 0);
    end
    wepSkillTooltipRow1 = wepSkillHeader;

    local maxSkillForLevel = playerLevel * 5;
    -- These might be negative.
    local bonusSkillMain = mainBase - maxSkillForLevel;
    local bonusSkillOff = offBase - maxSkillForLevel;

    local mainPercentBonus = format("%.2F", bonusSkillMain * .04).."%";
    local offPercentBonus = format("%.2F", bonusSkillOff * 0.4).."%";
    wepSkillTooltipRow2 = "Increases your chance to hit and crit, and reduce chance to be blocked, dodged or parried by "..mainPercentBonus;
    if (hasOffhand) then
        wepSkillTooltipRow2 = wepSkillTooltipRow2.." / "..offPercentBonus;
    end
    wepSkillTooltipRow2 = wepSkillTooltipRow2.." by a level "..playerLevel.." enemy";
    wepSkillTooltipRow2 = wepSkillTooltipRow2.."\nAlso reduces Glancing Blow damage penalty against higher-level enemies by "..(max(0, bonusSkillMain * 3)).."%";
    if (hasOffhand) then
        wepSkillTooltipRow2 = wepSkillTooltipRow2.." / "..(max(0, bonusSkillOff * 3)).."%";
    end

    return wepSkillText, wepSkillTooltipRow1, wepSkillTooltipRow2;
end

-- ///////////END MELEE SPECIFIC STUFF///////////

-- ///////////SPELL SPECIFIC STUFF///////////
local SPELL_SCHOOL_NAMES = {
    [1] = "Normal",
    [2] = "Holy",
    [3] = "Fire",
    [4] = "Nature",
    [5] = "Frost",
    [6] = "Shadow",
    [7] = "Arcane",
};

local function SpellSpellDamageTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");    
    GameTooltip:SetText("Bonus Damage "..self.normalSpellDamage, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddLine(" "); -- Blank line.
    for i=2,7 do        
        local schoolDamage = GetSpellBonusDamage(i);
        GameTooltip:AddDoubleLine(SPELL_SCHOOL_NAMES[i], schoolDamage, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    end    
    GameTooltip:Show();
end

local function SpellSpellCritTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");    
    GameTooltip:SetText("Spell Crit Chance "..self.normalSpellCritPercent.."%", HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddLine(" "); -- Blank line.
    for i=2,7 do        
        local schoolCrit = GetSpellCritChance(i);
        GameTooltip:AddDoubleLine(SPELL_SCHOOL_NAMES[i], format("%.2F", schoolCrit).."%", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    end    
    GameTooltip:Show();
end

-- ///////////END SPELL SPECIFIC STUFF///////////

-- ///////////DEFENSES SPECIFIC STUFF HERE///////////

local function GetArmorDetailText(base, posBuff, negBuff)
    local playerLevel = UnitLevel("player");
    local effectiveArmor = base + posBuff + negBuff;
    -- Some serious magic, taken straight form Blizzard's PaperDoll code
    local armorReduction = effectiveArmor/((85 * playerLevel) + 400);
	armorReduction = 100 * (armorReduction/(armorReduction + 1));
    return "Reduces physical damage taken from level "..playerLevel.. " enemies by "..format("%.2F", armorReduction).."%";
end

local function GetDefenseDetailText(base, posBuff, negBuff)
    local playerLevel = UnitLevel("player");
    local effectiveDefense = base + posBuff + negBuff;
    
    local maxSkillForLevel = playerLevel * 5;
    local bonusSkill = effectiveDefense - maxSkillForLevel;
    local percentBonusText = format("%.2F", bonusSkill * .04).."%";
    local detailText = "Reduces your chance to be hit or crit, and increases your chance to block, dodge, and parry by "..percentBonusText.." againt a "..playerLevel.. " enemy";

    local dazeReductionText = format("%.2F", bonusSkill * .16); -- Not certain about this value.
    detailText = detailText.."\nIn addition, reduces your chance to be dazed by "..dazeReductionText;
    return detailText;
end

-- ///////////END DEFENSES SPECIFIC STUFF///////////

function CharacterFrameTab6_OnLoad(self)        
    -- Make sure the CharacterFrame iterates through our Frame when doing Tab stuff
    PanelTemplates_SetNumTabs(CharacterFrame, CharacterFrame.numTabs + 1);    

    -- Hook Tab_OnClick so we can listen for our tab button being clicked.
    CharacterFrameTab_OnClick = function(self, button)
        local name = self:GetName();
        if ( name == "CharacterFrameTab6" ) then
            ShowAnachronismStatsFrame();
        end
    
        base_OnClick(self, button);
    end
end

function CharacterFrameTab6_OnHide(self)
    -- Make sure we're not sitting in the background if this tab has focus
    -- when the character frame is closed.
    AnachronismStatsFrame:Hide();
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
    self:RegisterEvent("UPDATE_SHAPESHIFT_FORMS");
    
    -- Queue one initial update
    self:SetScript("OnUpdate", AnachronismStatsFrame_QueuedUpdate);

    -- Hook ShowSubFrame so that we get closed if any other frame gets opened.
    CharacterFrame_ShowSubFrame = function(frameName)        
        if (frameName ~= AnachronismStatsFrame) then
            AnachronismStatsFrame:Hide();
        end
        base_ShowSubFrame(frameName);
    end
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
    local playerLevel = UnitLevel("player");
    AnachronismStatsFrame_SetAttributes(playerLevel);
    AnachronismStatsFrame_SetMelee(playerLevel);
    AnachronismStatsFrame_SetRanged(playerLevel);
    AnachronismStatsFrame_SetSpell(playerLevel);
    AnachronismStatsFrame_SetDefenses(playerLevel);
end

function AnachronismStatsFrame_SetAttributes(playerLevel)
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

        frame.tooltipRow1, frame.tooltipRow2 = GetAttributeTooltipText(HIGHLIGHT_FONT_COLOR_CODE.._G["SPELL_STAT"..i.."_NAME"].." ", frame.stat, base, current, posBuff, negBuff, playerLevel);        
    end
end

function AnachronismStatsFrame_SetMelee(playerLevel)    
    -- Damage.
    local damageFrame = AS_MeleeLabelFrame1;
    damageFrame = FillOutMeleeDamageFrame(damageFrame);
    damageFrame.tooltipSpecialCase = ShowMeleeTooltip;

    -- Speed
    local speedFrame = AS_MeleeLabelFrame2;
    local mainSpeed, offSpeed = UnitAttackSpeed("player");
    local hastePercent = GetMeleeHaste();
    local speedText = format("%.2F", mainSpeed);
    if (offSpeed) then
        local offspeedText = format("%.2F", offSpeed);
        speedText = speedText.." / "..offspeedText;
    end
    if (hastePercent == 0) then
        speedFrame.ValueFrame.Value:SetText(speedText);
    elseif (hastePercent > 0) then
        speedText = GREEN_FONT_COLOR_CODE..speedText..FONT_COLOR_CODE_CLOSE;
    elseif (hastePercent < 0) then
        speedText = RED_FONT_COLOR_CODE..speedText..FONT_COLOR_CODE_CLOSE;
    end
    speedFrame.ValueFrame.Value:SetText(speedText);
    speedFrame.tooltipRow1 = "Attack Speed "..speedText;
    speedFrame.tooltipRow2 = "Haste: "..format("%.2F", hastePercent).."%";

    -- Attack Power
    local apFrame = AS_MeleeLabelFrame3;
    local base, posBuff, negBuff = UnitAttackPower("player");
    apFrame.ValueFrame.Value:SetText(GetStatValue(base, posBuff, negBuff));
    apFrame.tooltipRow1, apFrame.tooltipRow2 = GetStatTooltipText(apFrame.name, base, posBuff, negBuff);

    -- Hit Chance
    local hitFrame = AS_MeleeLabelFrame4;
    local hitFromGear = GetHitModifier();
    -- TODO: Get hit from talents (and Defense skill?) too
    hitFrame.ValueFrame.Value:SetText(hitFromGear.."%");
    hitFrame.tooltipRow1 = "Hit Chance "..hitFromGear.."%";
    hitFrame.tooltipRow2 = "Increases your melee chance to hit a target of level "..playerLevel.." by "..hitFromGear.."%";

    -- Crit chance
    local critFrame = AS_MeleeLabelFrame5;
    local critChance = GetCritChance();
    local critText = format("%.2F", critChance).."%";
    critFrame.ValueFrame.Value:SetText(critText);
    critFrame.tooltipRow1 = "Critical Hit Chance "..critText;
    critFrame.tooltipRow2 = "Increases your melee chance to crit a target of level "..playerLevel.." by "..critText;

    -- Weapon skill
    local wepSkillFrame = AS_MeleeLabelFrame6;
    local mainBase, mainMod, offBase, offMod = UnitAttackBothHands("player");
    local hasOffhand = OffhandHasWeapon();
    local wepSkillText, wepSkillTooltipRow1, wepSkillTooltipRow2 = GetWeaponSkillDetails(mainBase, mainMod, hassOffhand, offBase, offMod, playerLevel);
    wepSkillFrame.ValueFrame.Value:SetText(wepSkillText);
    wepSkillFrame.tooltipRow1 = wepSkillTooltipRow1;
    wepSkillFrame.tooltipRow2 = wepSkillTooltipRow2;
end

function AnachronismStatsFrame_SetRanged(playerLevel)
end

function AnachronismStatsFrame_SetSpell(playerLevel)
    -- Damage
    local spellDamageFrame = AS_SpellLabelFrame1;
    local normalSpellDamage = GetSpellBonusDamage(1);
    spellDamageFrame.normalSpellDamage = normalSpellDamage;
    spellDamageFrame.ValueFrame.Value:SetText(normalSpellDamage);
    spellDamageFrame.tooltipSpecialCase = SpellSpellDamageTooltip;

    -- Healing
    local healingFrame = AS_SpellLabelFrame2;
    local bonusHealing = GetSpellBonusHealing();
    healingFrame.ValueFrame.Value:SetText(bonusHealing);
    healingFrame.tooltipRow1 = "Bonus Healing "..bonusHealing
    healingFrame.tooltipRow2 = "Increase your healing by up to "..bonusHealing;

    -- Spell Hit
    local spellHitFrame = AS_SpellLabelFrame3;
    local spellHitPercent = GetSpellHitModifier();
    spellHitFrame.ValueFrame.Value:SetText(spellHitPercent.."%");
    spellHitFrame.tooltipRow1 = "Spell Hit Chance "..spellHitPercent.."%";
    spellHitFrame.tooltipRow2 = "Increases your chance to hit a level "..playerLevel.." target with spells by "..spellHitPercent.."%";

    -- Spell Crit
    local spellCritFrame = AS_SpellLabelFrame4;
    local normalSpellCritPercent = format("%.2F", GetSpellCritChance(1));
    spellCritFrame.normalSpellCritPercent = normalSpellCritPercent;
    spellCritFrame.ValueFrame.Value:SetText(normalSpellCritPercent.."%");
    spellCritFrame.tooltipSpecialCase = SpellSpellCritTooltip;

    -- Mana regen
    local manaRegenFrame = AS_SpellLabelFrame5;
    local _, classFileName = UnitClass("player");
    if (classFileName == CLASSES.Rogue or classFileName == CLASSES.Warrior) then
        manaRegenFrame.ValueFrame.Value:SetText("-");
        manaRegenFrame.tooltipRow1 = "Mana Regeneration 0";
        manaRegenFrame.tooltipRow2 = "You have no mana. Why are you here?";
    else
        -- GetManaRegen("player") just returns regen at-the-moment, so we 
        -- have to calculate all this ourselves.
        -- Possible TODO: Somehow calculate all other sources of MP5. How? Manual list of whitelisted buff IDs?
        local _, spirit, _, _ = UnitStat("player", 5);
        local mp5FromSpirit = floor(GetMp5FromSpirit(spirit, classFileName));
        local percentWhileCasting = GetPercentRegenWhileCasting(classFileName);
        manaRegenFrame.ValueFrame.Value:SetText(mp5FromSpirit);
        manaRegenFrame.tooltipRow1 = "Mana Regeneration "..mp5FromSpirit;
        manaRegenFrame.tooltipRow2 = mp5FromSpirit.." mana regenerated every 5 seconds while not casting\n"..(floor(mp5FromSpirit * (percentWhileCasting / 100))).." mana regenerated every 5 seconds while casting\n*Note this does not account for MP/5 buffs";
    end
end

function AnachronismStatsFrame_SetDefenses(playerLevel)

    -- Armor
    local armorFrame = AS_DefensesLabelFrame1;
    local base, effectiveArmor, armor, posBuff, negBuff = UnitArmor("player");
    local armorText = GetStatValue(base, posBuff, negBuff);
    armorFrame.ValueFrame.Value:SetText(armorText);
    armorFrame.tooltipRow1, armorFrame.tooltipRow2  = GetStatTooltipText(armorFrame.name, base, posBuff, negBuff);

    -- Defense
    local defenseFrame = AS_DefensesLabelFrame2;
    local defenseValue, defenseModifier = GetDefenseValues();
    local defenseText = GetStatValue(defenseValue, defenseModifier, 0);
    defenseFrame.ValueFrame.Value:SetText(defenseText);
    defenseFrame.tooltipRow1, defenseFrame.tooltipRow2 = GetStatTooltipText(defenseFrame.name, defenseValue, defenseModifier, 0);

    -- Block
    local blockFrame = AS_DefensesLabelFrame3;
    local blockChance = GetBlockChance();
    local blockChanceText = format("%.2F", blockChance).."%";
    local blockValue = GetShieldBlock();
    blockFrame.ValueFrame.Value:SetText(blockChanceText);
    blockFrame.tooltipRow1 = "Block Chance "..blockChanceText;
    blockFrame.tooltipRow2 = "Increases your chance to block "..blockValue.." damage by "..blockChanceText.." against level "..playerLevel.." targets";

    -- Dodge
    local dodgeFrame = AS_DefensesLabelFrame4;
    local dodgeChance = GetDodgeChance();
    local dodgeChanceText = format("%.2F", dodgeChance).."%";
    dodgeFrame.ValueFrame.Value:SetText(dodgeChanceText);
    dodgeFrame.tooltipRow1 = "Dodge Chance "..dodgeChanceText;
    dodgeFrame.tooltipRow2 = "Increases your chance to dodge by "..dodgeChanceText.." against level "..playerLevel.." targets";

    -- Parry
    local parryFrame = AS_DefensesLabelFrame5;
    local parryChance = GetParryChance();
    local parryChanceText = format("%.2F", parryChance).."%";
    parryFrame.ValueFrame.Value:SetText(parryChanceText);
    parryFrame.tooltipRow1 = "Parry Chance "..parryChanceText;
    parryFrame.tooltipRow2 = "Increases your chance to parry by "..parryChanceText.." against level "..playerLevel.." targets";

end

function AS_ShowStatTooltip(self)
    if (not (self.tooltipRow1) and not(self.tooltipSpecialCase)) then
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

function AS_GetStatTooltipDetailText(name, base, posBuff, negBuff)
    if (name == "Attack Power") then
        return "Increases your damage with melee weapons by "..format("%.1F", ((base + posBuff + negBuff) / 14)).." damage per second";
    elseif (name == "Armor") then
        return GetArmorDetailText(base, posBuff, negBuff);
    elseif (name == "Defense") then
        return GetDefenseDetailText(base, posBuff, negBuff);
    end
end
