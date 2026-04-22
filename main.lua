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
local TEXTURE = get_texture_info("hikaseru_icon")

BASE_TERMINAL_VELOCITY = -75.0
HIKA_TERMINAL_VELOCITY = -150.0
HIKA_GRAVITY_MULT = 1.25

local IGNORE_GRAVITY_ACTIONS = {
    ACT_BUBBLED,
    ACT_FALL_AFTER_STAR_GRAB,
    ACT_FLYING,
    ACT_GETTING_BLOWN,
    ACT_SHOT_FROM_CANNON,
    ACT_TORNADO_TWIRLING,
    ACT_TWIRLING,
}

-- Adding Hikaseru to Character Select
CT_HIKASERU = _G.charSelect.character_add(NAME, DESC, CREDITS, COLOR, E_MODEL_HIKASERU, CT_WARIO, TEXTURE)

---Handles the inputs and actions we need to be updating every frame
---@param m MarioState
local function mario_update(m)
    if m.playerIndex ~= 0 then return end

    if m.heldObj ~= nil and m.controller.buttonDown & Z_TRIG ~= 0 then
        return ACT_EATING
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
        -- Allow the player to slow their fall by holding the A button as long as they're not performing a pounding action
        if m.action ~= ACT_BELLY_FLOP and m.action ~= ACT_GROUND_POUND and m.controller.buttonDown & A_BUTTON ~= 0 then
            m.vel.y = math.max(m.vel.y - 2, BASE_TERMINAL_VELOCITY // 2)
        else
            m.vel.y = math.max(m.vel.y - (4 * HIKA_GRAVITY_MULT) + 4, HIKA_TERMINAL_VELOCITY)
        end
    end
end

-- Event Hooks
_G.charSelect.character_hook_moveset(CT_HIKASERU, HOOK_MARIO_UPDATE, mario_update)
_G.charSelect.character_hook_moveset(CT_HIKASERU, HOOK_BEFORE_SET_MARIO_ACTION, before_set_mario_action)
_G.charSelect.character_hook_moveset(CT_HIKASERU, HOOK_BEFORE_PHYS_STEP, before_phys_step)

