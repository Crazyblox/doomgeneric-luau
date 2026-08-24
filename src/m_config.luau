--!native
--!optimize 2
local doomkeys = require("./doomkeys")
local m_config = {}

-- default_type_t
m_config.DEFAULT_INT = 0
m_config.DEFAULT_INT_HEX = 1
m_config.DEFAULT_STRING = 2
m_config.DEFAULT_FLOAT = 3
m_config.DEFAULT_KEY = 4

-- Location where all configuration data is stored.
m_config.configdir = ""

-- Default filenames for configuration files.
m_config.default_main_config = "default.cfg"
m_config.default_extra_config = "doom.cfg"

-- Registered bindings: name -> { tbl, field, type, bound }.
local bindings = {}

-- Search a binding by name.
local function get_binding(name)
    return bindings[name]
end

-- M_BindVariable: bind a config variable name to a field of a module table.
function m_config.M_BindVariable(name, tbl, field, type)
    local binding = get_binding(name)
    if binding == nil then
        binding = { tbl = tbl, field = field, type = type, bound = true }
        bindings[name] = binding
    else
        binding.tbl = tbl
        binding.field = field
        binding.type = type
        binding.bound = true
    end
end

-- ---------------------------------------------------------------------------
-- Scancode -> internal key translation (from m_config.c scantokey[]).
-- ---------------------------------------------------------------------------

local scantokey = {
    0, 27, string.byte("1"), string.byte("2"), string.byte("3"),
    string.byte("4"), string.byte("5"), string.byte("6"),
    string.byte("7"), string.byte("8"), string.byte("9"), string.byte("0"),
    string.byte("-"), string.byte("="), doomkeys.KEY_BACKSPACE, 9,
    string.byte("q"), string.byte("w"), string.byte("e"), string.byte("r"),
    string.byte("t"), string.byte("y"), string.byte("u"), string.byte("i"),
    string.byte("o"), string.byte("p"), string.byte("["), string.byte("]"),
    13, doomkeys.KEY_RCTRL, string.byte("a"), string.byte("s"),
    string.byte("d"), string.byte("f"), string.byte("g"), string.byte("h"),
    string.byte("j"), string.byte("k"), string.byte("l"), string.byte(";"),
    string.byte("'"), string.byte("`"), doomkeys.KEY_RSHIFT, string.byte("\\"),
    string.byte("z"), string.byte("x"), string.byte("c"), string.byte("v"),
    string.byte("b"), string.byte("n"), string.byte("m"), string.byte(","),
    string.byte("."), string.byte("/"), doomkeys.KEY_RSHIFT,
    doomkeys.KEYP_MULTIPLY,
    doomkeys.KEY_RALT, string.byte(" "), doomkeys.KEY_CAPSLOCK,
    doomkeys.KEY_F1, doomkeys.KEY_F2, doomkeys.KEY_F3, doomkeys.KEY_F4,
    doomkeys.KEY_F5, doomkeys.KEY_F6, doomkeys.KEY_F7, doomkeys.KEY_F8,
    doomkeys.KEY_F9, doomkeys.KEY_F10, doomkeys.KEY_PAUSE,
    doomkeys.KEY_SCRLCK, doomkeys.KEY_HOME,
    doomkeys.KEY_UPARROW, doomkeys.KEY_PGUP, doomkeys.KEY_MINUS,
    doomkeys.KEY_LEFTARROW, doomkeys.KEYP_5, doomkeys.KEY_RIGHTARROW,
    doomkeys.KEYP_PLUS, doomkeys.KEY_END,
    doomkeys.KEY_DOWNARROW, doomkeys.KEY_PGDN, doomkeys.KEY_INS,
    doomkeys.KEY_DEL, 0, 0, 0, doomkeys.KEY_F11,
    doomkeys.KEY_F12, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, doomkeys.KEY_PRTSCR, 0,
}

-- Parse an integer (config-file values may be 0x hex).
local function parse_int(str)
    str = string.gsub(str, "^%s+", "")
    if string.sub(str, 1, 2) == "0x" then
        return tonumber(string.sub(str, 3), 16)
    end
    return tonumber(str, 10)
end

-- Set the value of a particular variable, by name (API function).
function m_config.M_SetVariable(name, value)
    local binding = get_binding(name)
    if binding == nil or not binding.bound then
        return false
    end

    local btype = binding.type

    if btype == m_config.DEFAULT_STRING then
        binding.tbl[binding.field] = value
    elseif btype == m_config.DEFAULT_INT or btype == m_config.DEFAULT_INT_HEX then
        binding.tbl[binding.field] = parse_int(value) or 0
    elseif btype == m_config.DEFAULT_KEY then
        -- Translate scancodes read from the config file to internal keys.
        local intparm = parse_int(value) or 0
        if intparm >= 0 and intparm < 128 then
            binding.tbl[binding.field] = scantokey[intparm + 1]
        else
            binding.tbl[binding.field] = 0
        end
    elseif btype == m_config.DEFAULT_FLOAT then
        binding.tbl[binding.field] = tonumber(value) or 0
    end

    return true
end

-- Get the value of a variable.
function m_config.M_GetIntVariable(name)
    local binding = get_binding(name)
    if binding == nil or not binding.bound
        or (binding.type ~= m_config.DEFAULT_INT
            and binding.type ~= m_config.DEFAULT_INT_HEX) then
        return 0
    end
    return binding.tbl[binding.field]
end

function m_config.M_GetStrVariable(name)
    local binding = get_binding(name)
    if binding == nil or not binding.bound
        or binding.type ~= m_config.DEFAULT_STRING then
        return nil
    end
    return binding.tbl[binding.field]
end

function m_config.M_GetFloatVariable(name)
    local binding = get_binding(name)
    if binding == nil or not binding.bound
        or binding.type ~= m_config.DEFAULT_FLOAT then
        return 0
    end
    return binding.tbl[binding.field]
end

-- M_SetConfigFilenames: record the config filenames (no file I/O in v1).
function m_config.M_SetConfigFilenames(main_config, extra_config)
    m_config.default_main_config = main_config
    m_config.default_extra_config = extra_config
end

-- M_SetConfigDir: record the config directory (no filesystem in v1).
function m_config.M_SetConfigDir(dir)
    if dir ~= nil then
        m_config.configdir = dir
    else
        m_config.configdir = "."
    end
end

-- M_LoadDefaults / M_SaveDefaults: no-ops (config files cut in v1).
function m_config.M_LoadDefaults()
end

function m_config.M_SaveDefaults()
end

function m_config.M_SaveDefaultsAlternate(main, extra)
end

-- M_GetSaveGameDir: savegames are cut in v1; return an empty path.
function m_config.M_GetSaveGameDir(iwadname)
    return ""
end

return m_config