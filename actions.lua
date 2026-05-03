-- Create unique IDs for our custom actions
ACT_BELLY_TRAMPOLINE = allocate_mario_action(ACT_GROUP_STATIONARY | ACT_FLAG_STATIONARY)
ACT_BELLY_FLOP = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ATTACKING)
ACT_ROLL = allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING | ACT_FLAG_ATTACKING)
ACT_AIR_ROLL = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ATTACKING |
ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_BELLY_THRUST = allocate_mario_action(ACT_GROUP_STATIONARY | ACT_FLAG_STATIONARY | ACT_FLAG_ATTACKING)
ACT_BELLY_LONG_JUMP = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ATTACKING)
ACT_AIR_JUMP = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR)
ACT_EATING = allocate_mario_action(ACT_GROUP_STATIONARY | ACT_FLAG_STATIONARY)
ACT_SPIT = allocate_mario_action(ACT_GROUP_STATIONARY | ACT_FLAG_STATIONARY)
ACT_AIR_SPIT = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR)
ACT_EATEN = allocate_mario_action(ACT_GROUP_AUTOMATIC | ACT_FLAG_INTANGIBLE | ACT_FLAG_INVULNERABLE | ACT_FLAG_PAUSE_EXIT)
ACT_HELD = allocate_mario_action(ACT_GROUP_AUTOMATIC | ACT_FLAG_STATIONARY | ACT_FLAG_INTANGIBLE | ACT_FLAG_INVULNERABLE | ACT_FLAG_PAUSE_EXIT)
ACT_SPAT_OUT = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_MOVING | ACT_FLAG_ATTACKING)

---Belly Trampoline immobilizes the player and allows others to bounce off of their belly
---@param m MarioState
---@return integer | nil
local function belly_trampoline_loop(m)
    -- Hika rolls onto his back
    if m.actionState == 0 then
        if m.actionTimer == 0 then
            set_mario_animation(m, CHAR_ANIM_FALL_OVER_BACKWARDS)
        end

        if m.actionTimer == 30 then
            m.actionState = 1
            m.actionTimer = 0
            return
        end

    -- Hika is on his back and can be bounced on by other players
    elseif m.actionState == 1 then
        set_anim_to_frame(m, math.min(m.marioObj.header.gfx.animInfo.animFrame, 42))

        -- If the player presses the A button, B button, or moves the control stick, they will start to get up
         if m.input & INPUT_NONZERO_ANALOG ~= 0 or m.input & INPUT_A_PRESSED ~= 0 or m.input & INPUT_B_PRESSED ~= 0 then
            m.actionState = 2
            m.actionTimer = 0
        end

    -- Hika gets up from the ground
    elseif m.actionState == 2 then
        if m.actionTimer >= 38 then
            return set_mario_action(m, ACT_IDLE, 0)
        end
    end

    m.actionTimer = m.actionTimer + 1
end

---Belly Flop replaces the dive action and allows players to belly bounce on contact with the ground
---@param m MarioState
---@return integer | nil
local function belly_flop_loop(m)
    -- Cap out forward velocity after first bounce
    if gPlayerSyncTable[m.playerIndex].bellyBounces > 0 then
        m.forwardVel = math.min(m.forwardVel, HIKA_BELLY_FLOP_FORWARD_VEL)
    else
        m.forwardVel = approach_f32(m.forwardVel, HIKA_BELLY_FLOP_FORWARD_VEL, 0.0, 2.0)
    end

    -- Initial falling state
    if m.actionState == 0 then
        if m.actionTimer == 0 then
            set_mario_animation(m, CHAR_ANIM_DIVE)
        end
        update_air_with_turn(m)
        local step = perform_air_step(m, 0)


        if step == AIR_STEP_LANDED then
            set_mario_animation(m, CHAR_ANIM_START_CROUCHING)
            create_impact_effects(m)
            m.actionState = 1
            m.actionTimer = 0
            if m.playerIndex == 0 then
                gPlayerSyncTable[m.playerIndex].bellyBounces = gPlayerSyncTable[m.playerIndex].bellyBounces + 1
            end
            return
        end

        if m.controller.buttonPressed & Z_TRIG ~= 0 then
            return set_mario_action(m, ACT_GROUND_POUND, 0)
        end

    -- Contact with the ground, player can bounce here if they hold the A button
    elseif m.actionState == 1 then
        local step = perform_ground_step(m)

        if step == GROUND_STEP_LEFT_GROUND then
            m.actionState = 0
            m.actionTimer = 0
            return
        end

        -- Decelerate the player
        m.forwardVel = approach_f32(m.forwardVel, 0.0, 0.0, 1.0)

        if m.actionTimer >= 10 then
            if m.controller.buttonDown & A_BUTTON ~= 0 then
                set_mario_animation(m, CHAR_ANIM_DIVE)
                select_and_play_audio(m.pos, BOUNCE)
                m.vel.y = HIKA_BELLY_FLOP_BOUNCE_HEIGHT
                m.actionState = 2
                m.actionTimer = 0
                m.faceAngle.y = m.intendedYaw
                return
            else
                if m.forwardVel <= 0.0 then
                    return set_mario_action(m, ACT_CROUCHING, 0)
                end
            end
        end

    -- Rising state, Hikaseru can let go of A at any point to stop the momentum, similar to a standard jump
    elseif m.actionState == 2 then
        update_air_with_turn(m)
        local step = perform_air_step(m, 0)
        -- Return to falling state when the player's momentum stalls out
        if step == AIR_STEP_LANDED or m.vel.y < 0 then
            m.actionState = 0
            m.actionTimer = 0
            return
        end
    end

    m.actionTimer = m.actionTimer + 1
end

---Handles the gravity for the belly flop action
---@param m MarioState
local function belly_flop_gravity(m)
    if m.actionState == 2 and m.controller.buttonDown & A_BUTTON ~= 0 then
        m.vel.y = math.max(m.vel.y - 2 * HIKA_BELLY_FLOP_GRAVITY_MULT, HIKA_TERMINAL_VELOCITY)
    else
        m.vel.y = math.max(m.vel.y - 4.0 * HIKA_BELLY_FLOP_GRAVITY_MULT, HIKA_TERMINAL_VELOCITY)
    end
end

---Handles the rolling state, allowing the player to roll around like a ball. Credits to wibblus and her Bowser Moveset for the bulk of the logic in this function
---@param m MarioState
---@return integer | nil
local function roll_loop(m)
    if m.actionTimer == 0 then
        set_mario_animation(m, MARIO_ANIM_SLOW_LONGJUMP)
        m.actionState = 0
        mario_set_forward_vel(m, math.max(m.forwardVel, 50.0))
    elseif m.actionTimer > 2 then
        -- Keeps the player spinning based on their forward velocity
        local animSpeed = math.max(10.0, m.forwardVel) / 40.0 * 0x10000
        set_mario_anim_with_accel(m, CHAR_ANIM_FORWARD_SPINNING, animSpeed)
    end

    m.actionTimer = m.actionTimer + 1

    -- Grounded
    if m.actionState == 0 then
        local fwd = coss(m.intendedYaw - m.slideYaw)
        mario_set_forward_vel(m, math.max(math.min(m.forwardVel, 120.0), math.min(m.forwardVel + math.max(math.min(fwd + 1.0, 1.0), 0.1) * 4.0, 65.0)))

        m.intendedMag = 35.0
        update_sliding(m, 10.0)
        m.peakHeight = m.pos.y

        local step = perform_ground_step(m)

        play_sound(SOUND_MOVING_TERRAIN_SLIDE + m.terrainSoundAddend, m.marioObj.header.gfx.cameraToObject)
        adjust_sound_for_speed(m)
        set_mario_particle_flags(m, PARTICLE_DUST, 0)

        -- Allows the player to jump during the roll
        if m.controller.buttonPressed & A_BUTTON ~= 0 then
            -- Decreases forward velocity if attempting to jump up a slope
            if abs_angle_diff(m.floorAngle, m.faceAngle.y) > 0x4000 and (m.floor.normal.y < 0.9 or mario_floor_is_slippery(m) ~= 0) then
                mario_set_forward_vel(m, m.forwardVel * 0.75)
            end
            m.actionState = 1
            m.vel.y = HIKA_ROLL_JUMP_VEL

            play_sound(SOUND_ACTION_BONK, m.marioObj.header.gfx.cameraToObject)
            return
        end

        -- Allows the player to cancel the roll into a belly flop
        if m.controller.buttonPressed & B_BUTTON ~= 0 and m.actionTimer > 1 then
            m.vel.y = HIKA_DIVE_JUMP_VEL
            return set_mario_action(m, ACT_BELLY_FLOP, 0)
        end

        -- Allows the player to cancel the roll into a crouch slide
        if m.controller.buttonPressed & Z_TRIG ~= 0 then
            return set_mario_action(m, ACT_CROUCH_SLIDE, 0)
        end

        if m.forwardVel < 10.0 then
            return set_mario_action(m, ACT_STOP_CROUCHING, 0)
        end

        if step == GROUND_STEP_LEFT_GROUND then
            m.actionState = 1
            m.vel.y = 0
            return
        end

        if (step == GROUND_STEP_HIT_WALL and (m.wall ~= nil or gServerSettings.bouncyLevelBounds ~= 1))
        or (m.ceil ~= nil and m.ceilHeight < m.pos.y + 50) then
            create_wall_impact_effects(m)
            mario_bonk_reflection(m, 0)
        end

        align_with_floor(m)
        return
    end

    -- Airborne
    if m.actionState == 1 then
        update_air_without_turn(m)

        local step = perform_air_step(m, 0)

        -- Allow the player to cancel the roll into other actions
        if m.controller.buttonPressed & Z_TRIG ~= 0 then
            return set_mario_action(m, ACT_GROUND_POUND, 0)
        end

        if m.controller.buttonPressed & B_BUTTON ~= 0 then
            return set_mario_action(m, ACT_BELLY_FLOP, 0)
        end

        if step == AIR_STEP_LANDED then
            if check_fall_damage_or_get_stuck(m, ACT_HARD_FORWARD_GROUND_KB) == 0 then
                create_impact_effects(m)
                m.actionState = 0
            end
            return
        end

        if step == AIR_STEP_HIT_WALL and (m.wall ~= nil or gServerSettings.bouncyLevelBounds ~= 1) then
            create_wall_impact_effects(m)
            mario_bonk_reflection(m, 0)
        end
    end
end

---Handles the gravity for the roll action
---@param m MarioState
local function roll_gravity(m)
    if m.actionState == 1 and m.vel.y > 0.0 and m.controller.buttonDown & A_BUTTON ~= 0 then
        m.vel.y = math.max(m.vel.y - 2.0 * HIKA_GRAVITY_MULT, HIKA_TERMINAL_VELOCITY)
    else
        m.vel.y = math.max(m.vel.y - 4.0 * HIKA_GRAVITY_MULT, HIKA_TERMINAL_VELOCITY)
    end
end

---Belly Thrust is a stationary attack that sends players and enemies flying on contact
---@param m MarioState
local function belly_thrust_loop(m)
end

---Belly Long Jump acts like a long jump but making contact with players will send them flying
---@param m MarioState
local function belly_long_jump_loop(m)
    -- Airborne
    if m.actionState == 0 then
        update_air_without_turn(m)
        local step = perform_air_step(m, 0)

        if m.actionTimer == 0 then
            set_mario_animation(m, CHAR_ANIM_TRIPLE_JUMP_LAND)
            m.forwardVel = math.min(m.forwardVel * 1.3, HIKA_BELLY_LONG_JUMP_PEAK_VEL)
            set_mario_y_vel_based_on_fspeed(m, 30.0, 0.0)
        end

        set_anim_to_frame(m, 18)

        if step == AIR_STEP_HIT_WALL and has_hika_flags(m, _G.hikaMoveset.FLAG_CAN_BELLY_WALL_JUMP) and m.controller.buttonDown & A_BUTTON ~= 0 and (m.wall ~= nil or gServerSettings.bouncyLevelBounds ~= 1) then
            set_mario_animation(m, CHAR_ANIM_PUSHING)
            select_and_play_audio(m.pos, STRAIN)
            m.actionState = 1
            m.actionTimer = 0
        elseif step == AIR_STEP_LANDED then
            return set_mario_action(m, ACT_LONG_JUMP_LAND, 0)
        end
    end

    -- Clinging to Wall
    if m.actionState == 1 then
        set_anim_to_frame(m, 0)

        -- If the bounce is fully charged or the player lets go of the A button, bounce off the wall with the current bounce strength
        if m.actionTimer >= HIKA_BELLY_WALL_JUMP_MAX_CLING_TIME or m.controller.buttonDown & A_BUTTON == 0 then
            stop_audio_samples(SOUNDS_TABLE[STRAIN])
            -- If the player isn't holding in any direction, or they aren't holding away from the wall, cancel the bounce
            if m.input & INPUT_NONZERO_ANALOG == 0 or abs_angle_diff(m.intendedYaw, m.faceAngle.y) < 0x5500 then
                m.forwardVel = 0
                return set_mario_action(m, ACT_FREEFALL, 0)
            end

            m.faceAngle.y = m.intendedYaw
            m.forwardVel = math.min((m.actionTimer / HIKA_BELLY_WALL_JUMP_TIME_TO_MAX) * HIKA_BELLY_WALL_JUMP_PEAK_VEL, HIKA_BELLY_WALL_JUMP_PEAK_VEL)
            m.actionState = 0
            m.actionTimer = 1
            set_mario_particle_flags(m, PARTICLE_DUST, 0)
            select_and_play_audio(m.pos, BOUNCE)
            set_mario_animation(m, CHAR_ANIM_TRIPLE_JUMP_LAND)
            set_mario_y_vel_based_on_fspeed(m, HIKA_BELLY_WALL_JUMP_HEIGHT, 0.0)
        end
    end

    m.actionTimer = m.actionTimer + 1
end

---Handles the gravity for the belly long jump action
---@param m MarioState
local function belly_long_jump_gravity(m)
    if m.actionState == 0 and m.vel.y > 0.0 and m.controller.buttonDown & A_BUTTON ~= 0 then
        m.vel.y = math.max(m.vel.y - 2 * HIKA_GRAVITY_MULT, HIKA_TERMINAL_VELOCITY)
    else
        m.vel.y = math.max(m.vel.y - 4.0 * HIKA_GRAVITY_MULT, HIKA_TERMINAL_VELOCITY)
    end
end

---Handles the air jump action, allowing the player to perform multiple jumps in mid air
---@param m MarioState
---@return integer | nil
local function air_jump_loop(m)
    m.forwardVel = math.min(m.forwardVel, HIKA_AIR_JUMP_FORWARD_VEL)

    update_air_with_turn(m)
    perform_air_step(m, 0)

    if m.actionTimer == 0 then
        set_mario_animation(m, CHAR_ANIM_CROUCHING)
        select_and_play_audio(m.pos, AIR_JUMP)
        m.vel.y = HIKA_AIR_JUMP_VEL
        m.faceAngle.y = m.intendedYaw
        if m.playerIndex == 0 then
            gPlayerSyncTable[m.playerIndex].airJumpCount = gPlayerSyncTable[m.playerIndex].airJumpCount + 1
        end
    end

    -- Allows the player to belly flop or ground pound out of an air jump
    if m.controller.buttonPressed & B_BUTTON ~= 0 then
        return set_mario_action(m, ACT_BELLY_FLOP, 0)
    elseif m.controller.buttonPressed & Z_TRIG ~= 0 then
        return set_mario_action(m, ACT_GROUND_POUND, 0)
    end

    if m.vel.y <= 0 then
        return set_mario_action(m, ACT_FREEFALL, 0)
    end

    m.actionTimer = m.actionTimer + 1
end

---Handles the gravity for the air jump action
---@param m MarioState
local function air_jump_gravity(m)
    if m.controller.buttonDown & A_BUTTON ~= 0 then
        m.vel.y = math.max(m.vel.y - 2 * HIKA_GRAVITY_MULT, HIKA_TERMINAL_VELOCITY)
    else
        m.vel.y = math.max(m.vel.y - 4.0 * HIKA_GRAVITY_MULT, HIKA_TERMINAL_VELOCITY)
    end
end

---Eating is the state where the player puts another player or object into their mouth
---@param m MarioState
local function eating_loop(m)
    if m.actionTimer < 29 and (not gPlayerSyncTable[m.playerIndex].heldObjSyncId or gPlayerSyncTable[m.playerIndex].eatenPlayerGlobalId or gPlayerSyncTable[m.playerIndex].eatenObjSyncId) then
        log("eating_loop - eater is missing necessary syncTable values, exiting eating_loop")
        return set_mario_action(m, ACT_IDLE, 0)
    end

    if m.actionTimer == 0 then
        set_mario_animation(m, CHAR_ANIM_COUGHING)
    end

    -- The part of the animation where the player / object should shift from 'held' to 'eaten'
    if m.actionTimer == 29 then
        -- Players can have a held player / object and an eaten player / object at the same time
        if gPlayerSyncTable[m.playerIndex].heldPlayerGlobalId then
            local heldPlayerLocalIndex = network_local_index_from_global(gPlayerSyncTable[m.playerIndex].heldPlayerGlobalId)
            if heldPlayerLocalIndex then
                local heldPlayer = gMarioStates[heldPlayerLocalIndex]
                if heldPlayer then
                    if m.playerIndex == 0 then
                        gPlayerSyncTable[m.playerIndex].eatenPlayerGlobalId = gPlayerSyncTable[m.playerIndex].heldPlayerGlobalId
                        network_send_to(heldPlayerLocalIndex, true, { key = "actHikaEaten", hikaPlayerGlobalId = network_global_index_from_local(m.playerIndex) })
                    end
                end
            end
        elseif gPlayerSyncTable[m.playerIndex].heldObjSyncId then
            if m.playerIndex == 0 then
                gPlayerSyncTable[m.playerIndex].eatenObjSyncId = gPlayerSyncTable[m.playerIndex].heldObjSyncId
            end

            local heldObj = sync_object_get_object(gPlayerSyncTable[m.playerIndex].heldObjSyncId)
            if heldObj then
                heldObj.oBehParams = 1 -- Tells the object to act eaten
                network_send_object(heldObj, true)
            end
        end

        if m.playerIndex == 0 then
            gPlayerSyncTable[m.playerIndex].heldObjSyncId = nil
            gPlayerSyncTable[m.playerIndex].heldPlayerGlobalId = nil
        end

        if m.heldObj then m.heldObj = nil end
    end

    -- Simulate chewing. This won't need to exist when we move on from using placeholders
    if m.actionTimer == 38 then
        set_anim_to_frame(m, 29)
    elseif m.actionTimer == 47 then
        set_anim_to_frame(m, 29)
    end

    if m.actionTimer == 51 then
        return set_mario_action(m, ACT_IDLE, 0)
    end

    m.actionTimer = m.actionTimer + 1
end

---Handles the spitting out action which re-renders the eaten object or player and sends it flying forward
---@param m MarioState
local function spit_loop(m)
    -- Reset all held / eaten attributes and set the object / player into their spat out states
    if m.actionTimer == 0 then
        log("spit_loop - Spitting Out Object / Player")
        smlua_anim_util_set_animation(m.marioObj, CHAR_ANIM_HIKA_SPIT)
        set_anim_to_frame(m, 0)
        if m.action & ACT_FLAG_AIR == 0 then
            m.forwardVel = 0
            m.slideVelX = 0
            m.slideVelZ = 0
        end
    end

    if m.action & ACT_FLAG_AIR ~= 0 then
        if m.actionTimer <= 5 then
            update_air_with_turn(m)
        else
            update_air_without_turn(m)
        end
        local step = perform_air_step(m, 0)

        if step == AIR_STEP_LANDED then
            m.action = ACT_SPIT
        end
    end

    -- This is the part of the animation we want to re-render the object / player
    if m.actionTimer == 5 then
        if gPlayerSyncTable[m.playerIndex].eatenPlayerGlobalId then
            local eatenPlayerLocalIndex = network_local_index_from_global(gPlayerSyncTable[m.playerIndex].eatenPlayerGlobalId)
            if eatenPlayerLocalIndex then
                local eatenPlayer = gMarioStates[eatenPlayerLocalIndex]
                if eatenPlayer then
                    if m.playerIndex == 0 then
                        network_send_to(eatenPlayerLocalIndex, true, { key = "actHikaSpatOut", hikaPlayerGlobalId = network_global_index_from_local(m.playerIndex) })
                    end
                end
            end
        elseif gPlayerSyncTable[m.playerIndex].eatenObjSyncId then
             local eatenObj = sync_object_get_object(gPlayerSyncTable[m.playerIndex].eatenObjSyncId)
             if eatenObj then
                eatenObj.oHeldState = HELD_THROWN
                network_send_object(eatenObj, true)
             end
        end

        if m.playerIndex == 0 then
            gPlayerSyncTable[m.playerIndex].heldObjSyncId = nil
            gPlayerSyncTable[m.playerIndex].heldPlayerGlobalId = nil
            gPlayerSyncTable[m.playerIndex].eatenObjSyncId = nil
            gPlayerSyncTable[m.playerIndex].eatenPlayerGlobalId = nil
        end
    end

    -- At animation end, return back to idle
    if m.actionTimer == 25 then
        if m.action & ACT_FLAG_AIR ~= 0 then
            return set_mario_action(m, ACT_FREEFALL, 0)
        else
            return set_mario_action(m, ACT_IDLE, 0)
        end
    end

    m.actionTimer = m.actionTimer + 1
end

local function air_spit_gravity(m)
    m.vel.y = math.max(m.vel.y - 4.0, HIKA_TERMINAL_VELOCITY)
end

---Eaten is the state where a player has been put into a Hikaseru player's mouth, limiting available actions
---@param m MarioState
local function act_eaten_loop(m)
    if not gPlayerSyncTable[m.playerIndex].eaterGlobalId then
        log("act_eaten_loop - eaterGlobalId not found, exiting act_eaten_loop")
        return set_mario_action(m, ACT_BACKWARD_AIR_KB, 0)
    end

    if m.actionTimer == 0 then
        log("act_eaten_loop - Eaten Player Global Index: " .. tostring(network_global_index_from_local(m.playerIndex)))
        cur_obj_disable_rendering()
        cur_obj_become_intangible()
    end

    local eaterLocalIndex = network_local_index_from_global(gPlayerSyncTable[m.playerIndex].eaterGlobalId)
    local eater = gMarioStates[eaterLocalIndex]

    if not eater then
        return set_mario_action(m, ACT_IDLE, 0)
    end

    m.pos.x = eater.pos.x
    m.pos.y = eater.pos.y
    m.pos.z = eater.pos.z

    m.marioObj.header.gfx.pos.x = m.pos.x
    m.marioObj.header.gfx.pos.y = m.pos.y
    m.marioObj.header.gfx.pos.z = m.pos.z

    m.faceAngle.y = eater.faceAngle.y
    m.marioObj.header.gfx.angle.y = eater.faceAngle.y

    if m.controller.buttonPressed & A_BUTTON ~= 0 or m.controller.buttonPressed & B_BUTTON ~= 0 then
        gPlayerSyncTable[eater.playerIndex].eatenWiggles = gPlayerSyncTable[eater.playerIndex].eatenWiggles + 1
    end

    m.actionTimer = m.actionTimer + 1
end

---Spat out is the state where a player is sent flying through the air after Hikaseru spits them out
---@param m MarioState
local function act_spat_out_loop(m)
    if m.actionTimer == 0 then
        cur_obj_become_intangible()
        cur_obj_enable_rendering()
        set_mario_animation(m, CHAR_ANIM_BACKWARD_AIR_KB)
    elseif m.actionTimer == 5 then
        -- Short delay before becoming tangible to prevent hitting the spitting player
        cur_obj_become_tangible()
    elseif m.actionTimer >= 60 then
        -- Allows the player to cancel their flight through the air
        if m.controller.buttonPressed & A_BUTTON ~= 0 then
            return set_mario_action(m, ACT_JUMP, 0)
        elseif m.controller.buttonPressed & B_BUTTON ~= 0 then
            return set_mario_action(m, ACT_JUMP_KICK, 0)
        elseif m.controller.buttonPressed & Z_TRIG ~= 0 then
            return set_mario_action(m, ACT_GROUND_POUND, 0)
        end
    end

    m.forwardVel = approach_f32(m.forwardVel, 0.0, HIKA_PLAYER_SPIT_SPEED_DECAY, HIKA_PLAYER_SPIT_SPEED_DECAY)

    update_air_without_turn(m)
    local step = perform_air_step(m, 0)

    if step == AIR_STEP_LANDED then
        cur_obj_become_tangible()
        return set_mario_action(m, ACT_BACKWARD_GROUND_KB, 0)
    elseif step == AIR_STEP_HIT_WALL then
        cur_obj_become_tangible()
        return set_mario_action(m, ACT_BACKWARD_AIR_KB, 0)
    end

    m.actionTimer = m.actionTimer + 1
end

---Handles the gravity for the spat out state
---@param m MarioState
local function act_spat_out_gravity(m)
    if m.forwardVel <= -HIKA_PLAYER_SPIT_DROP_SPEED then
        m.vel.y = 0
    else
        m.vel.y = math.max(m.vel.y - 4.0, BASE_TERMINAL_VELOCITY)
    end
end

---Held is the state where a player is being held in a Hikaseru player's hands. Can exit this state by being thrown, eaten, or by mashing out of the hold
---@param m MarioState
local function act_held_loop(m)
    if not gPlayerSyncTable[m.playerIndex].holderGlobalId then
        log("act_held_loop - No holderGlobalId found, exiting act_held_loop")
        cur_obj_become_tangible()
        return set_mario_action(m, ACT_FREEFALL, 0)
    end

    if m.actionTimer == 0 then
        set_mario_animation(m, CHAR_ANIM_BEING_GRABBED)
        cur_obj_become_intangible()
    end

    local holderLocalIndex = network_local_index_from_global(gPlayerSyncTable[m.playerIndex].holderGlobalId)
    local holder = gMarioStates[holderLocalIndex]

    -- If we can't find the holder or the holder doesn't have a held object, cancel the act_held loop
    -- Not a huge fan of the conditionals here, but it's the cases needed to keep this from running when we don't want it to
    if not holder then
        log("act_held_loop - Holder not found, exiting act_held_loop")
        gPlayerSyncTable[m.playerIndex].holderGlobalId = nil
        cur_obj_become_tangible()
        return set_mario_action(m, ACT_FREEFALL, 0)
    end

    if not holder.heldObj and holder.action ~= ACT_EATING and gPlayerSyncTable[holderLocalIndex].heldObjSyncId then
        local heldObj = sync_object_get_object(gPlayerSyncTable[holderLocalIndex].heldObjSyncId)
        if heldObj then
            holder.heldObj = heldObj
        else
            log("act_held_loop - emergency fallback, exiting act_held_loop")
            gPlayerSyncTable[m.playerIndex].holderGlobalId = nil
            cur_obj_become_tangible()
            return set_mario_action(m, ACT_FREEFALL, 0)
        end
    end

    local heldObjPos = holder.marioBodyState.heldObjLastPosition
    m.pos.x = holder.pos.x
    m.pos.y = holder.pos.y
    m.pos.z = holder.pos.z

    -- Shift the held player's model to the held object to appears held
    if holder.action ~= ACT_EATING then
        m.marioObj.header.gfx.pos.x = heldObjPos.x - coss(holder.faceAngle.y) * 30.0
        m.marioObj.header.gfx.pos.y = heldObjPos.y + 20.0
        m.marioObj.header.gfx.pos.z = heldObjPos.z + sins(holder.faceAngle.y) * 30.0
        m.faceAngle.y = holder.faceAngle.y
        m.marioObj.header.gfx.angle.y = m.faceAngle.y
    else
        -- Shift the player's model towards the front of the holder instead to appear like they're being eaten
        m.marioObj.header.gfx.pos.x = holder.pos.x + sins(holder.faceAngle.y) * (m.marioObj.hitboxRadius * 2.0)
        m.marioObj.header.gfx.pos.y = holder.pos.y + (m.marioObj.hitboxHeight - 40.0)
        m.marioObj.header.gfx.pos.z = holder.pos.z + coss(holder.faceAngle.y) * (m.marioObj.hitboxRadius * 2.0)
        m.faceAngle.y = holder.faceAngle.y + 0x8000
        m.marioObj.header.gfx.angle.y = m.faceAngle.y
    end


    if m.playerIndex == 0 and (m.controller.buttonPressed & A_BUTTON ~= 0 or m.controller.buttonPressed & B_BUTTON ~= 0) then
        gPlayerSyncTable[holder.playerIndex].heldWiggles = gPlayerSyncTable[holder.playerIndex].heldWiggles + 1
    end

    m.actionTimer = m.actionTimer + 1
end

-- Actions exclusive to a Hikaseru player
hook_mario_action(ACT_BELLY_TRAMPOLINE, belly_trampoline_loop)
hook_mario_action(ACT_BELLY_FLOP, { every_frame = belly_flop_loop, gravity = belly_flop_gravity }, INT_GROUND_POUND)
hook_mario_action(ACT_ROLL, { every_frame = roll_loop, gravity = roll_gravity }, INT_GROUND_POUND)
hook_mario_action(ACT_BELLY_THRUST, belly_thrust_loop, INT_KICK)
hook_mario_action(ACT_BELLY_LONG_JUMP, { every_frame = belly_long_jump_loop, gravity = belly_long_jump_gravity }, INT_KICK)
hook_mario_action(ACT_AIR_JUMP, { every_frame = air_jump_loop, gravity = air_jump_gravity })
hook_mario_action(ACT_SPIT, spit_loop)
hook_mario_action(ACT_AIR_SPIT, { every_frame = spit_loop, gravity = air_spit_gravity })
hook_mario_action(ACT_EATING, eating_loop)

-- Action states other players can be put into by a Hikaseru player
hook_mario_action(ACT_EATEN, act_eaten_loop)
hook_mario_action(ACT_HELD, act_held_loop)
hook_mario_action(ACT_SPAT_OUT, { every_frame = act_spat_out_loop, gravity = act_spat_out_gravity }, INT_KICK)
