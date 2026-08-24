--!native
--!optimize 2
local m_misc = {}

-- M_StringCopy(src, dest_size): copy up to dest_size-1 characters.
-- Returns (result, not_truncated).
function m_misc.M_StringCopy(src, dest_size)
    src = src or ""
    local maxlen = dest_size - 1
    if maxlen < 0 then
        maxlen = 0
    end
    local result = string.sub(src, 1, maxlen)
    return result, #result == #src
end

-- M_StringConcat(dest, src, dest_size): concatenate, truncating to
-- dest_size-1 total characters. Returns (result, not_truncated).
function m_misc.M_StringConcat(dest, src, dest_size)
    return m_misc.M_StringCopy(dest .. (src or ""), dest_size)
end

-- M_StringStartsWith(s, prefix)
function m_misc.M_StringStartsWith(s, prefix)
    return string.sub(s, 1, #prefix) == prefix and #s > #prefix
end

-- M_StringEndsWith(s, suffix)
function m_misc.M_StringEndsWith(s, suffix)
    return string.sub(s, -(#suffix)) == suffix and #s >= #suffix
end

-- M_StringDuplicate(orig): strings are immutable in Lua; just return orig.
function m_misc.M_StringDuplicate(orig)
    return orig
end

-- M_StringJoin(...): concatenate all string args; stop at the first nil
-- (mirrors C's NULL-terminated va_list).
function m_misc.M_StringJoin(...)
    local n = select("#", ...)
    local result = ""
    for i = 1, n do
        local v = select(i, ...)
        if v == nil then
            break
        end
        result = result .. v
    end
    return result
end

-- M_StrCaseStr: case-insensitive strstr(). Returns the match start (1-based)
-- or nil.
function m_misc.M_StrCaseStr(haystack, needle)
    local hlen = #haystack
    local nlen = #needle
    if hlen < nlen then
        return nil
    end
    local lower_h = string.lower(haystack)
    local lower_n = string.lower(needle)
    for i = 1, hlen - nlen + 1 do
        if string.sub(lower_h, i, i + nlen - 1) == lower_n then
            return i
        end
    end
    return nil
end

-- M_StringReplace(haystack, needle, replacement): replace all occurrences.
function m_misc.M_StringReplace(haystack, needle, replacement)
    local result = ""
    local pos = 1
    local nlen = #needle
    while pos <= #haystack do
        if string.sub(haystack, pos, pos + nlen - 1) == needle then
            result = result .. replacement
            pos = pos + nlen
        else
            result = result .. string.sub(haystack, pos, pos)
            pos = pos + 1
        end
    end
    return result
end

-- M_ExtractFileBase(path): extract the 8-char uppercase base name of a path
-- (truncated to 8 chars, like the C 8.3 filename limit).
function m_misc.M_ExtractFileBase(path)
    -- Everything after the last '/' or '\' (the C code backs up to the last
    -- DIR_SEPARATOR). The greedy `.*` leaves the final slash + suffix for the
    -- capture, so this handles paths both with and without separators.
    local base = string.match(path, ".*[/\\]([^/\\]*)$")
    if base == nil then
        base = path
    end
    -- Strip the extension: everything from the last '.' to the end.
    base = string.gsub(base, "%.[^.]*$", "")
    if #base > 8 then
        print(string.format(
            "Warning: Truncated '%s' lump name to '%.8s'.",
            base, string.sub(base, 1, 8)))
        base = string.sub(base, 1, 8)
    end
    return string.upper(base)
end

-- M_ForceUppercase(text)
function m_misc.M_ForceUppercase(text)
    return string.upper(text)
end

-- M_snprintf: safe printf into a Lua string (strings are immutable, so the
-- result is returned rather than written to a caller buffer). Uses Lua's
-- string.format, which supports the %s/%d/%i/%u/%f/%x/%02i forms used by the
-- C code.
function m_misc.M_snprintf(fmt, ...)
    return string.format(fmt, ...)
end

-- M_StrToInt(str): parse an integer (hex 0x, octal 0, or decimal).
-- Returns (value, success).
function m_misc.M_StrToInt(str)
    str = string.gsub(str, "^%s+", "")
    local prefix = string.sub(str, 1, 2)
    if prefix == "0x" or prefix == "0X" then
        local v = tonumber(string.sub(str, 3), 16)
        if v ~= nil then
            return v, true
        end
        return 0, false
    end
    if string.sub(str, 1, 1) == "0" then
        local v = tonumber(str, 8)
        if v ~= nil then
            return v, true
        end
    end
    local v = tonumber(str, 10)
    if v ~= nil then
        return v, true
    end
    return 0, false
end

return m_misc