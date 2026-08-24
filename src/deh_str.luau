--!native
--!optimize 2
local deh_str = {}

-- DEH_String(s): no-op string replacement.
function deh_str.DEH_String(s)
    return s
end

-- DEH_printf: printf with the DEH_ prefix (identity in v1).
function deh_str.DEH_printf(fmt, ...)
    print(string.format(fmt, ...))
end

-- DEH_snprintf: returns the formatted string (see m_misc.M_snprintf).
function deh_str.DEH_snprintf(fmt, ...)
    return string.format(fmt, ...)
end

-- DEH_AddStringReplacement: no-op (DeHacked disabled).
function deh_str.DEH_AddStringReplacement(from_text, to_text)
end

return deh_str