--!native
--!optimize 2
local m_cheat = {}

local MAX_CHEAT_PARAMS = 5

-- m_cheat.CHEAT(value, parameters)
function m_cheat.CHEAT(value, parameters)
    return {
        sequence = value,
        sequence_len = #value - 1, -- sizeof(value) - 1 (excluding NUL)
        parameter_chars = parameters,
        chars_read = 0,
        param_chars_read = 0,
        parameter_buf = "",
    }
end

-- cht_CheckCheat: returns true if the cheat was matched.
function m_cheat.cht_CheckCheat(cht, key)
    key = bit32.band(key, 0xff) -- C: int -> char truncation

    -- If we make a short sequence on a cheat with parameters, this will not
    -- work in vanilla doom. Behave the same.
    if cht.parameter_chars > 0 and #cht.sequence < cht.sequence_len then
        return false
    end

    if cht.chars_read < #cht.sequence then
        -- Still reading characters from the cheat code and verifying.
        -- Reset back to the beginning if a key is wrong.
        if key == string.byte(cht.sequence, cht.chars_read + 1) then
            cht.chars_read = cht.chars_read + 1
        else
            cht.chars_read = 0
        end
        cht.param_chars_read = 0
    elseif cht.param_chars_read < cht.parameter_chars then
        -- We have passed the end of the cheat sequence and are entering
        -- parameters now.
        cht.parameter_buf = cht.parameter_buf .. string.char(key)
        cht.param_chars_read = cht.param_chars_read + 1
    end

    if cht.chars_read >= #cht.sequence
        and cht.param_chars_read >= cht.parameter_chars then
        cht.chars_read = 0
        cht.param_chars_read = 0
        return true
    end

    return false -- cheat not matched yet
end

-- cht_GetParam: return the parameter characters read so far.
function m_cheat.cht_GetParam(cht)
    return cht.parameter_buf
end

return m_cheat