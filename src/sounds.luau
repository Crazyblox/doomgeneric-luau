--!native
--!optimize 2
local sounds = {}

sounds.sfxenum = {
    sfx_None = 0,
    sfx_pistol = 1,
    sfx_shotgn = 2,
    sfx_sgcock = 3,
    sfx_dshtgn = 4,
    sfx_dbopn = 5,
    sfx_dbcls = 6,
    sfx_dbload = 7,
    sfx_plasma = 8,
    sfx_bfg = 9,
    sfx_sawup = 10,
    sfx_sawidl = 11,
    sfx_sawful = 12,
    sfx_sawhit = 13,
    sfx_rlaunc = 14,
    sfx_rxplod = 15,
    sfx_firsht = 16,
    sfx_firxpl = 17,
    sfx_pstart = 18,
    sfx_pstop = 19,
    sfx_doropn = 20,
    sfx_dorcls = 21,
    sfx_stnmov = 22,
    sfx_swtchn = 23,
    sfx_swtchx = 24,
    sfx_plpain = 25,
    sfx_dmpain = 26,
    sfx_popain = 27,
    sfx_vipain = 28,
    sfx_mnpain = 29,
    sfx_pepain = 30,
    sfx_slop = 31,
    sfx_itemup = 32,
    sfx_wpnup = 33,
    sfx_oof = 34,
    sfx_telept = 35,
    sfx_posit1 = 36,
    sfx_posit2 = 37,
    sfx_posit3 = 38,
    sfx_bgsit1 = 39,
    sfx_bgsit2 = 40,
    sfx_sgtsit = 41,
    sfx_cacsit = 42,
    sfx_brssit = 43,
    sfx_cybsit = 44,
    sfx_spisit = 45,
    sfx_bspsit = 46,
    sfx_kntsit = 47,
    sfx_vilsit = 48,
    sfx_mansit = 49,
    sfx_pesit = 50,
    sfx_sklatk = 51,
    sfx_sgtatk = 52,
    sfx_skepch = 53,
    sfx_vilatk = 54,
    sfx_claw = 55,
    sfx_skeswg = 56,
    sfx_pldeth = 57,
    sfx_pdiehi = 58,
    sfx_podth1 = 59,
    sfx_podth2 = 60,
    sfx_podth3 = 61,
    sfx_bgdth1 = 62,
    sfx_bgdth2 = 63,
    sfx_sgtdth = 64,
    sfx_cacdth = 65,
    sfx_skldth = 66,
    sfx_brsdth = 67,
    sfx_cybdth = 68,
    sfx_spidth = 69,
    sfx_bspdth = 70,
    sfx_vildth = 71,
    sfx_kntdth = 72,
    sfx_pedth = 73,
    sfx_skedth = 74,
    sfx_posact = 75,
    sfx_bgact = 76,
    sfx_dmact = 77,
    sfx_bspact = 78,
    sfx_bspwlk = 79,
    sfx_vilact = 80,
    sfx_noway = 81,
    sfx_barexp = 82,
    sfx_punch = 83,
    sfx_hoof = 84,
    sfx_metal = 85,
    sfx_chgun = 86,
    sfx_tink = 87,
    sfx_bdopn = 88,
    sfx_bdcls = 89,
    sfx_itmbk = 90,
    sfx_flame = 91,
    sfx_flamst = 92,
    sfx_getpow = 93,
    sfx_bospit = 94,
    sfx_boscub = 95,
    sfx_bossit = 96,
    sfx_bospn = 97,
    sfx_bosdth = 98,
    sfx_manatk = 99,
    sfx_mandth = 100,
    sfx_sssit = 101,
    sfx_ssdth = 102,
    sfx_keenpn = 103,
    sfx_keendt = 104,
    sfx_skeact = 105,
    sfx_skesit = 106,
    sfx_skeatk = 107,
    sfx_radio = 108
}

sounds.musicenum = {
    mus_None = 0,
    mus_e1m1 = 1,
    mus_e1m2 = 2,
    mus_e1m3 = 3,
    mus_e1m4 = 4,
    mus_e1m5 = 5,
    mus_e1m6 = 6,
    mus_e1m7 = 7,
    mus_e1m8 = 8,
    mus_e1m9 = 9,
    mus_e2m1 = 10,
    mus_e2m2 = 11,
    mus_e2m3 = 12,
    mus_e2m4 = 13,
    mus_e2m5 = 14,
    mus_e2m6 = 15,
    mus_e2m7 = 16,
    mus_e2m8 = 17,
    mus_e2m9 = 18,
    mus_e3m1 = 19,
    mus_e3m2 = 20,
    mus_e3m3 = 21,
    mus_e3m4 = 22,
    mus_e3m5 = 23,
    mus_e3m6 = 24,
    mus_e3m7 = 25,
    mus_e3m8 = 26,
    mus_e3m9 = 27,
    mus_inter = 28,
    mus_intro = 29,
    mus_bunny = 30,
    mus_victor = 31,
    mus_introa = 32,
    mus_runnin = 33,
    mus_stalks = 34,
    mus_countd = 35,
    mus_betwee = 36,
    mus_doom = 37,
    mus_the_da = 38,
    mus_shawn = 39,
    mus_ddtblu = 40,
    mus_in_cit = 41,
    mus_dead = 42,
    mus_stlks2 = 43,
    mus_theda2 = 44,
    mus_doom2 = 45,
    mus_ddtbl2 = 46,
    mus_runni2 = 47,
    mus_dead2 = 48,
    mus_stlks3 = 49,
    mus_romero = 50,
    mus_shawn2 = 51,
    mus_messag = 52,
    mus_count2 = 53,
    mus_ddtbl3 = 54,
    mus_ampie = 55,
    mus_theda3 = 56,
    mus_adrian = 57,
    mus_messg2 = 58,
    mus_romer2 = 59,
    mus_tense = 60,
    mus_shawn3 = 61,
    mus_openin = 62,
    mus_evil = 63,
    mus_ultima = 64,
    mus_read_m = 65,
    mus_dm2ttl = 66,
    mus_dm2int = 67
}

sounds.NUMSFX = 109
sounds.NUMMUSIC = 68

sounds.S_sfx = {
    { name = "none", priority = 0, link = nil, pitch = 0, volume = 0 },  -- sfx_None
    { name = "pistol", priority = 64, link = nil, pitch = 0, volume = 0 },  -- sfx_pistol
    { name = "shotgn", priority = 64, link = nil, pitch = 0, volume = 0 },  -- sfx_shotgn
    { name = "sgcock", priority = 64, link = nil, pitch = 0, volume = 0 },  -- sfx_sgcock
    { name = "dshtgn", priority = 64, link = nil, pitch = 0, volume = 0 },  -- sfx_dshtgn
    { name = "dbopn", priority = 64, link = nil, pitch = 0, volume = 0 },  -- sfx_dbopn
    { name = "dbcls", priority = 64, link = nil, pitch = 0, volume = 0 },  -- sfx_dbcls
    { name = "dbload", priority = 64, link = nil, pitch = 0, volume = 0 },  -- sfx_dbload
    { name = "plasma", priority = 64, link = nil, pitch = 0, volume = 0 },  -- sfx_plasma
    { name = "bfg", priority = 64, link = nil, pitch = 0, volume = 0 },  -- sfx_bfg
    { name = "sawup", priority = 64, link = nil, pitch = 0, volume = 0 },  -- sfx_sawup
    { name = "sawidl", priority = 118, link = nil, pitch = 0, volume = 0 },  -- sfx_sawidl
    { name = "sawful", priority = 64, link = nil, pitch = 0, volume = 0 },  -- sfx_sawful
    { name = "sawhit", priority = 64, link = nil, pitch = 0, volume = 0 },  -- sfx_sawhit
    { name = "rlaunc", priority = 64, link = nil, pitch = 0, volume = 0 },  -- sfx_rlaunc
    { name = "rxplod", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_rxplod
    { name = "firsht", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_firsht
    { name = "firxpl", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_firxpl
    { name = "pstart", priority = 100, link = nil, pitch = 0, volume = 0 },  -- sfx_pstart
    { name = "pstop", priority = 100, link = nil, pitch = 0, volume = 0 },  -- sfx_pstop
    { name = "doropn", priority = 100, link = nil, pitch = 0, volume = 0 },  -- sfx_doropn
    { name = "dorcls", priority = 100, link = nil, pitch = 0, volume = 0 },  -- sfx_dorcls
    { name = "stnmov", priority = 119, link = nil, pitch = 0, volume = 0 },  -- sfx_stnmov
    { name = "swtchn", priority = 78, link = nil, pitch = 0, volume = 0 },  -- sfx_swtchn
    { name = "swtchx", priority = 78, link = nil, pitch = 0, volume = 0 },  -- sfx_swtchx
    { name = "plpain", priority = 96, link = nil, pitch = 0, volume = 0 },  -- sfx_plpain
    { name = "dmpain", priority = 96, link = nil, pitch = 0, volume = 0 },  -- sfx_dmpain
    { name = "popain", priority = 96, link = nil, pitch = 0, volume = 0 },  -- sfx_popain
    { name = "vipain", priority = 96, link = nil, pitch = 0, volume = 0 },  -- sfx_vipain
    { name = "mnpain", priority = 96, link = nil, pitch = 0, volume = 0 },  -- sfx_mnpain
    { name = "pepain", priority = 96, link = nil, pitch = 0, volume = 0 },  -- sfx_pepain
    { name = "slop", priority = 78, link = nil, pitch = 0, volume = 0 },  -- sfx_slop
    { name = "itemup", priority = 78, link = nil, pitch = 0, volume = 0 },  -- sfx_itemup
    { name = "wpnup", priority = 78, link = nil, pitch = 0, volume = 0 },  -- sfx_wpnup
    { name = "oof", priority = 96, link = nil, pitch = 0, volume = 0 },  -- sfx_oof
    { name = "telept", priority = 32, link = nil, pitch = 0, volume = 0 },  -- sfx_telept
    { name = "posit1", priority = 98, link = nil, pitch = 0, volume = 0 },  -- sfx_posit1
    { name = "posit2", priority = 98, link = nil, pitch = 0, volume = 0 },  -- sfx_posit2
    { name = "posit3", priority = 98, link = nil, pitch = 0, volume = 0 },  -- sfx_posit3
    { name = "bgsit1", priority = 98, link = nil, pitch = 0, volume = 0 },  -- sfx_bgsit1
    { name = "bgsit2", priority = 98, link = nil, pitch = 0, volume = 0 },  -- sfx_bgsit2
    { name = "sgtsit", priority = 98, link = nil, pitch = 0, volume = 0 },  -- sfx_sgtsit
    { name = "cacsit", priority = 98, link = nil, pitch = 0, volume = 0 },  -- sfx_cacsit
    { name = "brssit", priority = 94, link = nil, pitch = 0, volume = 0 },  -- sfx_brssit
    { name = "cybsit", priority = 92, link = nil, pitch = 0, volume = 0 },  -- sfx_cybsit
    { name = "spisit", priority = 90, link = nil, pitch = 0, volume = 0 },  -- sfx_spisit
    { name = "bspsit", priority = 90, link = nil, pitch = 0, volume = 0 },  -- sfx_bspsit
    { name = "kntsit", priority = 90, link = nil, pitch = 0, volume = 0 },  -- sfx_kntsit
    { name = "vilsit", priority = 90, link = nil, pitch = 0, volume = 0 },  -- sfx_vilsit
    { name = "mansit", priority = 90, link = nil, pitch = 0, volume = 0 },  -- sfx_mansit
    { name = "pesit", priority = 90, link = nil, pitch = 0, volume = 0 },  -- sfx_pesit
    { name = "sklatk", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_sklatk
    { name = "sgtatk", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_sgtatk
    { name = "skepch", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_skepch
    { name = "vilatk", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_vilatk
    { name = "claw", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_claw
    { name = "skeswg", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_skeswg
    { name = "pldeth", priority = 32, link = nil, pitch = 0, volume = 0 },  -- sfx_pldeth
    { name = "pdiehi", priority = 32, link = nil, pitch = 0, volume = 0 },  -- sfx_pdiehi
    { name = "podth1", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_podth1
    { name = "podth2", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_podth2
    { name = "podth3", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_podth3
    { name = "bgdth1", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_bgdth1
    { name = "bgdth2", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_bgdth2
    { name = "sgtdth", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_sgtdth
    { name = "cacdth", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_cacdth
    { name = "skldth", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_skldth
    { name = "brsdth", priority = 32, link = nil, pitch = 0, volume = 0 },  -- sfx_brsdth
    { name = "cybdth", priority = 32, link = nil, pitch = 0, volume = 0 },  -- sfx_cybdth
    { name = "spidth", priority = 32, link = nil, pitch = 0, volume = 0 },  -- sfx_spidth
    { name = "bspdth", priority = 32, link = nil, pitch = 0, volume = 0 },  -- sfx_bspdth
    { name = "vildth", priority = 32, link = nil, pitch = 0, volume = 0 },  -- sfx_vildth
    { name = "kntdth", priority = 32, link = nil, pitch = 0, volume = 0 },  -- sfx_kntdth
    { name = "pedth", priority = 32, link = nil, pitch = 0, volume = 0 },  -- sfx_pedth
    { name = "skedth", priority = 32, link = nil, pitch = 0, volume = 0 },  -- sfx_skedth
    { name = "posact", priority = 120, link = nil, pitch = 0, volume = 0 },  -- sfx_posact
    { name = "bgact", priority = 120, link = nil, pitch = 0, volume = 0 },  -- sfx_bgact
    { name = "dmact", priority = 120, link = nil, pitch = 0, volume = 0 },  -- sfx_dmact
    { name = "bspact", priority = 100, link = nil, pitch = 0, volume = 0 },  -- sfx_bspact
    { name = "bspwlk", priority = 100, link = nil, pitch = 0, volume = 0 },  -- sfx_bspwlk
    { name = "vilact", priority = 100, link = nil, pitch = 0, volume = 0 },  -- sfx_vilact
    { name = "noway", priority = 78, link = nil, pitch = 0, volume = 0 },  -- sfx_noway
    { name = "barexp", priority = 60, link = nil, pitch = 0, volume = 0 },  -- sfx_barexp
    { name = "punch", priority = 64, link = nil, pitch = 0, volume = 0 },  -- sfx_punch
    { name = "hoof", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_hoof
    { name = "metal", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_metal
    { name = "chgun", priority = 64, link = 1, pitch = 150, volume = 0 },  -- sfx_chgun
    { name = "tink", priority = 60, link = nil, pitch = 0, volume = 0 },  -- sfx_tink
    { name = "bdopn", priority = 100, link = nil, pitch = 0, volume = 0 },  -- sfx_bdopn
    { name = "bdcls", priority = 100, link = nil, pitch = 0, volume = 0 },  -- sfx_bdcls
    { name = "itmbk", priority = 100, link = nil, pitch = 0, volume = 0 },  -- sfx_itmbk
    { name = "flame", priority = 32, link = nil, pitch = 0, volume = 0 },  -- sfx_flame
    { name = "flamst", priority = 32, link = nil, pitch = 0, volume = 0 },  -- sfx_flamst
    { name = "getpow", priority = 60, link = nil, pitch = 0, volume = 0 },  -- sfx_getpow
    { name = "bospit", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_bospit
    { name = "boscub", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_boscub
    { name = "bossit", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_bossit
    { name = "bospn", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_bospn
    { name = "bosdth", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_bosdth
    { name = "manatk", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_manatk
    { name = "mandth", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_mandth
    { name = "sssit", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_sssit
    { name = "ssdth", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_ssdth
    { name = "keenpn", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_keenpn
    { name = "keendt", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_keendt
    { name = "skeact", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_skeact
    { name = "skesit", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_skesit
    { name = "skeatk", priority = 70, link = nil, pitch = 0, volume = 0 },  -- sfx_skeatk
    { name = "radio", priority = 60, link = nil, pitch = 0, volume = 0 },  -- sfx_radio
}

sounds.S_music = {
    { name = nil, lumpnum = 0, data = nil, handle = nil },  -- mus_None
    { name = "e1m1", lumpnum = 0, data = nil, handle = nil },  -- mus_e1m1
    { name = "e1m2", lumpnum = 0, data = nil, handle = nil },  -- mus_e1m2
    { name = "e1m3", lumpnum = 0, data = nil, handle = nil },  -- mus_e1m3
    { name = "e1m4", lumpnum = 0, data = nil, handle = nil },  -- mus_e1m4
    { name = "e1m5", lumpnum = 0, data = nil, handle = nil },  -- mus_e1m5
    { name = "e1m6", lumpnum = 0, data = nil, handle = nil },  -- mus_e1m6
    { name = "e1m7", lumpnum = 0, data = nil, handle = nil },  -- mus_e1m7
    { name = "e1m8", lumpnum = 0, data = nil, handle = nil },  -- mus_e1m8
    { name = "e1m9", lumpnum = 0, data = nil, handle = nil },  -- mus_e1m9
    { name = "e2m1", lumpnum = 0, data = nil, handle = nil },  -- mus_e2m1
    { name = "e2m2", lumpnum = 0, data = nil, handle = nil },  -- mus_e2m2
    { name = "e2m3", lumpnum = 0, data = nil, handle = nil },  -- mus_e2m3
    { name = "e2m4", lumpnum = 0, data = nil, handle = nil },  -- mus_e2m4
    { name = "e2m5", lumpnum = 0, data = nil, handle = nil },  -- mus_e2m5
    { name = "e2m6", lumpnum = 0, data = nil, handle = nil },  -- mus_e2m6
    { name = "e2m7", lumpnum = 0, data = nil, handle = nil },  -- mus_e2m7
    { name = "e2m8", lumpnum = 0, data = nil, handle = nil },  -- mus_e2m8
    { name = "e2m9", lumpnum = 0, data = nil, handle = nil },  -- mus_e2m9
    { name = "e3m1", lumpnum = 0, data = nil, handle = nil },  -- mus_e3m1
    { name = "e3m2", lumpnum = 0, data = nil, handle = nil },  -- mus_e3m2
    { name = "e3m3", lumpnum = 0, data = nil, handle = nil },  -- mus_e3m3
    { name = "e3m4", lumpnum = 0, data = nil, handle = nil },  -- mus_e3m4
    { name = "e3m5", lumpnum = 0, data = nil, handle = nil },  -- mus_e3m5
    { name = "e3m6", lumpnum = 0, data = nil, handle = nil },  -- mus_e3m6
    { name = "e3m7", lumpnum = 0, data = nil, handle = nil },  -- mus_e3m7
    { name = "e3m8", lumpnum = 0, data = nil, handle = nil },  -- mus_e3m8
    { name = "e3m9", lumpnum = 0, data = nil, handle = nil },  -- mus_e3m9
    { name = "inter", lumpnum = 0, data = nil, handle = nil },  -- mus_inter
    { name = "intro", lumpnum = 0, data = nil, handle = nil },  -- mus_intro
    { name = "bunny", lumpnum = 0, data = nil, handle = nil },  -- mus_bunny
    { name = "victor", lumpnum = 0, data = nil, handle = nil },  -- mus_victor
    { name = "introa", lumpnum = 0, data = nil, handle = nil },  -- mus_introa
    { name = "runnin", lumpnum = 0, data = nil, handle = nil },  -- mus_runnin
    { name = "stalks", lumpnum = 0, data = nil, handle = nil },  -- mus_stalks
    { name = "countd", lumpnum = 0, data = nil, handle = nil },  -- mus_countd
    { name = "betwee", lumpnum = 0, data = nil, handle = nil },  -- mus_betwee
    { name = "doom", lumpnum = 0, data = nil, handle = nil },  -- mus_doom
    { name = "the_da", lumpnum = 0, data = nil, handle = nil },  -- mus_the_da
    { name = "shawn", lumpnum = 0, data = nil, handle = nil },  -- mus_shawn
    { name = "ddtblu", lumpnum = 0, data = nil, handle = nil },  -- mus_ddtblu
    { name = "in_cit", lumpnum = 0, data = nil, handle = nil },  -- mus_in_cit
    { name = "dead", lumpnum = 0, data = nil, handle = nil },  -- mus_dead
    { name = "stlks2", lumpnum = 0, data = nil, handle = nil },  -- mus_stlks2
    { name = "theda2", lumpnum = 0, data = nil, handle = nil },  -- mus_theda2
    { name = "doom2", lumpnum = 0, data = nil, handle = nil },  -- mus_doom2
    { name = "ddtbl2", lumpnum = 0, data = nil, handle = nil },  -- mus_ddtbl2
    { name = "runni2", lumpnum = 0, data = nil, handle = nil },  -- mus_runni2
    { name = "dead2", lumpnum = 0, data = nil, handle = nil },  -- mus_dead2
    { name = "stlks3", lumpnum = 0, data = nil, handle = nil },  -- mus_stlks3
    { name = "romero", lumpnum = 0, data = nil, handle = nil },  -- mus_romero
    { name = "shawn2", lumpnum = 0, data = nil, handle = nil },  -- mus_shawn2
    { name = "messag", lumpnum = 0, data = nil, handle = nil },  -- mus_messag
    { name = "count2", lumpnum = 0, data = nil, handle = nil },  -- mus_count2
    { name = "ddtbl3", lumpnum = 0, data = nil, handle = nil },  -- mus_ddtbl3
    { name = "ampie", lumpnum = 0, data = nil, handle = nil },  -- mus_ampie
    { name = "theda3", lumpnum = 0, data = nil, handle = nil },  -- mus_theda3
    { name = "adrian", lumpnum = 0, data = nil, handle = nil },  -- mus_adrian
    { name = "messg2", lumpnum = 0, data = nil, handle = nil },  -- mus_messg2
    { name = "romer2", lumpnum = 0, data = nil, handle = nil },  -- mus_romer2
    { name = "tense", lumpnum = 0, data = nil, handle = nil },  -- mus_tense
    { name = "shawn3", lumpnum = 0, data = nil, handle = nil },  -- mus_shawn3
    { name = "openin", lumpnum = 0, data = nil, handle = nil },  -- mus_openin
    { name = "evil", lumpnum = 0, data = nil, handle = nil },  -- mus_evil
    { name = "ultima", lumpnum = 0, data = nil, handle = nil },  -- mus_ultima
    { name = "read_m", lumpnum = 0, data = nil, handle = nil },  -- mus_read_m
    { name = "dm2ttl", lumpnum = 0, data = nil, handle = nil },  -- mus_dm2ttl
    { name = "dm2int", lumpnum = 0, data = nil, handle = nil },  -- mus_dm2int
}

return sounds