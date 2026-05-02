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
    if has_hika_flags(m, _G.hikaMoveset.FLAG_HEAVIER_IMPACT) then
        set_camera_shake_from_hit(SHAKE_ENV_BOWSER_JUMP)
        play_sound(SOUND_OBJ_BOWSER_WALK, m.marioObj.header.gfx.cameraToObject)
    end

    set_mario_particle_flags(m, PARTICLE_MIST_CIRCLE, 0)
    set_mario_particle_flags(m, PARTICLE_HORIZONTAL_STAR, 0)
end

---Shakes the camera and plays a sound effect to create a more impactful contact with walls
---@param m MarioState
function create_wall_impact_effects(m)
    if has_hika_flags(m, _G.hikaMoveset.FLAG_HEAVIER_IMPACT) then
        set_camera_shake_from_hit(SHAKE_ENV_BOWSER_JUMP)
        play_sound(SOUND_OBJ_BOWSER_WALK, m.marioObj.header.gfx.cameraToObject)
    end

    set_mario_particle_flags(m, PARTICLE_VERTICAL_STAR, 0)
end

---Stops playing all the samples in a given list, useful for cancelling an action
---@param samples ModAudio[]
function stop_audio_samples(samples)
    for i = 1, #samples do
        audio_sample_stop(samples[i])
    end
end

function play_audio(sample, pos, vol)
    if is_game_paused() then vol = 0.1 end
    audio_sample_stop(sample)
    audio_sample_play(sample, pos, vol)
end

---Selects a random audio from a given table and plays it at Mario's current position
---@param pos Vec3f
---@param samplesKey string
---@param sampleIndex integer? If specified, gets the specific sample from the sample list
---@return integer
function select_and_play_audio(pos, samplesKey, sampleIndex)
    local sampleIndex = sampleIndex or math.random(1, #SOUNDS_TABLE[samplesKey])
    local sample = SOUNDS_TABLE[samplesKey][sampleIndex]
    local vol = 1.0
    stop_audio_samples(SOUNDS_TABLE[samplesKey])
    play_audio(sample, pos, vol)
    return sampleIndex
end

---Selects a random audio from a given table and play's it at Mario's current position for all players in the area
---@param pos Vec3f
---@param samplesKey string
---@param globalPlayerIndex integer
function network_select_and_play_audio(pos, samplesKey, globalPlayerIndex)
    local sampleIndex = select_and_play_audio(pos, samplesKey, 1.0)
    local networkPlayer = network_player_from_global_index(globalPlayerIndex)

    network_send(false, {
        key = "sendAudioSample",
        sampleIndex = sampleIndex,
        samplesKey = samplesKey,
        posX = pos.x,
        posY = pos.y,
        posZ = pos.z,
        currAreaIndex = networkPlayer.currAreaIndex,
        currActNum = networkPlayer.currActNum,
        currCourseNum = networkPlayer.currCourseNum,
        currLevelNum = networkPlayer.currLevelNum
    })
end

---Checks if a Hikaseru player has the specified flags. Credit to wibblus and her Bowser Moveset for this function
---@param m MarioState
---@return boolean
function has_hika_flags(m, flags)
    return (gPlayerSyncTable[m.playerIndex].hikaState & flags ~= 0)
end

---Applies Hikaseru flags to the current player. hikaState will be 0 for all characters not using Hikaseru's moveset. Credit to wibblus and her Bowser Moveset for this function
function apply_player_hika_flags()
    local flags = gHikaFlagsTable[_G.charSelect.character_get_current_table().model]
    if flags then
        gPlayerSyncTable[0].hikaState = flags
    else
        gPlayerSyncTable[0].hikaState = 0
    end
end

---Resets all sync table values to their defaults for a given player index
---@param localIndex integer
function reset_sync_table(localIndex)
    apply_player_hika_flags()

    gPlayerSyncTable[localIndex].heldObjSyncId = nil
    gPlayerSyncTable[localIndex].heldPlayerGlobalId = nil
    gPlayerSyncTable[localIndex].heldWiggles = 0

    gPlayerSyncTable[localIndex].eatenObjSyncId = nil
    gPlayerSyncTable[localIndex].eatenPlayerGlobalId = nil
    gPlayerSyncTable[localIndex].eatenWiggles = 0

    gPlayerSyncTable[localIndex].airJumpCount = 0
    gPlayerSyncTable[localIndex].bellyBounces = 0
    gPlayerSyncTable[localIndex].isBounceable = false

    gPlayerSyncTable[localIndex].holderGlobalId = nil
    gPlayerSyncTable[localIndex].eaterGlobalId = nil

    cur_obj_become_tangible()
    cur_obj_enable_rendering()
end
