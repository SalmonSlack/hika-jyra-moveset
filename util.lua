---Checks if a value is in a list
---@param value any
---@param list any[]
---@return boolean
function is_value_in_list(value, list)
    for i = 1, #list do
        if value == list[i] then return true end
    end
    return false
end

---Shakes the camera and plays a sound effect to create a more impactful contact with the ground
---@param m MarioState
function create_impact_effects(m)
    set_camera_shake_from_hit(SHAKE_ENV_BOWSER_JUMP)
    play_sound(SOUND_OBJ_BOWSER_WALK, m.marioObj.header.gfx.cameraToObject)
    set_mario_particle_flags(m, PARTICLE_MIST_CIRCLE, 0)
    set_mario_particle_flags(m, PARTICLE_HORIZONTAL_STAR, 0)
end

---Shakes the camera and plays a sound effect to create a more impactful contact with walls
---@param m MarioState
function create_wall_impact_effects(m)
    set_camera_shake_from_hit(SHAKE_ENV_BOWSER_JUMP)
    play_sound(SOUND_OBJ_BOWSER_WALK, m.marioObj.header.gfx.cameraToObject)
    set_mario_particle_flags(m, PARTICLE_VERTICAL_STAR, 0)
end

-- Plays Hikaseru's air jump sound effect
---@param m MarioState
function play_hika_air_jump_sound(m)
    local vol = 1.0
    local sample = math.random() < 0.5 and HIKA_AIR_JUMP_1 or HIKA_AIR_JUMP_2
    if is_game_paused() then vol = 0.1 end
    audio_sample_stop(sample)
    audio_sample_play(sample, m.pos, vol)
end

-- Plays Hikaseru's wall bounce sound effect
---@param m MarioState
function play_hika_wall_bounce_sound(m)
    local vol = 1.0
    local sample = HIKA_BOING_1
    if is_game_paused() then vol = 0.1 end
    audio_sample_stop(sample)
    audio_sample_play(sample, m.pos, vol)
end
