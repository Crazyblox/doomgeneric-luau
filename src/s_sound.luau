--!native
--!optimize 2
local s_sound = {}

-- S_Init: no-op (sound cut in v1).
function s_sound.S_Init(sfxVolume, musicVolume)
end

-- S_Shutdown: no-op.
function s_sound.S_Shutdown()
end

-- S_Start: per-level startup, kills playing sounds at start of level.
-- no-op (sound cut in v1).
function s_sound.S_Start()
end

-- S_StartSound: start a sound for a thing/mobj origin. no-op.
function s_sound.S_StartSound(origin, sound_id)
end

-- S_StopSound: stop sound for a thing. no-op.
function s_sound.S_StopSound(origin)
end

-- S_UpdateSounds: no-op.
function s_sound.S_UpdateSounds(mo)
end

-- S_StartMusic: no-op.
function s_sound.S_StartMusic(music)
end

-- S_ChangeMusic / S_MusicPlaying / S_StopMusic: no-ops.
function s_sound.S_ChangeMusic(music, looping)
end

function s_sound.S_MusicPlaying()
    return false
end

function s_sound.S_StopMusic()
end

-- S_PauseSound / S_ResumeSound: no-ops.
function s_sound.S_PauseSound()
end

function s_sound.S_ResumeSound()
end

-- S_SetMusicVolume / S_SetSfxVolume: no-ops.
function s_sound.S_SetMusicVolume(volume)
end

function s_sound.S_SetSfxVolume(volume)
end

return s_sound