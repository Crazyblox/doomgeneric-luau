--!native
--!optimize 2
local i_system = {}

-- atexit registry: { func, run_on_error } entries.
local exit_funcs = {}
local already_quitting = false

-- I_AtExit: schedule a function to be called when the program exits.
-- If run_on_error is true, the function is also called on I_Error.
function i_system.I_AtExit(func, run_on_error)
    table.insert(exit_funcs, { func = func, run_on_error = run_on_error })
end

-- I_Quit: clean exit; runs all exit functions.
function i_system.I_Quit()
    for _, entry in ipairs(exit_funcs) do
        entry.func()
    end
    exit_funcs = {}
end

-- Format an error message the way C's vfprintf would (simple %s / %d).
local function format_error(fmt, args)
    -- Minimal printf-style formatting: %s, %d, %i, %u, %f, %x
    local i = 1
    local out = fmt:gsub("%%[sdifu]", function()
        local v = args[i]
        i = i + 1
        if v == nil then
            return ""
        end
        return tostring(v)
    end)
    -- %f (floating point, used by G_CheckDemoStatus's timedemo report).
    out = out:gsub("%%f", function()
        local v = args[i]
        i = i + 1
        if v == nil then
            return ""
        end
        return string.format("%f", v)
    end)
    return out
end

-- I_Error: print the message, run run-on-error exit handlers, then raise.
function i_system.I_Error(fmt, ...)
    local msg = format_error(fmt, { ... })

    if already_quitting then
        print("Warning: recursive call to I_Error detected.")
        error("I_Error: " .. msg)
    end
    already_quitting = true

    print("\nError: " .. msg .. "\n")

    for _, entry in ipairs(exit_funcs) do
        if entry.run_on_error then
            entry.func()
        end
    end

    error("I_Error: " .. msg)
end

-- I_Tactile: no-op (Logitech Cyberman feedback, unused).
function i_system.I_Tactile()
end

-- I_ZoneBase: the zone allocator is replaced by Lua GC; returns a size hint.
function i_system.I_ZoneBase()
    return 6 * 1024 * 1024 -- DEFAULT_RAM
end

-- I_ConsoleStdout: always false in the port (no terminal detection).
function i_system.I_ConsoleStdout()
    return false
end

-- Banners (startup output).

function i_system.I_PrintDivider()
    print(string.rep("=", 75))
end

function i_system.I_PrintBanner(msg)
    local spaces = 35 - (#msg // 2)
    print(string.rep(" ", spaces) .. msg)
end

function i_system.I_PrintStartupBanner(gamedescription)
    i_system.I_PrintDivider()
    i_system.I_PrintBanner(gamedescription)
    i_system.I_PrintDivider()
    print("Doom Generic is free software, covered by the GNU General Public")
    print("License.  There is NO warranty; not even for MERCHANTABILITY or")
    print("FITNESS FOR A PARTICULAR PURPOSE. You are welcome to change and")
    print("distribute copies under certain conditions. See the source for")
    print("more information.")
    i_system.I_PrintDivider()
end

-- I_GetMemoryValue: DOS NULL-pointer emulation; unused in the Luau port.
function i_system.I_GetMemoryValue()
    return false
end

-- I_BindVariables / I_Init: later phases bind config variables.
function i_system.I_BindVariables()
end

function i_system.I_Init()
end

return i_system