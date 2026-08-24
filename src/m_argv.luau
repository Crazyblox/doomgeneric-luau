--!native
--!optimize 2
local m_argv = {}

-- `myargv` is a list of strings. Index 1 is the executable name (as in C).
m_argv.myargv = {}
m_argv.myargc = 0

-- M_CheckParmWithArgs:
--   returns the argument index i (1..myargc-1) if myargv[i] == check
--   (case-insensitive) and at least num_args arguments follow it, else 0.
function m_argv.M_CheckParmWithArgs(check, num_args)
    local lower = string.lower(check)
    for i = 2, m_argv.myargc - num_args do
        if string.lower(m_argv.myargv[i]) == lower then
            return i
        end
    end
    return 0
end

-- M_CheckParm: returns the position of the given parameter (0 if not found).
function m_argv.M_CheckParm(check)
    return m_argv.M_CheckParmWithArgs(check, 0)
end

-- Parameter has been specified?
function m_argv.M_ParmExists(check)
    return m_argv.M_CheckParm(check) ~= 0
end

-- Set the argument list (called by DoomGeneric.Create).
function m_argv.SetArgs(args)
    m_argv.myargv = args or {}
    m_argv.myargc = #m_argv.myargv
end

-- Get the name of the executable used to run the program (myargv[1] base).
function m_argv.M_GetExecutableName()
    local arg0 = m_argv.myargv[1] or ""
    -- Greedy match up to the last '/' (DIR_SEPARATOR).
    local prefix = string.match(arg0, ".*/")
    if prefix == nil then
        return arg0
    end
    return string.sub(arg0, #prefix + 1)
end

-- M_FindResponseFile: no-op in this port (response files are ORIGCODE-only).
function m_argv.M_FindResponseFile()
end

return m_argv