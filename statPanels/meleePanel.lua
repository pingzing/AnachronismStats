local addonName, AS = ... -- Get addon name and shared table.
AnachronismStats = AS -- Globalized, so XML can see it

local function OffhandHasWeapon()
    local link = GetInventoryItemLink("player", 17);
    if (not(link)) then
        return false;
    end

    local _,_,_,_,itemType = GetItemInfo(link);
    return itemType=="Weapon";
end

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

    wepSkillText = AS.GetStatValue(mainBase, mainMod, 0);
    if (hasOffhand) then
        wepSkillText = wepSkillText.." / "..AS.GetStatValue(offBase, offMod, 0);
    end    
        
    local wepSkillHeader, _ = AS.GetStatTooltipText("Weapon Skill (Main)", mainBase, mainMod, 0);
    if (hasOffhand) then
        wepSkillHeader = wepSkillHeader.."\n"..AS.GetStatTooltipText("Weapon Skill (Off)", offBase, offMod, 0);
    end
    wepSkillTooltipRow1 = wepSkillHeader;

    local maxSkillForLevel = playerLevel * 5;
    -- These might be negative.
    local bonusSkillMain = mainBase - maxSkillForLevel;
    local bonusSkillOff = offBase - maxSkillForLevel;

    local mainPercentBonus = format("%.2F", max(0, bonusSkillMain * .04)).."%";
    local offPercentBonus = format("%.2F", max(0, bonusSkillOff * .04)).."%";
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

function AnachronismStats_MeleePanel_OnLoad(self)
    local containerFrame = AS.ContainerFrame;
    self:SetParent(containerFrame);
end

function AS.Frame_SetMelee(playerLevel)    
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
    apFrame.ValueFrame.Value:SetText(AS.GetStatValue(base, posBuff, negBuff));
    apFrame.tooltipRow1, apFrame.tooltipRow2 = AS.GetStatTooltipText(apFrame.name, base, posBuff, negBuff);

    -- Hit Chance
    local hitFrame = AS_MeleeLabelFrame4;
    local hitFromGear = GetHitModifier();
    -- TODO: Get hit from talents and weapon skill, and show main/off in tooltip and ValueFrame.
    hitFrame.ValueFrame.Value:SetText(hitFromGear.."%");
    hitFrame.tooltipRow1 = "Hit Chance "..hitFromGear.."%";
    hitFrame.tooltipRow2 = "Increases your melee chance to hit a target of level "..playerLevel.." by "..hitFromGear.."%";

    -- Crit chance
    local critFrame = AS_MeleeLabelFrame5;
    local critChance = GetCritChance();
    -- TODO: Get crit from weapon skill. Change ValueFrame and tooltip to show main/off.
    -- ALSO TODO: Get crit for per-weapon talents. Lotta AS.CLASSES have those.
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