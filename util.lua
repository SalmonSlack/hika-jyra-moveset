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