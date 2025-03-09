local addonName, AS = ... -- Get addon name and shared table.
AnachronismStats = AS -- Globalized, so XML can see it

local function OnUpArrow_Click()
    AS.StatPanel_UpArrow_OnClick(AS_SpellContainerFrame);
end

local function OnDownArrow_Click()
    AS.StatPanel_DownArrow_OnClick(AS_SpellContainerFrame);
end

function AnachronismStats_SpellPanel_OnLoad(self)
    local containerFrame = AS.ContainerFrame;
    self:SetParent(containerFrame);

    AS_SpellHeaderFrame.UpArrow:SetScript("OnClick", OnUpArrow_Click);
    AS_SpellHeaderFrame.DownArrow:SetScript("OnClick", OnDownArrow_Click);
end

function AS.Frame_SetSpell(playerLevel)
    -- Damage
    local spellDamageFrame = AS_SpellLabelFrame1;
    local highestSpellDamage = 0;
    for i = 2, 7 do
        local schoolDamage = GetSpellBonusDamage(i);
        if (schoolDamage > highestSpellDamage) then
            highestSpellDamage = schoolDamage;
        end
    end
    AS.Ratings.SetSpellDamageFrame(highestSpellDamage, spellDamageFrame);

    -- Healing
    local healingFrame = AS_SpellLabelFrame2;
    local bonusHealing = GetSpellBonusHealing();
    AS.Ratings.SetSpellHealingFrame(bonusHealing, healingFrame);

    -- Spell Haste
    local spellHasteFrame = AS_SpellLabelFrame3;
    local spellHastePercent = UnitSpellHaste("player");
    AS.Ratings.SetSpellHasteFrame(spellHastePercent, spellHasteFrame);

    -- Spell Hit
    local spellHitFrame = AS_SpellLabelFrame4;
    local baseSpellHitPercent = GetSpellHitModifier();
    AS.Ratings.SetSpellHitFrame(baseSpellHitPercent, playerLevel, spellHitFrame);

    -- Spell Crit
    local spellCritFrame = AS_SpellLabelFrame5;
    local normalSpellCritPercent = format("%.2F", GetSpellCritChance(1));
    spellCritFrame.normalSpellCritPercent = normalSpellCritPercent;
    AS.Ratings.SetSpellCritFrame(normalSpellCritPercent, spellCritFrame);

    -- Mana regen    
    local manaRegenFrame = AS_SpellLabelFrame6;
    local _, classFileName = UnitClass("player");
    AS.Ratings.SetManaRegenFrame(classFileName, manaRegenFrame);
end

function AS.GetSpellPanel()
    return AS_SpellContainerFrame;
end
