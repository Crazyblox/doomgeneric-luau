### Experimental

Experimental; current state is unfinished and buggy. 

# doomgeneric-to-luau

A Luau port of **Chocolate Doom** (Simon Howard's source-port of the original
Doom engine) with the **doomgeneric** platform glue layer on top.

## Public contract

```lua
local doom = require("./src")

doom.platform = {
    Init = function() end,               -- DG_Init
    DrawFrame = function() end,          -- DG_DrawFrame (reads DG_ScreenBuffer)
    SleepMs = function(ms) end,          -- DG_SleepMs
    GetTicksMs = function() return 0 end,-- DG_GetTicksMs
    GetKey = function() return false, 0 end, -- DG_GetKey -> (pressed, doom keycode)
    SetWindowTitle = function(title) end,-- DG_SetWindowTitle (optional)
}

doom.doomgeneric.SetWAD(wadBuffer)        -- required: raw IWAD bytes
-- doom.doomgeneric.AddPWAD(wadBuffer)         -- not yet implemented

doom.doomgeneric.Create(args)             -- like doomgeneric_Create(argc, argv)
doom.doomgeneric.Tick()                   -- like doomgeneric_Tick(); host calls this
```

`DG_ScreenBuffer` is a `buffer` of `DOOMGENERIC_RESX * DOOMGENERIC_RESY * 4`
bytes (default 640×400 = 1,024,000). Pixel `(x, y)` at
`(y * DOOMGENERIC_RESX + x) * 4`, bytes `[R, G, B, A]`, `A = 255`.
(Deviation from the C port, which is BGRA-in-memory with A=0 — deliberate.)

`DG_GetKey` returns Doom keycodes (`doomkeys.luau`: `KEY_FIRE = 0xa3`,
arrows `0xac..0xaf`, `KEY_ENTER = 13`, `KEY_ESCAPE = 27`, F-keys `0x80+…`).
Shift handling is done inside the engine (`i_input.luau`, a later phase), not
the host.

## 32-bit integer semantics

Luau numbers are doubles, but Doom relies on 32-bit wraparound. Central helpers:

- `m_fixed.luau` — `FixedMul` uses 16-bit split multiplication + `bit32`
  sanitization; `FixedDiv` uses exact truncating division. Unit-tested in
  `tests/test_fixed.luau` against hand-computed C results.
- `tables.luau` — `finetangent`/`finesine` are generated to be **bit-exact**
  with the C `tables.c` by emulating the C generator's float32 angle rounding
  (`string.pack("f")`). `tantoangle` is generated with the C source formula
  (double `atan`, float32-rounded quotient); the C table was produced by a
  legacy float `libm`, so our values differ by at most ±1 BAM unit
  (relative error < 1e-7).
  `gammatable` is embedded verbatim from the C source.

## WAD input

`SetWAD(buffer)` accepts raw IWAD bytes. The WAD is treated as an
in-memory-mapped file: `W_CacheLumpNum(lump)` returns a view
`{ buffer, offset, size }` into the WAD buffer rather than a copy (mirrors
the C memory-mapped path). `PWAD`s are deferred to a later phase.

## License

GPLv2. See `LICENSE`.