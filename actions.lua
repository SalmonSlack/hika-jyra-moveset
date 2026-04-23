-- Create unique IDs for our custom actions
ACT_BELLY_TRAMPOLINE = allocate_mario_action(ACT_GROUP_STATIONARY | ACT_FLAG_STATIONARY)
ACT_BELLY_FLOP = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ATTACKING)
ACT_ROLL = allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING | ACT_FLAG_ATTACKING)
ACT_AIR_ROLL = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ATTACKING |
ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_BELLY_THRUST = allocate_mario_action(ACT_GROUP_STATIONARY | ACT_FLAG_STATIONARY | ACT_FLAG_ATTACKING)
ACT_BELLY_LONG_JUMP = allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING | ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ATTACKING) -- Might not need the attacking flag?
ACT_AIR_JUMP = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR)
ACT_GRAB = allocate_mario_action(ACT_FLAG_ATTACKING)
ACT_EATING = allocate_mario_action(ACT_GROUP_STATIONARY | ACT_FLAG_STATIONARY)
ACT_EATEN = allocate_mario_action(ACT_GROUP_AUTOMATIC | ACT_FLAG_INTANGIBLE)
ACT_HELD = allocate_mario_action(ACT_GROUP_AUTOMATIC | ACT_FLAG_INTANGIBLE)

---Belly Trampoline immobilizes the player and allows others to bounce off of their belly
---@param m MarioState
---@return integer | nil
local function belly_trampoline_loop(m)
    if m.playerIndex ~= 0 then return end

    -- Hika rolls onto his back
    if m.actionState == 0 then
        if m.actionTimer == 15 then -- Placeholder number representing how long the animation takes to play
            m.actionState = 1
            m.actionTimer = 0
        end

    -- Hika is on his back and can be bounced on by other players
    elseif m.actionState == 1 then
        -- If the player presses the A button, B button, or moves the control stick, they will start to get up
         if m.input & INPUT_NONZERO_ANALOG ~= 0 or m.input & INPUT_A_PRESSED ~= 0 or m.input & INPUT_B_PRESSED ~= 0 then
            m.actionState = 3
            m.actionTimer = 0
        end

    -- Hika has a player bounce on him, leaving him momentarily unable to get up until the bounce animation finishes
    elseif m.actionState == 2 then
        if m.actionTimer >= 15 then -- Placeholder number representing how long the bounce animation takes to play
            m.actionState = 1
            m.actionTimer = 0
        end

    -- Hika gets up from his laying position and returns to idle
    elseif m.actionState == 3 then
        if m.actionTimer >= 15 then -- Placeholder actionTimer representing how long the get up animation takes
            return set_mario_action(m, ACT_IDLE, 0)
        end
    end

    m.actionTimer = m.actionTimer + 1
end

---Belly Flop replaces the dive action and allows players to belly bounce on contact with the ground
---@param m MarioState
---@return integer | nil
local function belly_flop_loop(m)
    if m.playerIndex ~= 0 then return end

    -- Cap out forward velocity after first bounce
    if gPlayerSyncTable[0].bellyBounces > 0 then
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
            gPlayerSyncTable[0].bellyBounces = gPlayerSyncTable[0].bellyBounces + 1
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

        if m.actionTimer >= 7 then
            if m.controller.buttonDown & A_BUTTON ~= 0 then
                set_mario_animation(m, CHAR_ANIM_DIVE)
                m.vel.y = 60.0
                m.actionState = 2
                m.actionTimer = 0
                m.faceAngle.y = m.intendedYaw
                return
            else
                if m.forwardVel <= 0.0 then
                    set_mario_animation(m, CHAR_ANIM_STOP_CROUCHING)
                    m.actionState = 3
                    m.actionTimer = 0
                    return
                end
            end
        end

    -- Rising state, player can let go of A at any point to stop the momentum, similar to a standard jump
    elseif m.actionState == 2 then
        update_air_with_turn(m)
        local step = perform_air_step(m, 0)
        -- Return to falling state when the player's momentum stalls out
        if step == AIR_STEP_LANDED or m.vel.y < 0 then
            m.actionState = 0
            m.actionTimer = 0
            return
        end

    -- Getting up from the flop
    elseif m.actionState == 3 then
        if m.actionTimer >= 10 then
            return set_mario_action(m, ACT_IDLE, 0)
        end
    end

    m.actionTimer = m.actionTimer + 1
end

---Handles the gravity for the belly flop action
---@param m MarioState
local function belly_flop_gravity(m)
    if m.playerIndex ~= 0 then return end

    if m.actionState == 2 and m.controller.buttonDown & A_BUTTON ~= 0 then
        m.vel.y = math.max(m.vel.y - 2 * HIKA_GRAVITY_MULT, HIKA_TERMINAL_VELOCITY)
    else
        m.vel.y = math.max(m.vel.y - 4.0 * HIKA_GRAVITY_MULT, HIKA_TERMINAL_VELOCITY)
    end
end

---Handles the rolling state, allowing the player to roll around like a ball. Credits to wibblus and their Bowser Moveset for the bulk of the logic in this function
---@param m MarioState
---@return integer | nil
local function roll_loop(m)
    if m.playerIndex ~= 0 then return end

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
    if m.playerIndex ~= 0 then return end

    if m.actionState == 1 and m.vel.y > 0.0 and m.controller.buttonDown & A_BUTTON ~= 0 then
        m.vel.y = math.max(m.vel.y - 2.0 * HIKA_GRAVITY_MULT, HIKA_TERMINAL_VELOCITY)
    else
        m.vel.y = math.max(m.vel.y - 4.0 * HIKA_GRAVITY_MULT, HIKA_TERMINAL_VELOCITY)
    end
end

---Handles the logic that checks for an object to grab
---@param m MarioState
---@return integer | nil
local function grab_loop(m)
    if m.playerIndex ~= 0 then return end

    perform_ground_step(m)

    if m.actionTimer == 0 then
        set_mario_animation(m, CHAR_ANIM_FIRST_PUNCH)
    end

    -- Get the closest object that can be grabbed
    local obj = get_first_overlapping_object(m, GRABBABLE_OBJECTS)

    -- If we detect a grabbable object, we're going to delete it and replace it with a 'grabbed' copy of itself
    if obj ~= nil then
        log_to_console("Grabbed Object: " .. tostring(get_id_from_behavior(obj.behavior)))
        local modelId = obj_get_model_id_extended(obj)
        log_to_console("Grabbed Object Model: " .. tostring(modelId))
        local heldObj = spawn_sync_object(id_bhvHeldObj, modelId, m.pos.x, m.pos.y, m.pos.z, function(o)
            o.parentObj = obj

            o.header.gfx.scale.x = obj.header.gfx.scale.x
            o.header.gfx.scale.y = obj.header.gfx.scale.y
            o.header.gfx.scale.z = obj.header.gfx.scale.z

            o.header.gfx.prevScale.x = obj.header.gfx.prevScale.x
            o.header.gfx.prevScale.y = obj.header.gfx.prevScale.y
            o.header.gfx.prevScale.z = obj.header.gfx.prevScale.z
            o.oHeldState = HELD_HELD
            o.heldByPlayerIndex = network_global_index_from_local(0)
        end)
        gPlayerSyncTable[0].heldObjSyncId = heldObj.oSyncID
        obj_mark_for_deletion(obj)
    end

    -- If animation ends without making contact with any objects, return to idle state
    if m.actionTimer > 10 then
         return set_mario_action(m, ACT_IDLE, 0)
    end

    m.actionTimer = m.actionTimer + 1
end

---Belly Thrust is a stationary attack that sends players and enemies flying on contact
---@param m MarioState
local function belly_thrust_loop(m)
    if m.playerIndex ~= 0 then return end
end

---Belly Long Jump acts like a long jump but making contact with players will send them flying
---@param m MarioState
local function belly_long_jump_loop(m)
    if m.playerIndex ~= 0 then return end
end

---
---@param m MarioState
---@return integer | nil
local function air_jump_loop(m)
    if m.playerIndex ~= 0 then return end

    m.forwardVel = math.min(m.forwardVel, HIKA_BELLY_FLOP_FORWARD_VEL)

    update_air_with_turn(m)
    perform_air_step(m, 0)

    if m.actionTimer == 0 then
        set_mario_animation(m, CHAR_ANIM_CROUCHING)
        play_hika_air_jump_sound(m)
        m.vel.y = HIKA_AIR_JUMP_VEL
        m.faceAngle.y = m.intendedYaw
        gPlayerSyncTable[0].airJumpCount = gPlayerSyncTable[0].airJumpCount + 1
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

local function air_jump_gravity(m)
    if m.playerIndex ~= 0 then return end

    if m.controller.buttonDown & A_BUTTON ~= 0 then
        m.vel.y = math.max(m.vel.y - 2 * HIKA_GRAVITY_MULT, HIKA_TERMINAL_VELOCITY)
    else
        m.vel.y = math.max(m.vel.y - 4.0 * HIKA_GRAVITY_MULT, HIKA_TERMINAL_VELOCITY)
    end
end

---Eating is the state where the player puts another player or object into their mouth
---@param m MarioState
local function eating_loop(m)
    if m.playerIndex ~= 0 then return end
end

---Eaten is the state where a player has been put into a Hikaseru player's mouth, limiting available actions
---@param m MarioState
local function act_eaten_loop(m)
    if m.playerIndex ~= 0 then return end
end

---Held is the state where a player is being held in a Hikaseru player's hands like a box or other holdable object
---@param m MarioState
local function act_held_loop(m)
    if m.playerIndex ~= 0 then return end
end

hook_mario_action(ACT_BELLY_TRAMPOLINE, belly_trampoline_loop)
hook_mario_action(ACT_BELLY_FLOP, { every_frame = belly_flop_loop, gravity = belly_flop_gravity }, INT_GROUND_POUND)
hook_mario_action(ACT_ROLL, { every_frame = roll_loop, gravity = roll_gravity }, INT_GROUND_POUND)
hook_mario_action(ACT_BELLY_THRUST, belly_thrust_loop, INT_KICK)
hook_mario_action(ACT_BELLY_LONG_JUMP, belly_long_jump_loop, INT_KICK)
hook_mario_action(ACT_AIR_JUMP, { every_frame = air_jump_loop, gravity = air_jump_gravity })
hook_mario_action(ACT_GRAB, grab_loop, INT_PUNCH)
hook_mario_action(ACT_EATING, eating_loop)
hook_mario_action(ACT_EATEN, act_eaten_loop)
hook_mario_action(ACT_HELD, act_held_loop)
