local _, ns = ...

-- Feats: SkinDeep's own achievements, and the unlocks they give.
--
-- At first login the player picks how skins are had (Onboarding.lua):
--   "collector": start with Classic+, Auto and your class's skin; earn the
--                rest through feats.
--   "all":       everything unlocked; feats still track and pop for fun.
-- Until a choice is made everything stays unlocked, so nobody loses a skin
-- to a window they closed. Unlocks and progress are account-wide (one
-- SkinDeepDB for every character).
--
-- What the client lets addons see shapes every feat: hits and crits on your
-- target and enemy nameplates (UNIT_COMBAT; amounts are secret, so no feat
-- depends on how big a hit was), kills of mobs you hit (by name or creature
-- type), boss kills (ENCOUNTER_END / BOSS_KILL), levels and gold. In a party
-- your target's hits include your party's, as with the numbers themselves.
-- Names and creature types are matched in English.

local Feats = {}
ns.Feats = Feats

local min, max, floor, tinsert = math.min, math.max, math.floor, table.insert
local GOLD = 10000 -- copper
local STARTER = { classic = true, [ns.AUTO or "auto"] = true }

local CLASS_NAMES = {
    WARRIOR = "Warrior", PALADIN = "Paladin", HUNTER = "Hunter", ROGUE = "Rogue", PRIEST = "Priest",
    SHAMAN = "Shaman", MAGE = "Mage", WARLOCK = "Warlock", DRUID = "Druid",
}
local function className(token)
    local names = LOCALIZED_CLASS_NAMES_MALE
    return (names and names[token]) or CLASS_NAMES[token] or token
end
Feats.ClassName = className

---------------------------------------------------------------------------
-- The feats. counter + goal: a running count; classLevel: a level reached
-- on a character of that class; boss: any of these kills completes it too.
-- skin: what it unlocks (flavor feats' skins arrive in a later update and
-- are counted already, so progress isn't lost).
---------------------------------------------------------------------------
local LIST = {
    { id = "ember",   skin = "ember",   text = "Deal Fire damage 500 times",   counter = "fire",   goal = 500 },
    { id = "frost",   skin = "frost",   text = "Deal Frost damage 500 times",  counter = "frost",  goal = 500 },
    { id = "arcane",  skin = "arcane",  text = "Deal Arcane damage 500 times", counter = "arcane", goal = 500 },
    { id = "comic",   skin = "comic",   text = "Land 250 critical hits",       counter = "crits",  goal = 250 },
    { id = "arcade",  skin = "arcade",  text = "Land 1,000 hits",              counter = "hits",   goal = 1000 },
    { id = "blade",   skin = "blade",   text = "Land 2,500 hits",              counter = "hits",   goal = 2500 },
    { id = "gilded",  skin = "gilded",  text = "Earn 100 gold",                counter = "gold",   goal = 100 * GOLD, money = true },
    { id = "blood",   skin = "blood",   text = "Reach level 20 on any character", counter = "maxLevel", goal = 20 },
    { id = "jackpot", skin = "jackpot", text = "Land 777 critical hits",       counter = "crits",  goal = 777 },
}

-- Race skins (RaceSkins.lua): level 10 on a character of that race, the
-- best level seen per race (UnitRace's English token).
local RACES = { { "Human", "a Human" }, { "Dwarf", "a Dwarf" }, { "NightElf", "a Night Elf" }, { "Gnome", "a Gnome" },
                { "Orc", "an Orc" }, { "Scourge", "an Undead" }, { "Tauren", "a Tauren" }, { "Troll", "a Troll" } }
Feats.RACES = RACES
for _, id in ipairs(ns.SkinOrder) do
    local race = ns.Skins[id].race
    if race then
        local who
        for _, r in ipairs(RACES) do if r[1] == race then who = r[2] end end
        LIST[#LIST + 1] = { id = "race_" .. id, skin = id, counter = "race" .. race, goal = 10, raceLevel = true,
                            text = ("Reach level 10 on %s character"):format(who or race) }
    end
end

for _, token in ipairs({ "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }) do
    local skinId = token:lower()
    LIST[#LIST + 1] = { id = "class_" .. skinId, skin = skinId, classLevel = token, goal = 10,
                        text = "Reach level 10 on a " .. className(token) }
end

-- Faction feats. A feat only shows, completes and pops once its skin
-- exists (see Feats.Available); until then its counters still run, so
-- progress made beforehand counts when the skin is added.
local FLAVOR = {
    { id = "scarlet",  title = "Crimson Oath", faction = "Scarlet Crusade", color = { 0.92, 0.14, 0.14 },
      text = "Slay 100 Scarlet Crusade or defeat Whitemane",
      counter = "scarlet", goal = 100, boss = { "High Inquisitor Whitemane" } },
    { id = "scourge",  title = "Plague Tide", faction = "Scourge", color = { 0.55, 1, 0.35 },
      text = "Slay 250 Undead or defeat Baron Rivendare",
      counter = "undead", goal = 250, boss = { "Baron Rivendare" } },
    { id = "defias",   title = "Red Kerchief", faction = "Defias Brotherhood", color = { 0.88, 0.25, 0.18 },
      text = "Defeat Edwin VanCleef", boss = { "Edwin VanCleef" } },
    { id = "darkiron", title = "Molten Anvil", faction = "Dark Iron", color = { 1, 0.55, 0.2 },
      text = "Slay 100 Dark Iron or defeat Emperor Thaurissan",
      counter = "darkiron", goal = 100, boss = { "Emperor Dagran Thaurissan" } },
    { id = "brood",    title = "Broodmother", faction = "Black Dragonflight", color = { 0.7, 0.45, 1 },
      text = "Defeat Onyxia", boss = { "Onyxia" } },
    { id = "argent",   title = "Silver Dawn", faction = "Argent Dawn", color = { 0.62, 0.88, 1 },
      text = "Defeat Darkmaster Gandling", boss = { "Darkmaster Gandling" } },
}
for _, f in ipairs(FLAVOR) do
    f.flavor = true
    f.skin = f.skin or f.id   -- the skin with this id
    LIST[#LIST + 1] = f
end

-- PvP. Ranks follow Forever's own PvP rank (the Player vs. Player window's
-- Civilian, Rank 1 ... Rank 14): the highest any character of that faction
-- has reached. Battleground wins come from PVP_MATCH_COMPLETE, duels from the
-- game's "has defeated ... in a duel" line.
local PVP = {
    -- The Legacy ranks: 3, 7, 10, 13, 14. (knight and stoneguard keep their
    -- ids from when they were Rank 6, so earlier unlocks stay earned.)
    { id = "sergeant_a",   counter = "rankAlliance", goal = 3,  text = "Reach PvP Rank 3 (Sergeant) on an Alliance character" },
    { id = "knight",       counter = "rankAlliance", goal = 7,  text = "Reach PvP Rank 7 (Knight-Lieutenant) on an Alliance character" },
    { id = "ltcommander",  counter = "rankAlliance", goal = 10, text = "Reach PvP Rank 10 on an Alliance character" },
    { id = "fieldmarshal", counter = "rankAlliance", goal = 13, text = "Reach PvP Rank 13 (Field Marshal) on an Alliance character" },
    { id = "grandmarshal", counter = "rankAlliance", goal = 14, text = "Reach PvP Rank 14 on an Alliance character" },
    { id = "sergeant_h",   counter = "rankHorde",    goal = 3,  text = "Reach PvP Rank 3 (Sergeant) on a Horde character" },
    { id = "stoneguard",   counter = "rankHorde",    goal = 7,  text = "Reach PvP Rank 7 (Blood Guard) on a Horde character" },
    { id = "champion",     counter = "rankHorde",    goal = 10, text = "Reach PvP Rank 10 on a Horde character" },
    { id = "warlord",      counter = "rankHorde",    goal = 13, text = "Reach PvP Rank 13 (Warlord) on a Horde character" },
    { id = "highwarlord",  counter = "rankHorde",    goal = 14, text = "Reach PvP Rank 14 on a Horde character" },
    { id = "flagrunner",   counter = "winWSG",        goal = 5,  text = "Win 5 Warsong Gulch battles" },
    { id = "fivebanners",  counter = "winAB",         goal = 5,  text = "Win 5 Arathi Basin battles" },
    { id = "wintersiege",  counter = "winAV",         goal = 3,  text = "Win 3 Alterac Valley battles" },
    { id = "duelist",      counter = "duels",         goal = 25, text = "Win 25 duels" },
}
for _, f in ipairs(PVP) do
    f.pvp = true
    f.skin = f.id
    LIST[#LIST + 1] = f
end

-- Round 3: more styles (three of them seasonal: hits landed during that
-- month), more factions, and PvP skins earned by honorable kills (each
-- character's lifetime count from the game, kept per character and summed
-- for the account).
local MORE = {
    { id = "starfall",   counter = "nightCrits", goal = 100,  text = "Land 100 critical hits at night (9 PM to 5 AM server time)" },
    { id = "gearworks",  counter = "mechanical", goal = 100,  text = "Slay 100 Mechanical foes" },
    { id = "murloc",     counter = "murloc",     goal = 100,  text = "Slay 100 Murlocs" },
    { id = "hallows",    counter = "hitsOct",    goal = 500,  text = "Land 500 hits during October" },
    { id = "winterveil", counter = "hitsDec",    goal = 500,  text = "Land 500 hits during December" },
    { id = "heartthrob", counter = "hitsFeb",    goal = 500,  text = "Land 500 hits during February" },
    { id = "broadside",  counter = "bloodsail",  goal = 100,  text = "Slay 100 Bloodsail Buccaneers" },
    { id = "hexbound",   counter = "gurubashi",  goal = 100,  text = "Slay 100 Gurubashi or Hakkari, or defeat Hakkar", boss = { "Hakkar" } },
    { id = "oldgod",     counter = "twilight",   goal = 100,  text = "Slay 100 Twilight's Hammer or defeat C'Thun", boss = { "C'Thun" } },
    { id = "swarm",      counter = "silithid",   goal = 250,  text = "Slay 250 Silithid or Qiraji, or defeat Ossirian", boss = { "Ossirian the Unscarred" } },
    { id = "tidecaller", counter = "elemental",  goal = 100,  text = "Slay 100 Elementals or defeat Ragnaros", boss = { "Ragnaros" } },
    { id = "tally",        counter = "hk",         goal = 100,  text = "Earn 100 honorable kills" },
    { id = "lionspride",   counter = "hkAlliance", goal = 250,  text = "Earn 250 honorable kills on Alliance characters" },
    { id = "bloodthunder", counter = "hkHorde",    goal = 250,  text = "Earn 250 honorable kills on Horde characters" },
    { id = "headhunter",   counter = "hk",         goal = 1000, text = "Earn 1,000 honorable kills" },
    { id = "warmonger",    counter = "hk",         goal = 5000, text = "Earn 5,000 honorable kills" },
}
for _, f in ipairs(MORE) do
    f.skin = f.id
    LIST[#LIST + 1] = f
end

-- Spec variants (SpecSkins.lua): spend 20 talent points in that spec's tree
-- on any character of the class. Built from the skins themselves.
local SPEC_POINTS = 20
local SPEC_FEATS = {}
for _, id in ipairs(ns.SkinOrder) do
    local s = ns.Skins[id]
    if s.spec then
        local f = { id = id, skin = id, spec = s.spec, tree = s.tree, class = s.class, goal = SPEC_POINTS,
                    text = ("Spend %d talent points in %s on a %s"):format(SPEC_POINTS, s.treeName or s.spec, className(s.class)) }
        LIST[#LIST + 1] = f
        SPEC_FEATS[#SPEC_FEATS + 1] = f
    end
end

-- Fun skins (FunSkins.lua): secret feats. Until one is done, players see
-- only its hint (Feats.DisplayText).
local FUN = {
    { id = "natural20",  counter = "nat20",        goal = 1,    hint = "Let the dice decide.",
      text = "Type /roll 20 and roll a natural 20" },
    { id = "synthwave",  counter = "midnightCrit", goal = 1,    hint = "When the clock strikes twelve.",
      text = "Land a crit at exactly midnight, game time" },
    { id = "glitch",     counter = "reloads",      goal = 50,   hint = "Have you tried turning it off and on again?",
      text = "Reload your UI 50 times" },
    { id = "discofever", counter = "dances",       goal = 100,  hint = "Feel the rhythm.",
      text = "/dance 100 times" },
    { id = "bunnyhop",   counter = "jumps",        goal = 5000, hint = "Up, up and away.",
      text = "Jump 5,000 times" },
    { id = "graveyard",  counter = "deaths",       goal = 50,   hint = "Every hero falls.",
      text = "Die 50 times" },
    { id = "hogger",     counter = "hogger",       goal = 1,    hint = "Elwynn's worst nightmare.",
      text = "Slay Hogger" },
    -- Anime- and music-inspired.
    { id = "powersurge", counter = "crits",        goal = 9001, hint = "Over nine thousand...",
      text = "Land 9,001 crits" },
    { id = "finalmove",  counter = "critBurst",    goal = 1,    hint = "Unleash everything at once.",
      text = "Land 5 crits within 3 seconds" },
    { id = "sakura",     counter = "hitsApr",      goal = 100,  hint = "When the blossoms fall.",
      text = "Land 100 hits during April" },
    { id = "mechastrike", boss = { "Mekgineer Thermaplugg" },   hint = "Pilot the machine.",
      text = "Defeat Mekgineer Thermaplugg" },
    { id = "bassdrop",   counter = "danceZones",   goal = 10,   hint = "Every floor is a dance floor.",
      text = "/dance in 10 different zones" },
    { id = "lofi",       counter = "afk",          goal = 25,   hint = "Just chill.",
      text = "Go AFK 25 times" },
    { id = "karaoke",    counter = "sings",        goal = 50,   hint = "Grab the mic.",
      text = "/sing 50 times" },
    { id = "powerballad", counter = "cheers",      goal = 100,  hint = "Raise your lighters.",
      text = "/cheer 100 times" },
}
for _, f in ipairs(FUN) do
    f.skin, f.secret = f.id, true
    LIST[#LIST + 1] = f
end

-- Anime skins (AnimeSkins.lua): secret feats too, on their own tab.
local ANIME = {
    { id = "mostwanted",    counter = "rares",       goal = 10,  hint = "Every head has a price.",
      text = "Slay 10 rare creatures" },
    { id = "blackcrescent", counter = "swordCrits",  goal = 500, hint = "Know your blade's name.",
      text = "Land 500 critical hits with a sword equipped" },
    { id = "shinobi",       counter = "meals",       goal = 100, hint = "A ninja never skips a meal.",
      text = "Eat food 100 times" },
    { id = "menacing",      counter = "flexes",      goal = 100, hint = "Strike a pose.",
      text = "/flex 100 times" },
    { id = "flowingform",   counter = "swimHits",    goal = 100, hint = "Breathe with the tide.",
      text = "Land 100 hits while swimming" },
    { id = "gotcha",        counter = "kinds",       goal = 151, hint = "One of every kind.",
      text = "Defeat 151 different kinds of creatures" },
    { id = "sootsprites",   counter = "sleeps",      goal = 50,  hint = "Take a long nap.",
      text = "/sleep 50 times" },
    { id = "transmute",     counter = "crafts",      goal = 100, hint = "Equivalent exchange.",
      text = "Craft 100 items with a profession" },
    { id = "finalpage",     counter = "letters",     goal = 25,  hint = "Write it down.",
      text = "Send 25 letters by mail" },
    { id = "steamblades",   counter = "giant",       goal = 50,  hint = "Beyond the walls, giants roam.",
      text = "Slay 50 Giants" },
    { id = "sevenstars",    counter = "gems",        goal = 7,   hint = "Gather all seven.",
      text = "Loot 7 different kinds of gems" },
    { id = "smash",         counter = "quests",      goal = 100, hint = "A hero answers every call.",
      text = "Complete 100 quests" },
    { id = "moonlitcharm",  counter = "curtseys",    goal = 50,  hint = "Curtsy to the moon.",
      text = "/curtsey 50 times" },
    { id = "hexbarrier",    counter = "defends",     goal = 500, hint = "No one gets through.",
      text = "Block, parry or dodge 500 attacks" },
    { id = "chainrev",      counter = "demon",       goal = 100, hint = "Hunt the devils.",
      text = "Slay 100 Demons" },
    { id = "pressurepoint", counter = "unarmedHits", goal = 100, hint = "Fight with bare hands.",
      text = "Land 100 hits with no weapon equipped" },
    { id = "spiraldrill",   counter = "flights",     goal = 50,  hint = "Pierce the heavens.",
      text = "Take 50 flight paths" },
    { id = "linkstart",     counter = "loginDays",   goal = 30,  hint = "Log in, never log out.",
      text = "Log in on 30 different days" },
    { id = "neonslide",     counter = "mounts",      goal = 500, hint = "Ride into the neon night.",
      text = "Summon your mount 500 times" },
    { id = "oneanddone",    counter = "trains",      goal = 100, hint = "100 every day.",
      text = "/train 100 times" },
    { id = "powerlevel",    counter = "levelUps",    goal = 30,  hint = "Train until you're off the scale.",
      text = "Level up 30 times (any characters)" },
    { id = "curseddomain",  counter = "dungeons",    goal = 10,  hint = "Step into another's domain.",
      text = "Enter 10 different dungeons" },
    { id = "bountyjazz",    counter = "elites",      goal = 100, hint = "Every bounty pays.",
      text = "Slay 100 elite enemies" },
    { id = "overflow",      counter = "cries",       goal = 50,  hint = "Let it all out.",
      text = "/cry 50 times" },
    { id = "facedowncard",  counter = "rolls",       goal = 100, hint = "Leave it to the draw.",
      text = "/roll 100 times" },
    { id = "isekaid",       counter = "revives",     goal = 25,  hint = "Wake up in another world.",
      text = "Come back from the dead 25 times" },
    { id = "angervein",     counter = "angers",      goal = 50,  hint = "Count to ten. It didn't help.",
      text = "/angry 50 times" },
    { id = "iaido",         counter = "sheathes",    goal = 100, hint = "Draw, strike, sheathe.",
      text = "Sheathe your weapon 100 times" },
}
for _, f in ipairs(ANIME) do
    f.skin, f.secret = f.id, true
    LIST[#LIST + 1] = f
end

-- Pop skins (PopSkins.lua): secret feats, on their own tab.
local POP = {
    { id = "wishingstar",    counter = "nightPrayers", goal = 25,  hint = "Make a wish after dark.",
      text = "/pray 25 times at night (game time)" },
    { id = "midnightchime",  counter = "shoes",        goal = 25,  hint = "If the shoe fits.",
      text = "Put on boots 25 times" },
    { id = "snowqueen",      counter = "coldHits",     goal = 500, hint = "Born of ice and snow.",
      text = "Land 500 hits in Dun Morogh, Winterspring or Alterac Mountains" },
    { id = "savannasunrise", counter = "savannah",     goal = 30,  hint = "Long live the king.",
      text = "Slay 30 Savannah lions in the Barrens" },
    { id = "rubberhose",     counter = "whistles",     goal = 50,  hint = "Toot the steamboat whistle.",
      text = "/whistle 50 times" },
    { id = "toybox",         counter = "hugs",         goal = 50,  hint = "Every toy needs a friend.",
      text = "/hug 50 times" },
    { id = "islandalert",    counter = "invites",      goal = 25,  hint = "Someone wants you.",
      text = "Get 25 group invites" },
    { id = "frostedglass",   counter = "drinks",       goal = 100, hint = "Raise a glass.",
      text = "Drink 100 times" },
    { id = "edgeglow",       counter = "screenshots",  goal = 25,  hint = "Capture the moment.",
      text = "Take 25 screenshots" },
    { id = "fastcharge",     counter = "hearths",      goal = 50,  hint = "Home to recharge.",
      text = "Use your Hearthstone 50 times" },
    { id = "readreceipt",    counter = "whispersSent", goal = 100, hint = "Slide into their whispers.",
      text = "Send 100 whispers" },
    { id = "ringcloser",     counter = "fightDays",    goal = 14,  hint = "Close them every day.",
      text = "Fight on 14 different days" },
}
for _, f in ipairs(POP) do
    f.skin, f.secret = f.id, true
    LIST[#LIST + 1] = f
end

-- World skins (WorldSkins.lua): Azeroth's legends, bosses, beasts and
-- holidays. Not secret: the feat is the adventure.
local WORLD = {
    { id = "windseeker",     boss = { "Baron Geddon", "Garr" },                  text = "Defeat Baron Geddon or Garr (the Bindings of the Windseeker)" },
    { id = "handofragnaros", boss = { "Ragnaros" },                              text = "Defeat Ragnaros" },
    { id = "ashbringer",     boss = { "Highlord Mograine", "Scarlet Commander Mograine" }, text = "Defeat Mograine in the Scarlet Monastery" },
    { id = "atiesh",         boss = { "Kel'Thuzad" },                            text = "Defeat Kel'Thuzad" },
    { id = "corruptedblood", boss = { "Hakkar" },                                text = "Defeat Hakkar" },
    { id = "chromatic",      boss = { "Nefarian", "Chromaggus" },                text = "Defeat Chromaggus or Nefarian" },
    { id = "emeralddream",   boss = { "Mutanus the Devourer", "Ysondre", "Lethon", "Emeriss", "Taerar" },
      text = "Defeat Mutanus the Devourer or a dragon of nightmare" },
    { id = "titandisc",      boss = { "Archaedas" },                             text = "Defeat Archaedas in Uldaman" },
    { id = "bonecraft",      boss = { "Darkmaster Gandling" },                   text = "Defeat Darkmaster Gandling" },
    { id = "kodostampede",   counter = "kodos",       goal = 50,  text = "Slay 50 kodos" },
    { id = "notakecandle",   counter = "kobolds",     goal = 100, text = "Slay 100 kobolds" },
    { id = "polymorph",      counter = "critters",    goal = 25,  text = "Slay 25 critters" },
    { id = "raptorpack",     counter = "raptors",     goal = 100, text = "Slay 100 raptors" },
    { id = "wisp",           counter = "elfDeaths",   goal = 25,  text = "Die 25 times as a Night Elf" },
    { id = "greenhills",     counter = "stvQuests",   goal = 25,  text = "Complete 25 quests in Stranglethorn Vale" },
    { id = "midsummerblaze", counter = "hitsJun",     goal = 500, text = "Land 500 hits during June" },
    { id = "lunarlanterns",  counter = "hitsJan",     goal = 500, text = "Land 500 hits during January" },
    { id = "highstriker",    counter = "claps",       goal = 100, text = "/clap or /applaud 100 times" },
    { id = "egghunt",        counter = "hitsMar",     goal = 500, text = "Land 500 hits during March" },
    { id = "spirithealer",   counter = "deaths",      goal = 100, text = "Die 100 times" },
}
for _, f in ipairs(WORLD) do
    f.skin = f.id
    LIST[#LIST + 1] = f
end

-- Loot skins (LootSkins.lua): loot an item of that quality or better
-- (2 Uncommon, 3 Rare, 4 Epic, 5 Legendary), or wear a whole item set.
local LOOT_FEATS = {
    { id = "freshfind", loot = 2, text = "Loot an Uncommon (green) item" },
    { id = "rarefind", loot = 3, text = "Loot a Rare (blue) item or better" },
    { id = "epichaul", loot = 4, text = "Loot an Epic (purple) item or better" },
    { id = "legendary", loot = 5, text = "Loot a Legendary (orange) item" },
    { id = "fullset", set = true, text = "Wear every piece of an item set" },
}
for _, f in ipairs(LOOT_FEATS) do
    f.skin = f.id
    LIST[#LIST + 1] = f
end

-- Profession skins (ProfSkins.lua): three tiers each. The first unlocks the
-- skin; Expert and Artisan upgrade it (ns.TierSkin). Skill counts from any
-- character, the best ever seen per profession.
local PROF_TIERS = { { 150, "Journeyman" }, { 225, "Expert" }, { 300, "Artisan" } }
local TIER_SUFFIX = { "", "_expert", "_artisan" }
Feats.PROF_TIERS = PROF_TIERS
local PROF_FEATS, PROF_BY_NAME = {}, {}
for _, id in ipairs(ns.SkinOrder) do
    local s = ns.Skins[id]
    if s.skillLine then
        PROF_BY_NAME[s.prof] = s.skillLine
        for t, tier in ipairs(PROF_TIERS) do
            local f = { id = id .. TIER_SUFFIX[t], skin = id, skillLine = s.skillLine, prof = s.prof,
                        tier = t, tierName = tier[2], goal = tier[1],
                        text = t == 1 and ("Reach %d %s"):format(tier[1], s.prof)
                            or ("Reach %d %s (%s)"):format(tier[1], s.prof, tier[2]) }
            LIST[#LIST + 1] = f
            PROF_FEATS[#PROF_FEATS + 1] = f
        end
    end
end

Feats.ALL = LIST

-- A feat is part of the game once the skin it unlocks is.
function Feats.Available(f)
    return ns.Skins[f.skin] ~= nil
end

-- The feats players see: those with a released skin.
function Feats.Visible()
    local out = {}
    for _, f in ipairs(LIST) do
        if Feats.Available(f) then out[#out + 1] = f end
    end
    return out
end
local BY_ID, BY_SKIN, BY_COUNTER, BY_BOSS = {}, {}, {}, {}
for _, f in ipairs(LIST) do
    BY_ID[f.id] = f
    BY_SKIN[f.skin] = BY_SKIN[f.skin] or f   -- a tiered skin unlocks with its first tier
    if f.counter then
        BY_COUNTER[f.counter] = BY_COUNTER[f.counter] or {}
        tinsert(BY_COUNTER[f.counter], f)
    end
    for _, b in ipairs(f.boss or {}) do BY_BOSS[b] = BY_BOSS[b] or {}; tinsert(BY_BOSS[b], f) end
end
Feats.ByID, Feats.BySkin = BY_ID, BY_SKIN

-- Kills counted toward counters, matched on the mob's English name/type.
local NAME_PREFIX = {
    ["Scarlet "] = "scarlet", ["Dark Iron "] = "darkiron", ["Defias "] = "defias",
    ["Bloodsail "] = "bloodsail", ["Twilight "] = "twilight",
}
local NAME_CONTAINS = {
    Murloc = "murloc", Savannah = "savannah", Kodo = "kodos", Kobold = "kobolds", Raptor = "raptors", Gurubashi = "gurubashi", Hakkari = "gurubashi", Silithid = "silithid", Qiraji = "silithid",
}
local CREATURE_TYPE = { Undead = "undead", Dragonkin = "dragonkin", Mechanical = "mechanical", Elemental = "elemental",
                        Giant = "giant", Demon = "demon", Critter = "critters" }

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------
local function db() return ns.db end

function Feats.InitDB(d)
    d.counters = d.counters or {}
    d.classLevels = d.classLevels or {}
    d.bosses = d.bosses or {}
    d.specPoints = d.specPoints or {}   -- best talent points seen per class and tree ("WARRIOR:1")
    d.setsWorn = d.setsWorn or {}       -- complete item sets worn, by name
    d.danceZones = d.danceZones or {}   -- zones you've danced in (Bass Drop)
    d.profSkill = d.profSkill or {}     -- best skill seen per profession (skill line id)
    d.feats = d.feats or {}
    d.hkChars = d.hkChars or {}
    d.kinds = d.kinds or {}             -- creatures defeated, by name (Gotcha!)
    d.gems = d.gems or {}               -- gems looted, by item id (Seven Stars)
    d.loginDays = d.loginDays or {}     -- days logged in, as YYYYMMDD (Link Start)
    d.fightDays = d.fightDays or {}     -- days you landed a hit, as YYYYMMDD (Ring Closer)
    d.dungeons = d.dungeons or {}       -- dungeons entered, by name (Cursed Domain)
end

function Feats.Mode()
    return db() and db().unlockMode   -- nil until chosen
end

-- Progress toward a feat: current, goal.
function Feats.Progress(f)
    local d = db()
    if f.classLevel then
        return min(f.goal, d.classLevels[f.classLevel] or 0), f.goal
    end
    if f.counter then
        return min(f.goal, d.counters[f.counter] or 0), f.goal
    end
    if f.spec then
        return min(f.goal, d.specPoints[f.class .. ":" .. f.tree] or 0), f.goal
    end
    if f.skillLine then
        return min(f.goal, d.profSkill[f.skillLine] or 0), f.goal
    end
    return 0, 1
end

-- The requirement as players see it: a secret shows only its hint.
function Feats.DisplayText(f)
    if f.secret and not Feats.IsDone(f) then return "Secret: " .. f.hint end
    return f.text
end

-- short: the compact form for the Feats tab's right-hand column.
function Feats.ProgressText(f, short)
    if Feats.IsDone(f) then return "Complete" end
    if f.secret then return "???" end
    if not f.counter and not f.classLevel and not f.spec and not f.skillLine then return "Not yet" end
    local cur, goal = Feats.Progress(f)
    if f.money then return ("%d / %d gold"):format(floor(cur / GOLD), floor(goal / GOLD)) end
    if f.spec then return ("%d / %d points"):format(cur, goal) end
    if f.raceLevel then return ("Level %d / %d"):format(cur, goal) end
    if f.classLevel then
        if short then return ("Level %d / %d"):format(cur, goal) end
        return ("Best %s: level %d / %d"):format(className(f.classLevel), cur, goal)
    end
    return ("%d / %d"):format(cur, goal)
end

local function bossDone(f)
    for _, b in ipairs(f.boss or {}) do
        if db().bosses[b] then return true end
    end
    return false
end

local function liveDone(f)
    if bossDone(f) then return true end
    if f.loot then return (db().counters.lootBest or 0) >= f.loot end
    if f.set then return next(db().setsWorn) ~= nil end
    if not f.counter and not f.classLevel and not f.spec and not f.skillLine then return false end
    local cur, goal = Feats.Progress(f)
    return cur >= goal
end

function Feats.IsDone(f)
    return db().feats[f.id] ~= nil
end

-- The skin's own lock state; any skin with no feat is free.
function Feats.IsUnlocked(skinId)
    local d = db()
    if not d or d.unlockMode ~= "collector" then return true end
    if STARTER[skinId] or skinId == ns.ClassSkinID() then return true end
    local f = BY_SKIN[skinId]
    return not f or Feats.IsDone(f)
end

function Feats.FeatForSkin(skinId)
    return BY_SKIN[skinId]
end

local TIERS_OF = {}
for _, f in ipairs(PROF_FEATS) do
    TIERS_OF[f.skin] = TIERS_OF[f.skin] or {}
    TIERS_OF[f.skin][f.tier] = f
end
Feats.TiersOf = TIERS_OF

-- A tiered skin's tier: the highest earned (all three with everything
-- unlocked), at least 1 so a locked skin previews as Journeyman.
function Feats.SkinTier(skinId)
    local tiers = TIERS_OF[skinId]
    if not tiers then return nil end
    local d = db()
    if not d or d.unlockMode ~= "collector" then return #PROF_TIERS end
    local best = 1
    for t, f in ipairs(tiers) do if Feats.IsDone(f) then best = t end end
    return best
end

-- One line for the window: the tier in use and what the next one takes.
function Feats.TierLine(skinId)
    local tiers = TIERS_OF[skinId]
    if not tiers then return nil end
    local tier = Feats.SkinTier(skinId)
    local f = tiers[tier]
    if not Feats.IsUnlocked(skinId) then
        return ("|cffffd84aLocked.|r Earn it: %s  |cff999999(%s)|r"):format(tiers[1].text, Feats.ProgressText(tiers[1]))
    end
    local nxt = tiers[tier + 1]
    if not nxt then return ("|cffffd84a%s|r: fully upgraded."):format(f.tierName) end
    local cur = Feats.Progress(nxt)
    return ("|cffffd84a%s|r. %s at %d %s  |cff999999(%d / %d)|r"):format(f.tierName, nxt.tierName, nxt.goal, nxt.prof, cur, nxt.goal)
end

-- Counts of skins the player could use right now / all there are.
function Feats.UnlockedCount()
    local have, total = 0, 0
    for _, id in ipairs(ns.SkinOrder) do
        total = total + 1
        if Feats.IsUnlocked(id) then have = have + 1 end
    end
    return have, total
end

---------------------------------------------------------------------------
-- Completing feats
---------------------------------------------------------------------------
local function complete(f, quiet)
    db().feats[f.id] = { at = time() }
    if quiet then return end
    local skin = ns.Skins[f.skin]
    local collector = db().unlockMode == "collector"
    local title = collector and "Skin unlocked" or "Feat complete"
    local name = skin.name
    if f.tier and f.tier > 1 then
        if collector then title = "Skin upgraded" end
        name = ("%s · %s"):format(skin.name, f.tierName)
        skin = ns.TierSkin and ns.TierSkin(skin) or skin
    end
    if Feats.OnComplete then Feats.OnComplete(f, title, name, f.text, skin) end
    if collector and f.tier and f.tier > 1 then
        ns.Print(("|cffffd84aSkin upgraded:|r %s (%s)."):format(name, f.text))
    elseif collector then
        ns.Print(("|cffffd84aSkin unlocked:|r %s (%s). /skindeep to equip it."):format(name, f.text))
    else
        ns.Print(("|cffffd84aFeat complete:|r %s (%s)."):format(name, f.text))
    end
end

-- Checks a set of feats (default: all) and completes any that are done.
-- Feats whose skin isn't in the game yet wait (their counters still run).
function Feats.Check(list, quiet)
    for _, f in ipairs(list or LIST) do
        if Feats.Available(f) and not Feats.IsDone(f) and liveDone(f) then complete(f, quiet) end
    end
end

local function bump(counter, by)
    local c = db().counters
    c[counter] = (c[counter] or 0) + (by or 1)
    local list = BY_COUNTER[counter]
    if list then Feats.Check(list) end
end
Feats.Bump = bump

-- For "highest reached" counters (levels, honor levels).
local function raise(counter, value)
    local c = db().counters
    if value and (c[counter] or 0) < value then
        c[counter] = value
        if BY_COUNTER[counter] then Feats.Check(BY_COUNTER[counter]) end
    end
end

function Feats.BossKilled(name)
    name = ns.Plain(name, "string")
    if not name or not BY_BOSS[name] then return end
    db().bosses[name] = db().bosses[name] or time()
    Feats.Check(BY_BOSS[name])
end

-- A mob you fought died. rare: a rare (or rare elite) creature.
function Feats.Killed(name, creatureType, rare, elite)
    if name == "Hogger" then raise("hogger", 1) end
    if rare then bump("rares") end
    if elite then bump("elites") end
    -- Gotcha!: every kind of creature, by name, once.
    if name and not db().kinds[name] then
        db().kinds[name] = true
        bump("kinds")
    end
    -- Each counter at most once per kill ("Gurubashi Hakkari" is one troll).
    local hit = {}
    if name then
        for prefix, counter in pairs(NAME_PREFIX) do
            if name:sub(1, #prefix) == prefix then hit[counter] = true end
        end
        for word, counter in pairs(NAME_CONTAINS) do
            if name:find(word, 1, true) then hit[counter] = true end
        end
        if BY_BOSS[name] then Feats.BossKilled(name) end
    end
    local counter = creatureType and CREATURE_TYPE[creatureType]
    if counter then hit[counter] = true end
    for c in pairs(hit) do bump(c) end
end

---------------------------------------------------------------------------
-- Mode
---------------------------------------------------------------------------
function Feats.SetMode(mode)
    local d = db()
    d.unlockMode = mode
    -- A skin that's locked in Collector falls back to Auto.
    if mode == "collector" and not Feats.IsUnlocked(d.skin) then
        ns.Print(("%s is locked in Collector mode, so you're on Auto: my class until you earn it.")
            :format(ns.Skins[d.skin] and ns.Skins[d.skin].name or d.skin))
        d.skin = ns.AUTO
        ns.ApplyCVars()
    end
    if ns.OnSettingsChanged then ns.OnSettingsChanged() end
end

---------------------------------------------------------------------------
-- Tracking
---------------------------------------------------------------------------
local CRIT = { CRITICAL = true, CRUSHING = true }
local SCHOOL_COUNTER = { [4] = "fire", [16] = "frost", [64] = "arcane" }
local MONTH_COUNTER = { [10] = "hitsOct", [12] = "hitsDec", [2] = "hitsFeb", [4] = "hitsApr", [6] = "hitsJun", [1] = "hitsJan", [3] = "hitsMar" }

-- The real-world month (local clock), for the seasonal skins.
function Feats.Month()
    if type(date) ~= "function" then return nil end
    local ok, t = pcall(date, "*t")
    return ok and type(t) == "table" and t.month or nil
end

-- 9 PM to 5 AM on the server's clock.
function Feats.IsNight()
    if type(GetGameTime) ~= "function" then return false end
    local ok, hour = pcall(GetGameTime)
    hour = ok and ns.Plain(hour, "number")
    return hour ~= nil and (hour >= 21 or hour < 5)
end

-- Enemy units we hit, by unit token, until they die or the token moves on.
local engaged = {}

local function call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, r = pcall(fn, ...)
    if ok then return r end
end

-- Refreshed on every hit: a token can come to carry a different mob (a
-- plate reused, a target swapped) without an event in between.
local function engage(u)
    if ns.SafeBool(UnitIsPlayer, u) then engaged[u] = nil; return end
    local rec = engaged[u] or {}
    rec.name = ns.Plain(call(UnitName, u), "string")
    rec.ctype = ns.Plain(call(UnitCreatureType, u), "string")
    local class = ns.Plain(call(rawget(_G, "UnitClassification"), u), "string")
    rec.rare = class == "rare" or class == "rareelite"
    rec.elite = class == "elite" or class == "rareelite" or class == "worldboss"
    engaged[u] = rec
end

local function checkDead(u)
    local rec = engaged[u]
    if not rec or not ns.SafeBool(UnitIsDead, u) then return end
    engaged[u] = nil
    -- The same mob may be engaged under its other token (target + plate).
    for other in pairs(engaged) do
        if ns.SafeBool(UnitIsUnit, u, other) then engaged[other] = nil end
    end
    Feats.Killed(rec.name, rec.ctype, rec.rare, rec.elite)
end
Feats.CheckDead = checkDead

---------------------------------------------------------------------------
-- Talents
---------------------------------------------------------------------------
-- Forever has one spec per class: its talent frame is a single modern
-- talent tree (C_Traits) with the three classic trees side by side. The
-- points in each tree are summed by node position: a new tree starts where
-- the gap between node columns is much wider than usual. Classic-style
-- clients report points per tree through GetSpecializationInfo instead.
local function playerClass()
    local ok, _, cls = pcall(UnitClass, "player")
    return ok and ns.Plain(cls, "string") or nil
end

local function readable(t)
    if type(t) ~= "table" then return nil end
    if issecretvalue and issecretvalue(t) then return nil end
    local canAccess = rawget(_G, "canaccesstable")
    if canAccess and not canAccess(t) then return nil end
    return t
end

-- Points per tree from the trait tree, left to right; nil if unreadable.
local function traitTrees()
    local CT, T = C_ClassTalents, C_Traits
    if not (CT and T and CT.GetActiveConfigID and T.GetConfigInfo and T.GetTreeNodes and T.GetNodeInfo) then return nil end
    local configID = ns.Plain(call(CT.GetActiveConfigID), "number")
    if not configID then return nil end
    local config = readable(call(T.GetConfigInfo, configID))
    local treeIDs = config and readable(config.treeIDs)
    if not treeIDs then return nil end
    local nodes = {}
    for _, treeID in ipairs(treeIDs) do
        treeID = ns.Plain(treeID, "number")
        local list = treeID and readable(call(T.GetTreeNodes, treeID))
        for _, nodeID in ipairs(list or {}) do
            nodeID = ns.Plain(nodeID, "number")
            local node = nodeID and readable(call(T.GetNodeInfo, configID, nodeID))
            local x = node and ns.Plain(node.posX, "number")
            if x then nodes[#nodes + 1] = node end
        end
    end
    if #nodes == 0 then return nil end
    local function columns(field)
        local cols, total = {}, 0
        for _, node in ipairs(nodes) do
            local p = ns.Plain(node[field], "number") or 0
            cols[node.posX] = (cols[node.posX] or 0) + p
            total = total + p
        end
        return cols, total
    end
    local cols, total = columns("ranksPurchased")
    if total == 0 then cols, total = columns("activeRank") end
    local xs = {}
    for x in pairs(cols) do xs[#xs + 1] = x end
    table.sort(xs)
    -- Split where the gap is much wider than the usual one between columns.
    local gaps = {}
    for i = 2, #xs do gaps[#gaps + 1] = xs[i] - xs[i - 1] end
    table.sort(gaps)
    local usual = gaps[math.ceil(#gaps / 2)] or 0
    local trees = { 0 }
    for i, x in ipairs(xs) do
        if i > 1 and xs[i] - xs[i - 1] > usual * 1.5 then trees[#trees + 1] = 0 end
        trees[#trees] = trees[#trees] + cols[x]
    end
    if #trees ~= 3 then
        -- Not three clear trees: fall back to thirds of the tree's width.
        trees = { 0, 0, 0 }
        local lo, hi = xs[1], xs[#xs]
        local w = hi - lo
        for _, x in ipairs(xs) do
            local i = w > 0 and min(3, floor((x - lo) / w * 3) + 1) or 1
            trees[i] = trees[i] + cols[x]
        end
    end
    return trees, "traits"
end

-- Points per tree from GetSpecializationInfo (classic-style clients).
local function specTrees()
    local s = C_SpecializationInfo
    local get = s and s.GetSpecializationInfo
    if type(get) ~= "function" then return nil end
    local trees, any = {}, false
    for i = 1, 3 do
        local ok, _, _, _, _, _, _, points = pcall(get, i)
        points = ok and ns.Plain(points, "number") or nil
        trees[i] = points or 0
        if points and points > 0 then any = true end
    end
    if any then return trees, "spec" end
end

local livePoints, liveSource = nil, nil

-- This character's points per tree, read fresh: table, source; or nil.
function Feats.TalentTrees()
    local trees, source = traitTrees()
    if not trees or (trees[1] + trees[2] + trees[3]) == 0 then
        local t2, s2 = specTrees()
        if t2 then trees, source = t2, s2 end
    end
    return trees, source
end

-- The tree holding the most points (ties go to the earlier one), as of the
-- last scan: index, points; nil with no points spent.
function Feats.ActiveTree()
    if not livePoints then return nil end
    local best, bestPoints = nil, 0
    for i = 1, 3 do
        if (livePoints[i] or 0) > bestPoints then best, bestPoints = i, livePoints[i] end
    end
    return best, bestPoints
end

-- "bear" in Bear Form or Dire Bear Form, else nil.
function Feats.PlayerForm()
    if type(GetShapeshiftFormID) ~= "function" then return nil end
    local ok, form = pcall(GetShapeshiftFormID)
    form = ok and ns.Plain(form, "number") or nil
    if form == 5 or form == 8 then return "bear" end
end

-- Records the points spent in each tree (the best ever seen per class and
-- tree, so respeccing never takes an unlock back).
local function scanTalents()
    local cls = playerClass()
    if not cls then return end
    local trees, source = Feats.TalentTrees()
    livePoints, liveSource = trees, source
    if not trees then return end
    local sp = db().specPoints
    local changed = false
    for i = 1, 3 do
        local key = cls .. ":" .. i
        if (sp[key] or 0) < (trees[i] or 0) then sp[key], changed = trees[i], true end
    end
    if changed then Feats.Check(SPEC_FEATS) end
end
Feats.ScanTalents = scanTalents

-- For /skindeep talents.
function Feats.TalentReport()
    scanTalents()
    local cls = playerClass()
    if not livePoints then return nil, cls end
    return livePoints, cls, liveSource
end

---------------------------------------------------------------------------
-- Loot and item sets
---------------------------------------------------------------------------
-- An item's class and subclass ids (2 = weapon; 7, 8 = one- and two-handed
-- swords; 3 = gem).
local function itemClass(item)
    local info = rawget(_G, "GetItemInfoInstant") or (C_Item and C_Item.GetItemInfoInstant)
    if not item or type(info) ~= "function" then return nil end
    local ok, _, _, _, _, _, classID, subclassID = pcall(info, item)
    if not ok then return nil end
    return ns.Plain(classID, "number"), ns.Plain(subclassID, "number")
end

-- "You receive loot: %s." as a pattern (any client language).
local function lootPattern(fmt)
    if type(fmt) ~= "string" then return nil end
    local p = fmt:gsub("([%(%)%.%[%]%*%+%-%?%^%$])", "%%%1")
    p = p:gsub("%%s", "(.+)"):gsub("%%d", "%%d+")
    return "^" .. p
end
local lootPatterns, createPatterns

local HEX_QUALITY = { ["9d9d9d"] = 0, ["ffffff"] = 1, ["1eff00"] = 2, ["0070dd"] = 3, ["a335ee"] = 4, ["ff8000"] = 5, ["e6cc80"] = 6 }

-- An item's quality from its chat text: Forever's quality code (|cnIQ4:),
-- the classic color, or the item itself.
function Feats.LinkQuality(text)
    local iq = text:match("|cnIQ(%d+):")
    if iq then return tonumber(iq) end
    local hex = text:match("|c%x%x(%x%x%x%x%x%x)")
    if hex and HEX_QUALITY[hex:lower()] then return HEX_QUALITY[hex:lower()] end
    local itemID = tonumber(text:match("|Hitem:(%d+)") or "")
    local get = C_Item and C_Item.GetItemQualityByID
    if itemID and type(get) == "function" then
        local ok, q = pcall(get, itemID)
        q = ok and ns.Plain(q, "number")
        if q then return q end
    end
end

-- Your own loot only ("You receive loot", not a party member's).
function Feats.OnLootMessage(msg)
    msg = ns.Plain(msg, "string")
    if not msg or not db() then return end
    if not lootPatterns then
        lootPatterns = {}
        for _, key in ipairs({ "LOOT_ITEM_SELF_MULTIPLE", "LOOT_ITEM_SELF" }) do
            local p = lootPattern(rawget(_G, key))
            if p then lootPatterns[#lootPatterns + 1] = p end
        end
        if #lootPatterns == 0 then lootPatterns[1] = "^You receive loot: (.+)" end
    end
    if not createPatterns then
        createPatterns = {}
        for _, key in ipairs({ "LOOT_ITEM_CREATED_SELF_MULTIPLE", "LOOT_ITEM_CREATED_SELF" }) do
            local p = lootPattern(rawget(_G, key))
            if p then createPatterns[#createPatterns + 1] = p end
        end
        if #createPatterns == 0 then createPatterns[1] = "^You create: (.+)" end
    end
    -- Transmute: something you made ("You create: [Linen Bandage].").
    for _, p in ipairs(createPatterns) do
        if msg:match(p) then bump("crafts"); return end
    end
    for _, p in ipairs(lootPatterns) do
        local item = msg:match(p)
        if item then
            -- Seven Stars: each kind of gem, once.
            local itemID = tonumber(item:match("|Hitem:(%d+)") or "")
            if itemID and not db().gems[itemID] and itemClass(itemID) == 3 then
                db().gems[itemID] = true
                bump("gems")
            end
            local q = Feats.LinkQuality(item)
            if q then
                raise("lootBest", min(q, 5))
                Feats.Check(LOOT_FEATS)
            end
            return q
        end
    end
end

-- The complete item sets you're wearing: the "Set Name (8/8)" line on any
-- equipped piece's tooltip.
local SET_LINE = "^(.-) %((%d+)/(%d+)%)$"
local scanTip
local function tooltipLines(slot)
    local TI = C_TooltipInfo
    if TI and type(TI.GetInventoryItem) == "function" then
        local ok, data = pcall(TI.GetInventoryItem, "player", slot)
        local lines = ok and readable(data) and readable(data.lines)
        if lines then
            local out = {}
            for _, line in ipairs(lines) do
                local t = readable(line) and ns.Plain(line.leftText, "string")
                if t then out[#out + 1] = t end
            end
            return out
        end
    end
    -- Classic-style: read a hidden tooltip.
    if not scanTip then
        local ok, tip = pcall(CreateFrame, "GameTooltip", "SkinDeepScanTip", nil, "GameTooltipTemplate")
        if not ok or not tip then return {} end
        scanTip = tip
    end
    scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
    scanTip:ClearLines()
    if not pcall(scanTip.SetInventoryItem, scanTip, "player", slot) then return {} end
    local out = {}
    for i = 1, scanTip:NumLines() or 0 do
        local fs = rawget(_G, "SkinDeepScanTipTextLeft" .. i)
        local t = fs and ns.Plain(fs:GetText(), "string")
        if t then out[#out + 1] = t end
    end
    return out
end

function Feats.WornSets()
    local sets = {}
    local getLink = rawget(_G, "GetInventoryItemLink")
    for slot = 1, 19 do
        local link = getLink and ns.Plain(call(getLink, "player", slot), "string")
        if link then
            for _, line in ipairs(tooltipLines(slot)) do
                local name, have, total = line:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):match(SET_LINE)
                if name and tonumber(total) and tonumber(total) >= 2 then
                    sets[name] = { have = tonumber(have), total = tonumber(total) }
                    break
                end
            end
        end
    end
    return sets
end

local function scanSets()
    local d = db()
    if not d then return end
    local changed = false
    for name, info in pairs(Feats.WornSets()) do
        if info.have >= info.total and not d.setsWorn[name] then
            d.setsWorn[name], changed = true, true
        end
    end
    if changed then Feats.Check({ BY_ID.fullset }) end
end
Feats.ScanSets = scanSets
local setScanPending
local function scanSetsSoon()
    if setScanPending then return end
    setScanPending = true
    local function go() setScanPending = false; scanSets() end
    if C_Timer then C_Timer.After(0.5, go) else go() end
end

---------------------------------------------------------------------------
-- Professions
---------------------------------------------------------------------------
local function global(name)
    local v = rawget(_G, name)
    return type(v) == "function" and v or nil
end

-- Records each profession's skill (the best ever seen, so dropping a
-- profession never takes a tier back).
local function scanProfessions()
    local d = db()
    local changed = false
    local function record(skillLine, rank)
        if skillLine and rank and (d.profSkill[skillLine] or 0) < rank then
            d.profSkill[skillLine], changed = rank, true
        end
    end
    local getProfs, getInfo = global("GetProfessions"), global("GetProfessionInfo")
    local found = false
    if getProfs and getInfo then
        local r = { pcall(getProfs) }
        if r[1] then
            for i = 2, 6 do
                local slot = ns.Plain(r[i], "number")
                if slot then
                    local ok, name, _, rank, _, _, _, skillLine = pcall(getInfo, slot)
                    if ok then
                        name = ns.Plain(name, "string")
                        skillLine = ns.Plain(skillLine, "number")
                        if not skillLine or skillLine == 0 then skillLine = name and PROF_BY_NAME[name] end
                        record(skillLine, ns.Plain(rank, "number"))
                        found = true
                    end
                end
            end
        end
    end
    -- Classic-style skill list, matched by English name.
    local numLines, lineInfo = global("GetNumSkillLines"), global("GetSkillLineInfo")
    if not found and numLines and lineInfo then
        local ok, n = pcall(numLines)
        n = ok and ns.Plain(n, "number") or 0
        for i = 1, n do
            local ok2, name, isHeader, _, rank = pcall(lineInfo, i)
            name = ok2 and ns.Plain(name, "string")
            if name and not isHeader and PROF_BY_NAME[name] then record(PROF_BY_NAME[name], ns.Plain(rank, "number")) end
        end
    end
    if changed then
        Feats.Check(PROF_FEATS)
        if ns.OnSettingsChanged then ns.OnSettingsChanged() end   -- a skin may have grown a tier
    end
end
Feats.ScanProfessions = scanProfessions

local recentCrits = {}   -- times of your latest crits (Final Move)

-- What's in your main hand: "sword", "other", or nil (bare hands).
local function mainHand()
    local link = ns.Plain(call(rawget(_G, "GetInventoryItemLink"), "player", 16), "string")
    if not link then return nil end
    local classID, sub = itemClass(link)
    return (classID == 2 and (sub == 7 or sub == 8)) and "sword" or "other"
end
Feats.MainHand = mainHand

-- Snow Queen's cold places.
local COLD_ZONES = { ["Dun Morogh"] = true, ["Winterspring"] = true, ["Alterac Mountains"] = true }

-- Today as YYYYMMDD (Link Start, Ring Closer).
local function dayKey()
    local t = call(date, "*t")
    if type(t) ~= "table" or not t.year then return nil end
    return t.year * 10000 + (t.month or 0) * 100 + (t.day or 0)
end

-- Blocks, parries and dodges against you (Hex Barrier).
local DEFEND = { BLOCK = true, PARRY = true, DODGE = true }

function Feats.OnCombat(unit, action, flags, amount, school)
    if not db() then return end
    local u = ns.Plain(unit, "string")
    if u == "player" then
        if DEFEND[ns.Plain(action, "string") or ""] then bump("defends") end
        return
    end
    if not u or (u ~= "target" and not u:find("^nameplate%d")) then return end
    if ns.SafeBool(UnitCanAttack, "player", u) == false then return end
    if ns.Plain(action, "string") ~= "WOUND" then return end
    if ns.Plain(amount, "number") == 0 then return end -- a miss in disguise
    engage(u)
    -- The target's own plate fires too: count each hit once.
    if u ~= "target" and ns.SafeBool(UnitIsUnit, u, "target") then return end
    bump("hits")
    local zone = ns.Plain(call(rawget(_G, "GetRealZoneText")), "string")
    if zone and COLD_ZONES[zone] then bump("coldHits") end
    local day = dayKey()
    if day and not db().fightDays[day] then
        db().fightDays[day] = true
        bump("fightDays")
    end
    local mc = MONTH_COUNTER[Feats.Month() or 0]
    if mc then bump(mc) end
    if ns.SafeBool(rawget(_G, "IsSwimming")) then bump("swimHits") end
    local hand = mainHand()
    if not hand then bump("unarmedHits") end
    if CRIT[ns.Plain(flags, "string") or ""] then
        bump("crits")
        if hand == "sword" then bump("swordCrits") end
        if Feats.IsNight() then bump("nightCrits") end
        local okTime, hour, minute = pcall(GetGameTime)
        if okTime and ns.Plain(hour, "number") == 0 and ns.Plain(minute, "number") == 0 then raise("midnightCrit", 1) end
        local now = call(GetTime) or 0
        tinsert(recentCrits, now)
        while recentCrits[1] and now - recentCrits[1] > 3 do table.remove(recentCrits, 1) end
        if #recentCrits >= 5 then raise("critBurst", 1) end
    end
    local sc = SCHOOL_COUNTER[ns.Plain(school, "number") or 1]
    if sc then bump(sc) end
end

local lastMoney
local function money()
    local m = ns.Plain(call(GetMoney), "number")
    if not m then return end
    if lastMoney and m > lastMoney then bump("gold", m - lastMoney) end
    lastMoney = m
end

local function level(newLevel)
    local lvl = ns.Plain(newLevel, "number") or ns.Plain(call(UnitLevel, "player"), "number")
    local ok, _, cls = pcall(UnitClass, "player")
    cls = ok and ns.Plain(cls, "string")
    if not lvl then return end
    local d = db()
    if cls and (d.classLevels[cls] or 0) < lvl then d.classLevels[cls] = lvl end
    if (d.counters.maxLevel or 0) < lvl then d.counters.maxLevel = lvl end
    -- Race skins: the best level per race.
    local okRace, _, race = pcall(UnitRace, "player")
    race = okRace and ns.Plain(race, "string")
    if race and (d.counters["race" .. race] or 0) < lvl then d.counters["race" .. race] = lvl end
    Feats.Check()
end

---------------------------------------------------------------------------
-- PvP tracking
---------------------------------------------------------------------------
local function playerFaction()
    local ok, f = pcall(UnitFactionGroup, "player")
    f = ok and ns.Plain(f, "string")
    return (f == "Alliance" or f == "Horde") and f or nil
end

Feats.PlayerFaction = playerFaction

-- Classic rank titles, for display (index = rank; 0 is Civilian).
Feats.RANK_NAMES = {
    Alliance = { "Private", "Corporal", "Sergeant", "Master Sergeant", "Sergeant Major", "Knight", "Knight-Lieutenant",
                 "Knight-Captain", "Knight-Champion", "Lieutenant Commander", "Commander", "Marshal", "Field Marshal",
                 "Grand Marshal" },
    Horde = { "Scout", "Grunt", "Sergeant", "Senior Sergeant", "First Sergeant", "Stone Guard", "Blood Guard",
              "Legionnaire", "Centurion", "Champion", "Lieutenant General", "General", "Warlord", "High Warlord" },
}

-- This character's PvP rank: Forever keeps it as a Renown-style currency
-- (Constants.CurrencyConsts.CURRENCY_ID_RENOWN_PVP_RANK) whose amount is the
-- rank. Returns rank (0-14) and the raw currency info, or nil.
function Feats.PvPRank()
    local consts = Constants and Constants.CurrencyConsts
    local id = consts and ns.Plain(consts.CURRENCY_ID_RENOWN_PVP_RANK, "number")
    local get = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo
    if not (id and get) then return nil end
    local ok, info = pcall(get, id)
    if not ok or type(info) ~= "table" then return nil end
    local q = ns.Plain(info.quantity, "number")
    if not q then return nil, info end
    return max(0, min(14, q)), info
end

local function pvpRank()
    local rank, faction = Feats.PvPRank(), playerFaction()
    if rank and faction then raise("rank" .. faction, rank) end
end

local BG = { { "Warsong", "winWSG" }, { "Arathi", "winAB" }, { "Alterac", "winAV" } }
local lastMatch = -100

local function matchComplete(winner)
    winner = ns.Plain(winner, "number")
    local mine = ns.Plain(call(GetBattlefieldArenaFaction), "number")
    if not (winner and mine) or winner ~= mine then return end
    local now = GetTime()
    if now - lastMatch < 60 then return end  -- one result per battle
    lastMatch = now
    local map = ns.Plain(call(GetInstanceInfo), "string") or ""
    for _, bg in ipairs(BG) do
        if map:find(bg[1], 1, true) then bump(bg[2]) end
    end
end

-- The duel result line as a pattern, with which capture is the winner.
local duelPattern, winnerFirst
local function buildDuelPattern()
    local f = type(DUEL_WINNER_KNOCKOUT) == "string" and DUEL_WINNER_KNOCKOUT or "%1$s has defeated %2$s in a duel"
    local i1, i2 = f:find("%1$s", 1, true), f:find("%2$s", 1, true)
    if not (i1 and i2) then return end
    winnerFirst = i1 < i2
    f = f:gsub("%%1%$s", "\1")
    f = f:gsub("%%2%$s", "\2")
    f = f:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
    f = f:gsub("[\1\2]", "(.+)")
    duelPattern = "^" .. f .. "$"
end

-- "Name rolls 20 (1-20)" as a pattern (any client language).
local rollPattern
local function myRoll(msg)
    if rollPattern == nil then
        local fmt = rawget(_G, "RANDOM_ROLL_RESULT")
        if type(fmt) == "string" then
            rollPattern = "^" .. fmt:gsub("([%(%)%.%[%]%*%+%-%?%^%$])", "%%%1"):gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")
        else
            rollPattern = "^(.+) rolls (%d+) %((%d+)%-(%d+)%)"
        end
    end
    local who, roll, lo, hi = msg:match(rollPattern)
    if not who then return end
    local me = ns.Plain(call(UnitName, "player"), "string")
    if not me or not (who == me or who:sub(1, #me + 1) == me .. "-" or who:sub(1, #me + 1) == me .. " ") then return end
    return tonumber(roll), tonumber(lo), tonumber(hi)
end

function Feats.OnSystemMessage(msg)
    msg = ns.Plain(msg, "string")
    if not msg then return end
    local roll, lo, hi = myRoll(msg)
    if roll then
        bump("rolls")
        if roll == 20 and lo == 1 and hi == 20 then raise("nat20", 1) end
        return
    end
    if not duelPattern then buildDuelPattern() end
    if not duelPattern then return end
    local a, b = msg:match(duelPattern)
    if not a then return end
    local winner = winnerFirst and a or b
    local me = ns.Plain(call(UnitName, "player"), "string")
    if not me then return end
    -- The line may carry a surname or realm after the first name.
    if winner == me or winner:sub(1, #me + 1) == me .. " " or winner:sub(1, #me + 1) == me .. "-" then
        bump("duels")
    end
end

-- Honorable kills. Each character's count is the higher of what SkinDeep has
-- seen (one per honor-kill line) and the game's lifetime total for it, so
-- kills from before SkinDeep count too; the account totals add them up.
local function charKey()
    local name = ns.Plain(call(UnitName, "player"), "string")
    if not name then return nil end
    return name .. "-" .. (ns.Plain(call(GetRealmName), "string") or "")
end

local function hkTotals()
    local total, ally, horde = 0, 0, 0
    for _, rec in pairs(db().hkChars) do
        total = total + rec.n
        if rec.faction == "Alliance" then ally = ally + rec.n elseif rec.faction == "Horde" then horde = horde + rec.n end
    end
    raise("hk", total)
    raise("hkAlliance", ally)
    raise("hkHorde", horde)
end

local function hkSync(gained)
    local key = charKey()
    if not key then return end
    local chars = db().hkChars
    local rec = chars[key] or { n = 0 }
    chars[key] = rec
    rec.faction = playerFaction() or rec.faction
    rec.n = rec.n + (gained or 0)
    local lifetime = ns.Plain(call(GetPVPLifetimeStats), "number")
    if lifetime and lifetime > rec.n then rec.n = lifetime end
    hkTotals()
end
Feats.SyncHonorableKills = hkSync

-- The honor-kill line counts; the "You have been awarded N honor points"
-- line (bonus honor, no kill) doesn't.
local awardPattern
function Feats.OnHonorMessage(msg)
    msg = ns.Plain(msg, "string")
    if not msg then return end
    if not awardPattern then
        local f = type(COMBATLOG_HONORAWARD) == "string" and COMBATLOG_HONORAWARD or "You have been awarded %d honor points."
        f = f:gsub("[%(%)%.%+%-%*%?%[%]%^%$]", "%%%0")
        f = f:gsub("%%d", "%%d+")
        f = f:gsub("%%s", ".+")
        awardPattern = "^" .. f .. "$"
    end
    if msg:find(awardPattern) then return end
    hkSync(1)
end

local lastForm
-- Neon Slide: each time you go from on foot to mounted.
local wasMounted
local function checkMount(quiet)
    local m = ns.SafeBool(rawget(_G, "IsMounted")) == true
    if m and wasMounted == false and not quiet then bump("mounts") end
    wasMounted = m
end

-- Shinobi: a meal is the "Food" channel (any food).
local function spellName(id)
    local spell = rawget(_G, "C_Spell")
    local get = (spell and spell.GetSpellName) or rawget(_G, "GetSpellInfo")
    return ns.Plain(call(get, id), "string")
end

-- Link Start: each day you log in, once.
local function loginDay()
    local key = dayKey()
    if key and not db().loginDays[key] then
        db().loginDays[key] = true
        bump("loginDays")
    end
end

-- Cursed Domain: each dungeon you enter, once.
local function enteredDungeon()
    local ok, _, kind = pcall(IsInInstance)
    if not ok or ns.Plain(kind, "string") ~= "party" then return end
    local name = ns.Plain(call(rawget(_G, "GetInstanceInfo")), "string")
    if name and name ~= "" and not db().dungeons[name] then
        db().dungeons[name] = true
        bump("dungeons")
    end
end

local events = CreateFrame("Frame")
local wasAfk, wasDead
for _, e in ipairs({ "PLAYER_FLAGS_CHANGED", "PLAYER_DEAD", "CHAT_MSG_TEXT_EMOTE", "CHAT_MSG_LOOT", "PLAYER_EQUIPMENT_CHANGED", "UPDATE_SHAPESHIFT_FORM", "SKILL_LINES_CHANGED", "CHAT_MSG_SKILL", "CHAT_MSG_COMBAT_HONOR_GAIN", "PLAYER_PVP_KILLS_CHANGED", "PLAYER_TALENT_UPDATE",
                     "CHARACTER_POINTS_CHANGED", "PLAYER_SPECIALIZATION_CHANGED", "ACTIVE_TALENT_GROUP_CHANGED",
                     "TRAIT_CONFIG_UPDATED",
                     "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "UNIT_COMBAT", "UNIT_HEALTH", "PLAYER_TARGET_CHANGED",
                     "NAME_PLATE_UNIT_REMOVED", "ENCOUNTER_END", "BOSS_KILL", "PLAYER_MONEY", "PLAYER_LEVEL_UP",
                     "PLAYER_PVP_RANK_CHANGED", "CURRENCY_DISPLAY_UPDATE", "PVP_MATCH_COMPLETE", "CHAT_MSG_SYSTEM",
                     "UNIT_SPELLCAST_SUCCEEDED", "PLAYER_MOUNT_DISPLAY_CHANGED", "MAIL_SEND_SUCCESS", "QUEST_TURNED_IN",
                     "PLAYER_ALIVE", "PLAYER_UNGHOST", "CHAT_MSG_WHISPER_INFORM", "PARTY_INVITE_REQUEST", "SCREENSHOT_SUCCEEDED" }) do
    pcall(events.RegisterEvent, events, e)
end
events:SetScript("OnEvent", function(_, event, a, b, c, d, e)
    if not db() then return end
    if event == "UNIT_COMBAT" then
        Feats.OnCombat(a, b, c, d, e)
    elseif event == "UNIT_HEALTH" then
        local u = ns.Plain(a, "string")
        if u and engaged[u] then checkDead(u) end
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        local u = ns.Plain(a, "string")
        if u and engaged[u] then
            checkDead(u)
            engaged[u] = nil  -- the token will carry another unit next
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        engaged.target = nil  -- "target" is someone else now
    elseif event == "ENCOUNTER_END" then
        if e == 1 or e == true then Feats.BossKilled(b) end
    elseif event == "BOSS_KILL" then
        Feats.BossKilled(b)
    elseif event == "PLAYER_MONEY" then
        money()
    elseif event == "PLAYER_LEVEL_UP" then
        bump("levelUps")
        level(a)
    elseif event == "PLAYER_PVP_RANK_CHANGED" or event == "CURRENCY_DISPLAY_UPDATE" then
        pvpRank()
    elseif event == "PVP_MATCH_COMPLETE" then
        matchComplete(a)
    elseif event == "CHAT_MSG_SYSTEM" then
        Feats.OnSystemMessage(a)
    elseif event == "CHAT_MSG_COMBAT_HONOR_GAIN" then
        Feats.OnHonorMessage(a)
    elseif event == "PLAYER_PVP_KILLS_CHANGED" then
        hkSync(0)
    elseif event == "PLAYER_TALENT_UPDATE" or event == "CHARACTER_POINTS_CHANGED" or event == "TRAIT_CONFIG_UPDATED"
        or event == "PLAYER_SPECIALIZATION_CHANGED" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
        scanTalents()
        if ns.OnSettingsChanged then ns.OnSettingsChanged() end  -- Auto may now pick another variant
    elseif event == "PLAYER_FLAGS_CHANGED" then
        if ns.Plain(a, "string") == "player" then
            local afk = ns.SafeBool(rawget(_G, "UnitIsAFK"), "player") == true
            if afk and not wasAfk then bump("afk") end
            wasAfk = afk
        end
    elseif event == "PLAYER_DEAD" then
        bump("deaths")
        wasDead = true
        -- Wisp: a Night Elf dies as a wisp.
        local okRace, _, race = pcall(UnitRace, "player")
        if okRace and ns.Plain(race, "string") == "NightElf" then bump("elfDeaths") end
    elseif event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        -- Isekai'd: back in your body (releasing to a ghost isn't it).
        if wasDead and ns.SafeBool(rawget(_G, "UnitIsDeadOrGhost"), "player") == false then
            wasDead = false
            bump("revives")
        end
    elseif event == "CHAT_MSG_WHISPER_INFORM" then
        bump("whispersSent")
    elseif event == "PARTY_INVITE_REQUEST" then
        bump("invites")
    elseif event == "SCREENSHOT_SUCCEEDED" then
        bump("screenshots")
    elseif event == "CHAT_MSG_TEXT_EMOTE" then
        -- Your own /dance ("You burst into dance." / "You dance with ...").
        local text, sender = ns.Plain(a, "string"), ns.Plain(b, "string")
        local me = ns.Plain(call(UnitName, "player"), "string")
        if text and sender and me and (sender == me or sender:sub(1, #me + 1) == me .. "-") then
            local lower = text:lower()
            if lower:find("dance", 1, true) then
                bump("dances")
                -- Bass Drop: the zones you've danced in.
                local zone = ns.Plain(call(rawget(_G, "GetRealZoneText")) or call(rawget(_G, "GetZoneText")), "string")
                if zone and zone ~= "" and not db().danceZones[zone] then
                    db().danceZones[zone] = true
                    local n = 0
                    for _ in pairs(db().danceZones) do n = n + 1 end
                    raise("danceZones", n)
                end
            elseif lower:find("song", 1, true) or lower:find("sing", 1, true) then
                bump("sings")
            elseif lower:find("cheer", 1, true) then
                bump("cheers")
            elseif lower:find("flex", 1, true) then
                bump("flexes")
            elseif lower:find("asleep", 1, true) then
                bump("sleeps")
            elseif lower:find("curts", 1, true) then
                bump("curtseys")
            elseif lower:find("train", 1, true) or lower:find("choo", 1, true) then
                bump("trains")
            elseif lower:find("whistle", 1, true) then
                bump("whistles")
            elseif lower:find("%f[%a]hug") then
                bump("hugs")
            elseif lower:find("pray", 1, true) then
                if Feats.IsNight() then bump("nightPrayers") end
            elseif lower:find("%f[%a]cry") then
                bump("cries")
            elseif lower:find("%f[%a]anger") then
                bump("angers")
            elseif lower:find("%f[%a]clap") or lower:find("applaud", 1, true) then
                bump("claps")
            end
        end
    elseif event == "CHAT_MSG_LOOT" then
        Feats.OnLootMessage(a)
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        if ns.Plain(a, "string") ~= "player" then return end
        local name = spellName(ns.Plain(c, "number"))
        if name == "Food" or (name and name:find("^Food ")) then bump("meals")
        elseif name == "Drink" or (name and name:find("^Drink ")) then bump("drinks")
        elseif name == "Hearthstone" then bump("hearths") end
        checkMount()
    elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        checkMount()
    elseif event == "MAIL_SEND_SUCCESS" then
        bump("letters")
    elseif event == "QUEST_TURNED_IN" then
        bump("quests")
        local zone = ns.Plain(call(rawget(_G, "GetRealZoneText")), "string")
        if zone == "Stranglethorn Vale" then bump("stvQuests") end
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        -- Midnight Chime: boots going on (slot 8, feet), not coming off.
        if ns.Plain(a, "number") == 8 and ns.Plain(call(rawget(_G, "GetInventoryItemLink"), "player", 8), "string") then bump("shoes") end
        scanSetsSoon()
    elseif event == "SKILL_LINES_CHANGED" then
        scanProfessions()
    elseif event == "CHAT_MSG_SKILL" then
        -- "Your skill in Skinning has increased to 144." arrives before the
        -- skill list updates.
        if C_Timer then C_Timer.After(0.3, scanProfessions) else scanProfessions() end
    elseif event == "UPDATE_SHAPESHIFT_FORM" then
        local form = Feats.PlayerForm()
        if form ~= lastForm then
            lastForm = form
            if ns.OnSettingsChanged then ns.OnSettingsChanged() end  -- Guardian in Bear Form
        end
    elseif event == "PLAYER_LOGIN" then
        -- Records this character's level, rank and honorable kills (and
        -- checks every feat: anything already reached pops now).
        pvpRank()
        hkSync(0)
        scanTalents()
        scanProfessions()
        level()
        -- Jumps: the jump key calls JumpOrAscendStart.
        local hook, jump = rawget(_G, "hooksecurefunc"), rawget(_G, "JumpOrAscendStart")
        if hook and jump and not Feats.jumpHooked then
            Feats.jumpHooked = pcall(hook, "JumpOrAscendStart", function() bump("jumps") end)
        end
        -- Flight paths: taking one calls TakeTaxiNode.
        if hook and rawget(_G, "TakeTaxiNode") and not Feats.taxiHooked then
            Feats.taxiHooked = pcall(hook, "TakeTaxiNode", function() bump("flights") end)
        end
        -- Sheathing your weapon (the Z key) calls ToggleSheath.
        if hook and rawget(_G, "ToggleSheath") and not Feats.sheathHooked then
            Feats.sheathHooked = pcall(hook, "ToggleSheath", function() bump("sheathes") end)
        end
        loginDay()
    elseif event == "PLAYER_ENTERING_WORLD" then
        if b == true then bump("reloads") end   -- isReloadingUi
        enteredDungeon()
        checkMount(true)   -- already mounted when you log in doesn't count
        lastMoney = nil
        money()
        pvpRank()
        hkSync(0)
        scanTalents()
        scanProfessions()
        scanSetsSoon()
        -- Talent data can arrive a moment after loading in.
        if C_Timer then C_Timer.After(3, function() scanTalents(); if ns.OnSettingsChanged then ns.OnSettingsChanged() end end) end
    end
end)
