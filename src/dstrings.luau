--!native
--!optimize 2
local dstrings = {}

-- ---------------------------------------------------------------------------
-- D_Main / M_Menu
-- ---------------------------------------------------------------------------

dstrings.D_DEVSTR = "Development mode ON.\n"
dstrings.D_CDROM = "CD-ROM Version: default.cfg from c:\\doomdata\n"

dstrings.PRESSKEY = "press a key."
dstrings.PRESSYN = "press y or n."
dstrings.QUITMSG = "are you sure you want to\nquit this great game?"
dstrings.LOADNET = "you can't do load while in a net game!\n\n" .. dstrings.PRESSKEY
dstrings.QLOADNET = "you can't quickload during a netgame!\n\n" .. dstrings.PRESSKEY
dstrings.QSAVESPOT = "you haven't picked a quicksave slot yet!\n\n" .. dstrings.PRESSKEY
dstrings.SAVEDEAD = "you can't save if you aren't playing!\n\n" .. dstrings.PRESSKEY
dstrings.QSPROMPT = "quicksave over your game named\n\n'%s'?\n\n" .. dstrings.PRESSYN
dstrings.QLPROMPT = "do you want to quickload the game named\n\n'%s'?\n\n" .. dstrings.PRESSYN

dstrings.NEWGAME = "you can't start a new game\nwhile in a network game.\n\n" .. dstrings.PRESSKEY

dstrings.NIGHTMARE = "are you sure? this skill level\nisn't even remotely fair.\n\n" .. dstrings.PRESSYN

dstrings.SWSTRING = "this is the shareware version of doom.\n\n" ..
    "you need to order the entire trilogy.\n\n" .. dstrings.PRESSKEY

dstrings.MSGOFF = "Messages OFF"
dstrings.MSGON = "Messages ON"
dstrings.NETEND = "you can't end a netgame!\n\n" .. dstrings.PRESSKEY
dstrings.ENDGAME = "are you sure you want to end the game?\n\n" .. dstrings.PRESSYN

dstrings.DOSY = "(press y to quit to dos.)"

dstrings.DETAILHI = "High detail"
dstrings.DETAILLO = "Low detail"
dstrings.GAMMALVL0 = "Gamma correction OFF"
dstrings.GAMMALVL1 = "Gamma correction level 1"
dstrings.GAMMALVL2 = "Gamma correction level 2"
dstrings.GAMMALVL3 = "Gamma correction level 3"
dstrings.GAMMALVL4 = "Gamma correction level 4"
dstrings.EMPTYSTRING = "empty slot"

-- ---------------------------------------------------------------------------
-- HU_stuff
-- ---------------------------------------------------------------------------

dstrings.HUSTR_MSGU = "[Message unsent]"

dstrings.mapnames = {
    "E1M1: Hangar",
    "E1M2: Nuclear Plant",
    "E1M3: Toxin Refinery",
    "E1M4: Command Control",
    "E1M5: Phobos Lab",
    "E1M6: Central Processing",
    "E1M7: Computer Station",
    "E1M8: Phobos Anomaly",
    "E1M9: Military Base",

    "E2M1: Deimos Anomaly",
    "E2M2: Containment Area",
    "E2M3: Refinery",
    "E2M4: Deimos Lab",
    "E2M5: Command Center",
    "E2M6: Halls of the Damned",
    "E2M7: Spawning Vats",
    "E2M8: Tower of Babel",
    "E2M9: Fortress of Mystery",

    "E3M1: Hell Keep",
    "E3M2: Slough of Despair",
    "E3M3: Pandemonium",
    "E3M4: House of Pain",
    "E3M5: Unholy Cathedral",
    "E3M6: Mt. Erebus",
    "E3M7: Limbo",
    "E3M8: Dis",
    "E3M9: Warrens",

    "E4M1: Hell Beneath",
    "E4M2: Perfect Hatred",
    "E4M3: Sever The Wicked",
    "E4M4: Unruly Evil",
    "E4M5: They Will Repent",
    "E4M6: Against Thee Wickedly",
    "E4M7: And Hell Followed",
    "E4M8: Unto The Cruel",
    "E4M9: Fear",

    "NEWLEVEL",
    "NEWLEVEL",
    "NEWLEVEL",
    "NEWLEVEL",
    "NEWLEVEL",
    "NEWLEVEL",
    "NEWLEVEL",
    "NEWLEVEL",
    "NEWLEVEL",
}

-- The commercial names are stored in a single large array; WADs like pl2.wad
-- have a MAP33 and rely on the Vanilla layout where it is possible to
-- overflow the end of one array into the next.
dstrings.mapnames_commercial = {
    "level 1: entryway",
    "level 2: underhalls",
    "level 3: the gantlet",
    "level 4: the focus",
    "level 5: the waste tunnels",
    "level 6: the crusher",
    "level 7: dead simple",
    "level 8: tricks and traps",
    "level 9: the pit",
    "level 10: refueling base",
    "level 11: 'o' of destruction!",

    "level 12: the factory",
    "level 13: downtown",
    "level 14: the inmost dens",
    "level 15: industrial zone",
    "level 16: suburbs",
    "level 17: tenements",
    "level 18: the courtyard",
    "level 19: the citadel",
    "level 20: gotcha!",

    "level 21: nirvana",
    "level 22: the catacombs",
    "level 23: barrels o' fun",
    "level 24: the chasm",
    "level 25: bloodfalls",
    "level 26: the abandoned mines",
    "level 27: monster condo",
    "level 28: the spirit world",
    "level 29: the living end",
    "level 30: icon of sin",

    "level 31: wolfenstein",
    "level 32: grosse",

    -- Plutonia WAD map names.
    "level 1: congo",
    "level 2: well of souls",
    "level 3: aztec",
    "level 4: caged",
    "level 5: ghost town",
    "level 6: baron's lair",
    "level 7: caughtyard",
    "level 8: realm",
    "level 9: abattoire",
    "level 10: onslaught",
    "level 11: hunted",

    "level 12: speed",
    "level 13: the crypt",
    "level 14: genesis",
    "level 15: the twilight",
    "level 16: the omen",
    "level 17: compound",
    "level 18: neurosphere",
    "level 19: nme",
    "level 20: the death domain",

    "level 21: slayer",
    "level 22: impossible mission",
    "level 23: tombstone",
    "level 24: the final frontier",
    "level 25: the temple of darkness",
    "level 26: bunker",
    "level 27: anti-christ",
    "level 28: the sewers",
    "level 29: odyssey of noises",
    "level 30: the gateway of hell",

    "level 31: cyberden",
    "level 32: go 2 it",

    -- TNT WAD map names.
    "level 1: system control",
    "level 2: human bbq",
    "level 3: power control",
    "level 4: wormhole",
    "level 5: hanger",
    "level 6: open season",
    "level 7: prison",
    "level 8: metal",
    "level 9: stronghold",
    "level 10: redemption",
    "level 11: storage facility",

    "level 12: crater",
    "level 13: nukage processing",
    "level 14: steel works",
    "level 15: dead zone",
    "level 16: deepest reaches",
    "level 17: processing area",
    "level 18: mill",
    "level 19: shipping/respawning",
    "level 20: central processing",

    "level 21: administration center",
    "level 22: habitat",
    "level 23: lunar mining project",
    "level 24: quarry",
    "level 25: baron's den",
    "level 26: ballistyx",
    "level 27: mount pain",
    "level 28: heck",
    "level 29: river styx",
    "level 30: last call",

    "level 31: pharaoh",
    "level 32: caribbean",
}

dstrings.HUSTR_CHATMACRO1 = "I'm ready to kick butt!"
dstrings.HUSTR_CHATMACRO2 = "I'm OK."
dstrings.HUSTR_CHATMACRO3 = "I'm not looking too good!"
dstrings.HUSTR_CHATMACRO4 = "Help!"
dstrings.HUSTR_CHATMACRO5 = "You suck!"
dstrings.HUSTR_CHATMACRO6 = "Next time, scumbag..."
dstrings.HUSTR_CHATMACRO7 = "Come here!"
dstrings.HUSTR_CHATMACRO8 = "I'll take care of it."
dstrings.HUSTR_CHATMACRO9 = "Yes"
dstrings.HUSTR_CHATMACRO0 = "No"

dstrings.HUSTR_TALKTOSELF1 = "You mumble to yourself"
dstrings.HUSTR_TALKTOSELF2 = "Who's there?"
dstrings.HUSTR_TALKTOSELF3 = "You scare yourself"
dstrings.HUSTR_TALKTOSELF4 = "You start to rave"
dstrings.HUSTR_TALKTOSELF5 = "You've lost it..."

dstrings.HUSTR_MESSAGESENT = "[Message Sent]"

dstrings.HUSTR_PLRGREEN = "Green: "
dstrings.HUSTR_PLRINDIGO = "Indigo: "
dstrings.HUSTR_PLRBROWN = "Brown: "
dstrings.HUSTR_PLRRED = "Red: "

-- ---------------------------------------------------------------------------
-- AM_map
-- ---------------------------------------------------------------------------

dstrings.AMSTR_FOLLOWON = "Follow Mode ON"
dstrings.AMSTR_FOLLOWOFF = "Follow Mode OFF"
dstrings.AMSTR_GRIDON = "Grid ON"
dstrings.AMSTR_GRIDOFF = "Grid OFF"
dstrings.AMSTR_MARKEDSPOT = "Marked Spot"
dstrings.AMSTR_MARKSCLEARED = "All Marks Cleared"

-- ---------------------------------------------------------------------------
-- ST_stuff
-- ---------------------------------------------------------------------------

dstrings.STSTR_MUS = "Music Change"
dstrings.STSTR_NOMUS = "IMPOSSIBLE SELECTION"
dstrings.STSTR_DQDON = "Degreelessness Mode On"
dstrings.STSTR_DQDOFF = "Degreelessness Mode Off"
dstrings.STSTR_KFAADDED = "Very Happy Ammo Added"
dstrings.STSTR_FAADDED = "Ammo (no keys) Added"
dstrings.STSTR_NCON = "No Clipping Mode ON"
dstrings.STSTR_NCOFF = "No Clipping Mode OFF"
dstrings.STSTR_BEHOLD = "inVuln, Str, Inviso, Rad, Allmap, or Lite-amp"
dstrings.STSTR_BEHOLDX = "Power-up Toggled"
dstrings.STSTR_CHOPPERS = "... doesn't suck - GM"
dstrings.STSTR_CLEV = "Changing Level..."

-- ---------------------------------------------------------------------------
-- F_Finale
-- ---------------------------------------------------------------------------

dstrings.E1TEXT = "Once you beat the big badasses and\n" ..
    "clean out the moon base you're supposed\n" ..
    "to win, aren't you? Aren't you? Where's\n" ..
    "your fat reward and ticket home? What\n" ..
    "the hell is this? It's not supposed to\n" ..
    "end this way!\n" ..
    "\n" ..
    "It stinks like rotten meat, but looks\n" ..
    "like the lost Deimos base.  Looks like\n" ..
    "you're stuck on The Shores of Hell.\n" ..
    "The only way out is through.\n" ..
    "\n" ..
    "To continue the DOOM experience, play\n" ..
    "The Shores of Hell and its amazing\n" ..
    "sequel, Inferno!\n"

dstrings.E2TEXT = "You've done it! The hideous cyber-\n" ..
    "demon lord that ruled the lost Deimos\n" ..
    "moon base has been slain and you\n" ..
    "are triumphant! But ... where are\n" ..
    "you? You clamber to the edge of the\n" ..
    "moon and look down to see the awful\n" ..
    "truth.\n" ..
    "\n" ..
    "Deimos floats above Hell itself!\n" ..
    "You've never heard of anyone escaping\n" ..
    "from Hell, but you'll make the bastards\n" ..
    "sorry they ever heard of you! Quickly,\n" ..
    "you rappel down to  the surface of\n" ..
    "Hell.\n" ..
    "\n" ..
    "Now, it's on to the final chapter of\n" ..
    "DOOM! -- Inferno."

dstrings.E3TEXT = "The loathsome spiderdemon that\n" ..
    "masterminded the invasion of the moon\n" ..
    "bases and caused so much death has had\n" ..
    "its ass kicked for all time.\n" ..
    "\n" ..
    "A hidden doorway opens and you enter.\n" ..
    "You've proven too tough for Hell to\n" ..
    "contain, and now Hell at last plays\n" ..
    "fair -- for you emerge from the door\n" ..
    "to see the green fields of Earth!\n" ..
    "Home at last.\n" ..
    "\n" ..
    "You wonder what's been happening on\n" ..
    "Earth while you were battling evil\n" ..
    "unleashed. It's good that no Hell-\n" ..
    "spawn could have come through that\n" ..
    "door with you ..."

dstrings.E4TEXT = "the spider mastermind must have sent forth\n" ..
    "its legions of hellspawn before your\n" ..
    "final confrontation with that terrible\n" ..
    "beast from hell.  but you stepped forward\n" ..
    "and brought forth eternal damnation and\n" ..
    "suffering upon the horde as a true hero\n" ..
    "would in the face of something so evil.\n" ..
    "\n" ..
    "besides, someone was gonna pay for what\n" ..
    "happened to daisy, your pet rabbit.\n" ..
    "\n" ..
    "but now, you see spread before you more\n" ..
    "potential pain and gibbitude as a nation\n" ..
    "of demons run amok among our cities.\n" ..
    "\n" ..
    "next stop, hell on earth!"

dstrings.C1TEXT = "YOU HAVE ENTERED DEEPLY INTO THE INFESTED\n" ..
    "STARPORT. BUT SOMETHING IS WRONG. THE\n" ..
    "MONSTERS HAVE BROUGHT THEIR OWN REALITY\n" ..
    "WITH THEM, AND THE STARPORT'S TECHNOLOGY\n" ..
    "IS BEING SUBVERTED BY THEIR PRESENCE.\n" ..
    "\n" ..
    "AHEAD, YOU SEE AN OUTPOST OF HELL, A\n" ..
    "FORTIFIED ZONE. IF YOU CAN GET PAST IT,\n" ..
    "YOU CAN PENETRATE INTO THE HAUNTED HEART\n" ..
    "OF THE STARBASE AND FIND THE CONTROLLING\n" ..
    "SWITCH WHICH HOLDS EARTH'S POPULATION\n" ..
    "HOSTAGE."

dstrings.C2TEXT = "YOU HAVE WON! YOUR VICTORY HAS ENABLED\n" ..
    "HUMANKIND TO EVACUATE EARTH AND ESCAPE\n" ..
    "THE NIGHTMARE.  NOW YOU ARE THE ONLY\n" ..
    "HUMAN LEFT ON THE FACE OF THE PLANET.\n" ..
    "CANNIBAL MUTATIONS, CARNIVOROUS ALIENS,\n" ..
    "AND EVIL SPIRITS ARE YOUR ONLY NEIGHBORS.\n" ..
    "YOU SIT BACK AND WAIT FOR DEATH, CONTENT\n" ..
    "THAT YOU HAVE SAVED YOUR SPECIES.\n" ..
    "\n" ..
    "BUT THEN, EARTH CONTROL BEAMS DOWN A\n" ..
    "MESSAGE FROM SPACE: \"SENSORS HAVE LOCATED\n" ..
    "THE SOURCE OF THE ALIEN INVASION. IF YOU\n" ..
    "GO THERE, YOU MAY BE ABLE TO BLOCK THEIR\n" ..
    "ENTRY.  THE ALIEN BASE IS IN THE HEART OF\n" ..
    "YOUR OWN HOME CITY, NOT FAR FROM THE\n" ..
    "STARPORT.\" SLOWLY AND PAINFULLY YOU GET\n" ..
    "UP AND RETURN TO THE FRAY."

dstrings.C3TEXT = "YOU ARE AT THE CORRUPT HEART OF THE CITY,\n" ..
    "SURROUNDED BY THE CORPSES OF YOUR ENEMIES.\n" ..
    "YOU SEE NO WAY TO DESTROY THE CREATURES'\n" ..
    "ENTRYWAY ON THIS SIDE, SO YOU CLENCH YOUR\n" ..
    "TEETH AND PLUNGE THROUGH IT.\n" ..
    "\n" ..
    "THERE MUST BE A WAY TO CLOSE IT ON THE\n" ..
    "OTHER SIDE. WHAT DO YOU CARE IF YOU'VE\n" ..
    "GOT TO GO THROUGH HELL TO GET TO IT?"

dstrings.C4TEXT = "THE HORRENDOUS VISAGE OF THE BIGGEST\n" ..
    "DEMON YOU'VE EVER SEEN CRUMBLES BEFORE\n" ..
    "YOU, AFTER YOU PUMP YOUR ROCKETS INTO\n" ..
    "HIS EXPOSED BRAIN. THE MONSTER SHRIVELS\n" ..
    "UP AND DIES, ITS THRASHING LIMBS\n" ..
    "DEVASTATING UNTOLD MILES OF HELL'S\n" ..
    "SURFACE.\n" ..
    "\n" ..
    "YOU'VE DONE IT. THE INVASION IS OVER.\n" ..
    "EARTH IS SAVED. HELL IS A WRECK. YOU\n" ..
    "WONDER WHERE BAD FOLKS WILL GO WHEN THEY\n" ..
    "DIE, NOW. WIPING THE SWEAT FROM YOUR\n" ..
    "FOREHEAD YOU BEGIN THE LONG TREK BACK\n" ..
    "HOME. REBUILDING EARTH OUGHT TO BE A\n" ..
    "LOT MORE FUN THAN RUINING IT WAS."

dstrings.C5TEXT = "CONGRATULATIONS, YOU'VE FOUND THE SECRET\n" ..
    "LEVEL! LOOKS LIKE IT'S BEEN BUILT BY\n" ..
    "HUMANS, RATHER THAN DEMONS. YOU WONDER\n" ..
    "WHO THE INMATES OF THIS CORNER OF HELL\n" ..
    "WILL BE."

dstrings.C6TEXT = "CONGRATULATIONS, YOU'VE FOUND THE\n" ..
    "SUPER SECRET LEVEL!  YOU'D BETTER\n" ..
    "BLAZE THROUGH THIS ONE!\n"

dstrings.P1TEXT = "You gloat over the steaming carcass of the\n" ..
    "Guardian.  With its death, you've wrested\n" ..
    "the Accelerator from the stinking claws\n" ..
    "of Hell.  You relax and glance around the\n" ..
    "room.  Damn!  There was supposed to be at\n" ..
    "least one working prototype, but you can't\n" ..
    "see it. The demons must have taken it.\n" ..
    "\n" ..
    "You must find the prototype, or all your\n" ..
    "struggles will have been wasted. Keep\n" ..
    "moving, keep fighting, keep killing.\n" ..
    "Oh yes, keep living, too."

dstrings.P2TEXT = "Even the deadly Arch-Vile labyrinth could\n" ..
    "not stop you, and you've gotten to the\n" ..
    "prototype Accelerator which is soon\n" ..
    "efficiently and permanently deactivated.\n" ..
    "\n" ..
    "You're good at that kind of thing."

dstrings.P3TEXT = "You've bashed and battered your way into\n" ..
    "the heart of the devil-hive.  Time for a\n" ..
    "Search-and-Destroy mission, aimed at the\n" ..
    "Gatekeeper, whose foul offspring is\n" ..
    "cascading to Earth.  Yeah, he's bad. But\n" ..
    "you know who's worse!\n" ..
    "\n" ..
    "Grinning evilly, you check your gear, and\n" ..
    "get ready to give the bastard a little Hell\n" ..
    "of your own making!"

dstrings.P4TEXT = "The Gatekeeper's evil face is splattered\n" ..
    "all over the place.  As its tattered corpse\n" ..
    "collapses, an inverted Gate forms and\n" ..
    "sucks down the shards of the last\n" ..
    "prototype Accelerator, not to mention the\n" ..
    "few remaining demons.  You're done. Hell\n" ..
    "has gone back to pounding bad dead folks \n" ..
    "instead of good live ones.  Remember to\n" ..
    "tell your grandkids to put a rocket\n" ..
    "launcher in your coffin. If you go to Hell\n" ..
    "when you die, you'll need it for some\n" ..
    "final cleaning-up ..."

dstrings.P5TEXT = "You've found the second-hardest level we\n" ..
    "got. Hope you have a saved game a level or\n" ..
    "two previous.  If not, be prepared to die\n" ..
    "aplenty. For master marines only."

dstrings.P6TEXT = "Betcha wondered just what WAS the hardest\n" ..
    "level we had ready for ya?  Now you know.\n" ..
    "No one gets out alive."

dstrings.T1TEXT = "You've fought your way out of the infested\n" ..
    "experimental labs.   It seems that UAC has\n" ..
    "once again gulped it down.  With their\n" ..
    "high turnover, it must be hard for poor\n" ..
    "old UAC to buy corporate health insurance\n" ..
    "nowadays..\n" ..
    "\n" ..
    "Ahead lies the military complex, now\n" ..
    "swarming with diseased horrors hot to get\n" ..
    "their teeth into you. With luck, the\n" ..
    "complex still has some warlike ordnance\n" ..
    "laying around."

dstrings.T2TEXT = "You hear the grinding of heavy machinery\n" ..
    "ahead.  You sure hope they're not stamping\n" ..
    "out new hellspawn, but you're ready to\n" ..
    "ream out a whole herd if you have to.\n" ..
    "They might be planning a blood feast, but\n" ..
    "you feel about as mean as two thousand\n" ..
    "maniacs packed into one mad killer.\n" ..
    "\n" ..
    "You don't plan to go down easy."

dstrings.T3TEXT = "The vista opening ahead looks real damn\n" ..
    "familiar. Smells familiar, too -- like\n" ..
    "fried excrement. You didn't like this\n" ..
    "place before, and you sure as hell ain't\n" ..
    "planning to like it now. The more you\n" ..
    "brood on it, the madder you get.\n" ..
    "Hefting your gun, an evil grin trickles\n" ..
    "onto your face. Time to take some names."

dstrings.T4TEXT = "Suddenly, all is silent, from one horizon\n" ..
    "to the other. The agonizing echo of Hell\n" ..
    "fades away, the nightmare sky turns to\n" ..
    "blue, the heaps of monster corpses start \n" ..
    "to evaporate along with the evil stench \n" ..
    "that filled the air. Jeeze, maybe you've\n" ..
    "done it. Have you really won?\n" ..
    "\n" ..
    "Something rumbles in the distance.\n" ..
    "A blue light begins to glow inside the\n" ..
    "ruined skull of the demon-spitter."

dstrings.T5TEXT = "What now? Looks totally different. Kind\n" ..
    "of like King Tut's condo. Well,\n" ..
    "whatever's here can't be any worse\n" ..
    "than usual. Can it?  Or maybe it's best\n" ..
    "to let sleeping gods lie.."

dstrings.T6TEXT = "Time for a vacation. You've burst the\n" ..
    "bowels of hell and by golly you're ready\n" ..
    "for a break. You mutter to yourself,\n" ..
    "Maybe someone else can kick Hell's ass\n" ..
    "next time around. Ahead lies a quiet town,\n" ..
    "with peaceful flowing water, quaint\n" ..
    "buildings, and presumably no Hellspawn.\n" ..
    "\n" ..
    "As you step off the transport, you hear\n" ..
    "the stomp of a cyberdemon's iron shoe."

-- ---------------------------------------------------------------------------
-- Character cast strings (F_FINALE.C)
-- ---------------------------------------------------------------------------

dstrings.CC_ZOMBIE = "ZOMBIEMAN"
dstrings.CC_SHOTGUN = "SHOTGUN GUY"
dstrings.CC_HEAVY = "HEAVY WEAPON DUDE"
dstrings.CC_IMP = "IMP"
dstrings.CC_DEMON = "DEMON"
dstrings.CC_LOST = "LOST SOUL"
dstrings.CC_CACO = "CACODEMON"
dstrings.CC_HELL = "HELL KNIGHT"
dstrings.CC_BARON = "BARON OF HELL"
dstrings.CC_ARACH = "ARACHNOTRON"
dstrings.CC_PAIN = "PAIN ELEMENTAL"
dstrings.CC_REVEN = "REVENANT"
dstrings.CC_MANCU = "MANCUBUS"
dstrings.CC_ARCH = "ARCH-VILE"
dstrings.CC_SPIDER = "THE SPIDER MASTERMIND"
dstrings.CC_CYBER = "THE CYBERDEMON"
dstrings.CC_HERO = "OUR HERO"

-- ---------------------------------------------------------------------------
-- dstrings.c
-- ---------------------------------------------------------------------------

dstrings.doom1_endmsg = {
    "are you sure you want to\nquit this great game?",
    "please don't leave, there's more\ndemons to toast!",
    "let's beat it -- this is turning\ninto a bloodbath!",
    "i wouldn't leave if i were you.\ndos is much worse.",
    "you're trying to say you like dos\nbetter than me, right?",
    "don't leave yet -- there's a\ndemon around that corner!",
    "ya know, next time you come in here\ni'm gonna toast ya.",
    "go ahead and leave. see if i care.",
}

dstrings.doom2_endmsg = {
    "are you sure you want to\nquit this great game?",
    "you want to quit?\nthen, thou hast lost an eighth!",
    "don't go now, there's a \ndimensional shambler waiting\nat the dos prompt!",
    "get outta here and go back\nto your boring programs.",
    "if i were your boss, i'd \n deathmatch ya in a minute!",
    "look, bud. you leave now\nand you forfeit your body count!",
    "just leave. when you come\nback, i'll be waiting with a bat.",
    "you're lucky i don't smack\nyou for thinking about leaving.",
}

return dstrings