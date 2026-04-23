-- name: [CS] Hikaseru
-- description: Hikaseru v0.1 \nTraverse the Super Mario 64 universe with Hikaseru!\n\nCredits\n\nHikaseru Belongs to \\#4287f5\\MidnightLab\n\\#dcdcdc\\Mod Developed by \\#cf9e3c\\Slack

---@diagnostic disable: undefined-field
if not _G.charSelectExists then return end
_G.charSelect = _G.charSelect -- Redefining charSelect to avoid undefined-field errors in this file
---@diagnostic enable: undefined-field

E_MODEL_HIKASERU = smlua_model_util_get_id('hikaseru_geo')
local NAME = "Hikaseru"
local DESC = { "Desc1", "Desc2" }
local CREDITS = "Credits"
local COLOR = { r = 93, g = 178, b = 183 }
local TEXTURE = get_texture_info("toonTurtleLife")

HIKA_AIR_JUMP_1 = audio_sample_load('hika_air_jump_1.ogg')
HIKA_AIR_JUMP_2 = audio_sample_load('hika_air_jump_2.ogg')

BASE_TERMINAL_VELOCITY = -75.0
HIKA_TERMINAL_VELOCITY = -150.0
HIKA_GRAVITY_MULT = 1.25
HIKA_BELLY_FLOP_FORWARD_VEL = 20.0
HIKA_AIR_JUMP_VEL = 40.0
HIKA_AIR_JUMP_COUNT = 5
HIKA_DIVE_JUMP_VEL = 50.0
HIKA_ROLL_JUMP_VEL = 40.0
HIKA_OBJ_THROW_STRENGTH = 60.0

local IGNORE_GRAVITY_ACTIONS = {
    ACT_BUBBLED,
    ACT_FALL_AFTER_STAR_GRAB,
    ACT_FLYING,
    ACT_GETTING_BLOWN,
    ACT_SHOT_FROM_CANNON,
    ACT_TORNADO_TWIRLING,
    ACT_TWIRLING,
}

local VALID_AIR_JUMP_ACTIONS = {
    ACT_FREEFALL,
    ACT_JUMP,
    ACT_DOUBLE_JUMP,
    ACT_TRIPLE_JUMP,
    ACT_SIDE_FLIP,
    ACT_BELLY_FLOP,
}

-- Enemies Hika will pick up instead of punching
-- Stretch goal is to give each "held enemy" we generate different properties when being held such as gravity, style of impact when it hits someone, etc.
local GRABBABLE_OBJECTS = {
    id_bhvBoo,
    id_bhvBooInCastle,
    id_bhvCourtyardBooTriplet,
    id_bhvFlyGuy,
    id_bhvGhostHuntBoo,
    id_bhvGoomba,
    id_bhvKoopa,
    id_bhvMerryGoRoundBoo,
    id_bhvMontyMole,
    id_bhvPiranhaPlant,
    id_bhvScuttlebug,
    id_bhvSkeeter,
    id_bhvSmallBully,
    id_bhvSmallChillBully,
    id_bhvSnufit,
    id_bhvSpindrift,
    id_bhvSwoop,
}

-- Adding Hikaseru to Character Select
CT_HIKASERU = _G.charSelect.character_add(NAME, DESC, CREDITS, COLOR, E_MODEL_HIKASERU, CT_WARIO, TEXTURE)

---Handles checks that need to occur on every frame
---@param m MarioState
local function mario_update(m)
    if m.playerIndex ~= 0 then return end

    -- When the player is grounded, reset their air jumps to zero
    if m.action & ACT_FLAG_AIR == 0 then
        gPlayerSyncTable[0].airJumpCount = 0
        gPlayerSyncTable[0].bellyBounces = 0
    end

    -- Handles the air jump action
    if m.action & ACT_FLAG_AIR and m.vel.y <= 0 and gPlayerSyncTable[0].airJumpCount < HIKA_AIR_JUMP_COUNT and is_value_in_list(m.action, VALID_AIR_JUMP_ACTIONS) then
        -- If the player has already started air jumping, the player can simply hold the A button to continue air jumping
        if m.prevAction == ACT_AIR_JUMP and m.action ~= ACT_BELLY_FLOP then
            -- Letting the player fall a bit more before they can jump again to give a similar air jump effect to Kirby Air Ride
            if m.vel.y <= (-4 * HIKA_GRAVITY_MULT * 2) and m.controller.buttonDown & A_BUTTON ~= 0 then
                set_mario_action(m, ACT_AIR_JUMP, 0)
            end
        elseif m.controller.buttonPressed & A_BUTTON ~= 0 then
            -- If the player is belly flopping, only allow a jump out of the belly flop if they aren't falling too fast
            if m.action ~= ACT_BELLY_FLOP or (m.action == ACT_BELLY_FLOP and m.vel.y > -HIKA_AIR_JUMP_VEL and gPlayerSyncTable[0].bellyBounces > 0) then
                set_mario_action(m, ACT_AIR_JUMP, 0)
            end
        end
    end

    -- Allows the player to ground pound out of a belly flop
    if m.action == ACT_BELLY_FLOP and m.controller.buttonDown & Z_TRIG ~= 0 and m.vel.y > -HIKA_AIR_JUMP_VEL and gPlayerSyncTable[0].bellyBounces > 0 then
        set_mario_action(m, ACT_GROUND_POUND, 0)
    end

    -- Allows the player to roll out of a ground pound
    if m.action == ACT_GROUND_POUND_LAND and m.controller.buttonDown & Z_TRIG ~= 0 and m.controller.buttonPressed & B_BUTTON ~= 0 then
        set_mario_action(m, ACT_ROLL, 0)
    end

    -- Begins the eating action
    if m.heldObj ~= nil and m.controller.buttonDown & Z_TRIG ~= 0 then
        set_mario_action(m, ACT_EATING, 0)
    end
end

---Handles overriding existing actions with our custom ones
---@param m MarioState
---@param incomingAction integer
local function before_set_mario_action(m, incomingAction)
    if m.playerIndex ~= 0 then return end

    if incomingAction == ACT_BACKFLIP then
        return ACT_BELLY_TRAMPOLINE
    end

    if incomingAction == ACT_DIVE then
        -- If the player is on the ground, perform a small jump leading into the belly flop
        if m.action & ACT_FLAG_AIR == 0 then
            m.vel.y = HIKA_DIVE_JUMP_VEL
        end
        return ACT_BELLY_FLOP
    end

    if incomingAction == ACT_SLIDE_KICK then
        return ACT_ROLL
    end

    if (incomingAction == ACT_PUNCHING or incomingAction == ACT_MOVE_PUNCHING) and m.controller.buttonDown & Z_TRIG ~= 0 then
        return ACT_BELLY_THRUST
    end

    if incomingAction == ACT_LONG_JUMP then
        return ACT_BELLY_LONG_JUMP
    end

    if incomingAction == ACT_GROUND_POUND_LAND then
        create_impact_effects(m)
        return
    end
end

---Handles Hikaseru's gravity multiplier and glide behavior
---@param m MarioState
---@param stepType integer
local function before_phys_step(m, stepType)
    if m.playerIndex ~= 0 or stepType ~= STEP_TYPE_AIR or is_value_in_list(m.action, IGNORE_GRAVITY_ACTIONS) then return end

    -- Apply gravity multiplier only if we're falling
    if m.vel.y < 0 then
        -- Allow the player to slow their fall by holding the A button as long as they're not performing a pounding action or an air jump
        if m.action ~= ACT_BELLY_FLOP and m.action ~= ACT_GROUND_POUND and m.action ~= ACT_AIR_JUMP and m.controller.buttonDown & A_BUTTON ~= 0 then
            m.vel.y = math.max(m.vel.y - 2, BASE_TERMINAL_VELOCITY // 2)
        else
            m.vel.y = math.max(m.vel.y - (4 * HIKA_GRAVITY_MULT) + 4, HIKA_TERMINAL_VELOCITY)
        end
    end
end

---Handles the grab action on enemies
---@param m MarioState
---@param victim Object
local function on_attack_object(m, victim)
    if m.playerIndex ~= 0 or not is_value_in_list(get_id_from_behavior(victim.behavior), GRABBABLE_OBJECTS) then return end

    -- If the attack isn't a punch, we don't need to do any special actions
    if m.action ~= ACT_PUNCHING and m.action ~= ACT_MOVE_PUNCHING then
        return
    end

    -- Zero out velocity to keep the player from sliding
    m.slideVelX = 0
    m.slideVelZ = 0
    m.forwardVel = 0

    local modelId = obj_get_model_id_extended(victim)
    local heldObj = spawn_sync_object(id_bhvHeldObj, modelId, m.pos.x, m.pos.y, m.pos.z, function(o)
        o.header.gfx.scale.x = victim.header.gfx.scale.x
        o.header.gfx.scale.y = victim.header.gfx.scale.y
        o.header.gfx.scale.z = victim.header.gfx.scale.z
    end)

    m.heldObj = heldObj
    obj_mark_for_deletion(victim)
    set_mario_action(m, ACT_HOLD_IDLE, 0)
end

-- Event Hooks
_G.charSelect.character_hook_moveset(CT_HIKASERU, HOOK_MARIO_UPDATE, mario_update)
_G.charSelect.character_hook_moveset(CT_HIKASERU, HOOK_BEFORE_SET_MARIO_ACTION, before_set_mario_action)
_G.charSelect.character_hook_moveset(CT_HIKASERU, HOOK_BEFORE_PHYS_STEP, before_phys_step)

hook_event(HOOK_ON_ATTACK_OBJECT, on_attack_object)
