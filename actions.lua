-- Create unique IDs for our custom actions
ACT_BELLY_TRAMPOLINE = allocate_mario_action(ACT_GROUP_STATIONARY | ACT_FLAG_STATIONARY)
ACT_BELLY_FLOP = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ATTACKING)
ACT_ROLL = allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING | ACT_FLAG_ATTACKING)
ACT_BELLY_THRUST = allocate_mario_action(ACT_GROUP_STATIONARY | ACT_FLAG_STATIONARY | ACT_FLAG_ATTACKING)
ACT_BELLY_LONG_JUMP = allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING | ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ATTACKING) -- Might not need the attacking flag?
ACT_EATING = allocate_mario_action(ACT_GROUP_STATIONARY | ACT_FLAG_STATIONARY)
ACT_EATEN = allocate_mario_action(ACT_GROUP_AUTOMATIC | ACT_FLAG_INTANGIBLE)
ACT_HELD = allocate_mario_action(ACT_GROUP_AUTOMATIC | ACT_FLAG_INTANGIBLE)

---Belly Trampoline immobilizes the player and allows others to bounce off of their belly
---@param m MarioState
local function belly_trampoline_loop(m)
    if m.playerIndex ~= 0 then return end

    -- Mario rolls onto his back
    if m.actionState == 0 then
        if m.actionTimer == 15 then -- Placeholder number representing how long the animation takes to play
            m.actionState = 1
            m.actionTimer = 0
        end

    -- Mario is on his back and can be bounced on by other players
    elseif m.actionState == 1 then
        -- If the player presses the A button, B button, or moves the control stick, they will start to get up
         if m.input & INPUT_NONZERO_ANALOG ~= 0 or m.input & INPUT_A_PRESSED ~= 0 or m.input & INPUT_B_PRESSED ~= 0 then
            m.actionState = 3
            m.actionTimer = 0
        end

    -- Mario has a player bounce on him, leaving him momentarily unable to get up until the bounce animation finishes
    elseif m.actionState == 2 then
        if m.actionTimer >= 15 then -- Placeholder number representing how long the bounce animation takes to play
            m.actionState = 1
            m.actionTimer = 0
        end

    -- Mario gets up from his laying position and returns to idle
    elseif m.actionState == 3 then
        if m.actionTimer >= 15 then -- Placeholder actionTimer representing how long the get up animation takes
            return set_mario_action(m, ACT_IDLE, 0)
        end
    end

    m.actionTimer = m.actionTimer + 1
end

---Belly Flop replaces the dive action and allows players to belly bounce on contact with the ground
---@param m MarioState
local function belly_flop_loop(m)
    if m.playerIndex ~= 0 then return end

    -- Cap out forward velocity
    m.forwardVel = math.min(m.forwardVel, 20.0)

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
        m.forwardVel = approach_f32(m.forwardVel, 0.0, 0.0, 1.5)

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
        if m.actionTimer >= 15 then
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

---Roll puts the player into a state where they can roll around the map and bounce off walls like a ball
---@param m MarioState
local function ground_roll_loop(m)
    if m.playerIndex ~= 0 then return end
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
hook_mario_action(ACT_ROLL, ground_roll_loop, INT_GROUND_POUND)
hook_mario_action(ACT_BELLY_THRUST, belly_thrust_loop, INT_KICK)
hook_mario_action(ACT_BELLY_LONG_JUMP, belly_long_jump_loop, INT_KICK)
hook_mario_action(ACT_EATING, eating_loop)
hook_mario_action(ACT_EATEN, act_eaten_loop)
hook_mario_action(ACT_HELD, act_held_loop)
