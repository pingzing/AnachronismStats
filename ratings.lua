local addonName, AS = ...; -- Get addon name and shared table.

-- Ratings
-- Shared Helper functions for dealing with various stat and rating calculations

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

AS.SPELL_SCHOOL_NAMES = {
    [1] = "Physical",
    [2] = "Holy",
    [3] = "Fire",
    [4] = "Nature",
    [5] = "Frost",
    [6] = "Shadow",
    [7] = "Arcane",
};