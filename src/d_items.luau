--!native
--!optimize 2
local d_items = {}

d_items.NUMWEAPONS = 9

d_items.weaponinfo = {
    { ammo = 5, upstate = 4, downstate = 3, readystate = 2, atkstate = 5, flashstate = 0 },  -- wp_fist
    { ammo = 0, upstate = 12, downstate = 11, readystate = 10, atkstate = 13, flashstate = 17 },  -- wp_pistol
    { ammo = 1, upstate = 20, downstate = 19, readystate = 18, atkstate = 21, flashstate = 30 },  -- wp_shotgun
    { ammo = 0, upstate = 51, downstate = 50, readystate = 49, atkstate = 52, flashstate = 55 },  -- wp_chaingun
    { ammo = 3, upstate = 59, downstate = 58, readystate = 57, atkstate = 60, flashstate = 63 },  -- wp_missile
    { ammo = 2, upstate = 76, downstate = 75, readystate = 74, atkstate = 77, flashstate = 79 },  -- wp_plasma
    { ammo = 2, upstate = 83, downstate = 82, readystate = 81, atkstate = 84, flashstate = 88 },  -- wp_bfg
    { ammo = 5, upstate = 70, downstate = 69, readystate = 67, atkstate = 71, flashstate = 0 },  -- wp_chainsaw
    { ammo = 1, upstate = 34, downstate = 33, readystate = 32, atkstate = 35, flashstate = 47 },  -- wp_supershotgun
}

return d_items