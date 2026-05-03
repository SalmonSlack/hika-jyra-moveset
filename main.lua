-- name: [CS] Hikaseru
-- description: Hikaseru v0.5 \nTraverse the Super Mario 64 universe with Hikaseru!\n\nCredits\n\nHikaseru Belongs to \\#4287f5\\MidnightLab\n\\#dcdcdc\\Moveset Developed by \\#cf9e3c\\Slack\n\\#dcdcdc\\

---@diagnostic disable: undefined-field
if not _G.charSelectExists then return end
_G.charSelect = _G.charSelect
---@diagnostic enable: undefined-field

-- Adding Hikaseru to Character Select
E_MODEL_HIKASERU = smlua_model_util_get_id('hikaseru_geo')
local NAME = "Hikaseru"
local DESC = { "Desc1", "Desc2" }
local CREDITS = "MidnightLab / Slack"
local COLOR = { r = 93, g = 178, b = 183 }
local TEXTURE = get_texture_info("hikaseru-icon")
CT_HIKASERU = _G.charSelect.character_add(NAME, DESC, CREDITS, COLOR, E_MODEL_HIKASERU, CT_WARIO, TEXTURE)

-- Audio
SOUND_AIR_JUMP_1 = audio_sample_load('hika_air_jump_1.ogg')
SOUND_AIR_JUMP_2 = audio_sample_load('hika_air_jump_2.ogg')
SOUND_BOUNCE_1 = audio_sample_load('hika_boing_1.ogg')
SOUND_BOUNCE_2 = audio_sample_load('hika_boing_2.ogg')
SOUND_BOUNCE_3 = audio_sample_load('hika_boing_3.ogg')
SOUND_STRAIN_1 = audio_sample_load('hika_strain_1.ogg')

-- Sounds will be picked at random from this list when played
AIR_JUMP = "AIR_JUMP"
BOUNCE = "BOUNCE"
STRAIN = "STRAIN"
SOUNDS_TABLE = {
    [AIR_JUMP] = { SOUND_AIR_JUMP_1, SOUND_AIR_JUMP_2 },
    [BOUNCE] = { SOUND_BOUNCE_1, SOUND_BOUNCE_2, SOUND_BOUNCE_3 },
    [STRAIN] = { SOUND_STRAIN_1 },
}

-- Physics Constants
BASE_TERMINAL_VELOCITY = -75.0 -- The vanilla maximum speed a player can be falling at
HIKA_TERMINAL_VELOCITY = -200.0 -- The maximum speed Hikaseru can fall at
HIKA_GRAVITY_MULT = 1.75 -- The multiplier for how much gravity affects Hikaseru
HIKA_GROUND_POUND_GRAVITY_MULT = 2.0 -- The multiplier for how much gravity affects Hikaseru during a ground pound
HIKA_HITBOX_RADIUS = 60.0 -- The width of Hikaseru's hitbox. Mario's default hitbox width is 37.0 units
HIKA_HITBOX_HEIGHT = 200.0 -- The height of Hikaseru's hitbox. Mario's default hitbox height is 160.0 units

-- Belly Flop Constants
HIKA_BELLY_FLOP_FORWARD_VEL = 32.0 -- The maximum speed Hikaseru can move during a belly flop
HIKA_DIVE_JUMP_VEL = 60.0 -- The height Hikaseru will jump when initiating a belly flop from the ground
HIKA_BELLY_FLOP_BOUNCE_HEIGHT = 80.0 -- The maximum height the Hikaseru player can reach when bouncing off the floor
HIKA_BELLY_FLOP_GRAVITY_MULT = 2.0 -- The multiplier for how much gravity affects Hikaseru during a belly flop

-- Roll Constants
HIKA_ROLL_JUMP_VEL = 40.0 -- The maximum height Hikaseru can reach when jumping during a roll

-- Air Jump Constants
HIKA_AIR_JUMP_COUNT = 5 -- The number of air jumps Hikaseru can perform before touching ground
HIKA_AIR_JUMP_VEL = 50.0 -- The maximum height of each air jump
HIKA_AIR_JUMP_FORWARD_VEL = 25.0 -- The maximum forward speed of each air jump

-- Belly Long Jump Constants
HIKA_BELLY_LONG_JUMP_PEAK_VEL = 60.0 -- The maximum speed Hikaseru can reach during a belly long jump
HIKA_BELLY_WALL_JUMP_PEAK_VEL = 70.0 -- The maximum speed Hikaseru can reach with a fully charged wall jump
HIKA_BELLY_WALL_JUMP_HEIGHT = 50.0 -- The height Hikaseru will bounce when performing a belly wall jump
HIKA_BELLY_WALL_JUMP_TIME_TO_MAX = 40 -- The number of frames Hikaseru needs to cling to a wall for the wall jump to reach max speed
HIKA_BELLY_WALL_JUMP_MAX_CLING_TIME = 60 -- The maximum number of frames Hikaseru can cling to a wall before being forced to jump

-- Trampoline Constants
HIKA_TRAMPOLINE_MAX_HEIGHT = 240.00 -- The maximum height a player can bounce to when bouncing off a Hikaseru in the trampoline state 
HIKA_TRAMPOLINE_VEL_INFLUENCE = 0.5 -- The amount a player's downward velocity should affect their bounce height off of a Hikaseru in the trampoline state
HIKA_TRAMPOLINE_BOUNCE_STRENGTH = 1.2 -- The multiplier for how much higher a player should bounce off of a Hikaseru in the trampoline state after other factors are calculated

-- Grab / Eat Object Constants
HIKA_OBJ_THROW_STRENGTH = 70.0 -- The speed objects travel when thrown by Hikaseru
HIKA_OBJ_SPIT_STRENGTH = 140.0 -- The speed objects travel when spat out of Hikaseru's mouth

-- PvP Constants
HIKA_PLAYER_THROW_STRENGTH = 70.0 -- The speed players travel when thrown by Hikaseru
HIKA_PLAYER_THROW_HEIGHT = 50.0 -- The height players reach when thrown by Hikaseru
HIKA_PLAYER_SPIT_STRENGTH = 115.0 -- The speed players travel when spat out of Hikaseru's mouth
HIKA_PLAYER_SPIT_DROP_SPEED = 50.0 -- The speed a player's gravity will kick in while being spat out of Hikaseru's mouth
HIKA_PLAYER_SPIT_SPEED_DECAY = 0.10 -- The rate at which a spat out player's speed should decrease by every frame
HIKA_HOLD_BREAKOUT_INPUTS = 5 -- The number of inputs a held player has to press to break out of Hikaseru's hold
HIKA_EATEN_BREAKOUT_INPUTS = 8 -- The number of inputs an eaten player has to press to break out of Hikaseru's belly

-- Credits to wibblus's Bowser Moveset as reference for the entire moveset flagging system and subsequent functions
-- Leave this table untouched, and instead add the flags you want in the character_set_hika_flags call below
_G.hikaMoveset = {
    isActive = true,
    FLAG_CAN_AIR_JUMP = (1 << 0), -- Allows the player to perform air jumps
    FLAG_CAN_BELLY_FLOP = (1 << 1), -- Replaces the Dive with a Belly Flop
    FLAG_CAN_BELLY_LONG_JUMP = (1 << 2), -- Replaces the Long Jump with a Belly Focused Long Jump
    FLAG_CAN_BELLY_WALL_JUMP = (1 << 3), -- Allows the player to bounce off walls when Belly Long Jumping
    FLAG_CAN_BELLY_TRAMPOLINE = (1 << 4), -- Allows the player to lie on their back and act as a trampoline
    FLAG_CAN_GRAB_ENTITIES = (1 << 5), -- Allows the player to grab entities. Can update which entities can be grabbed in GRABBABLE_OBJECTS below
    FLAG_CAN_EAT_ENTITIES = (1 << 6), -- Allows the player to eat entities they're holding. Only applies if FLAG_CAN_GRAB_ENTITIES is enabled
    FLAG_CAN_ROLL = (1 << 7), -- Allows the player to perform a roll
    FLAG_HEAVIER_IMPACT = (1 << 8), -- Whether or not to create impact effects when ground pounding and bouncing off walls
    FLAG_ALL = 0xFFFF, -- Shorthand to set all flags
}

-- Helps us track which players are using which parts of the Hikaseru Moveset
gHikaFlagsTable = {}

IS_LOGGING_ENABLED = false

---Sets the moveset flags for a given Hikaseru player
---@param characterModelID ModelExtendedId|integer The CS Model ID for your character (e.g. E_MODEL_HIKASERU)
---@param flags integer Bitfield of combined moveset flags (e.g. FLAG_CAN_AIR_JUMP)
local function character_set_hika_flags(characterModelID, flags)
    if characterModelID == nil then return end
    gHikaFlagsTable[characterModelID] = flags
end

_G.hikaMoveset.character_set_hika_flags = character_set_hika_flags

-- To customize the moveset to your own character, replace E_MODEL_HIKASERU with your own model, and replace _G.hikaMoveset.FLAG_ALL with pipe delimited flags of your choosing
-- e.g. _G.hikaMoveset.FLAG_CAN_BELLY_FLOP | _G.hikaMoveset.FLAG_CAN_ROLL | _G.hikaMoveset.FLAG_CAN_GRAB_ENTITIES
_G.hikaMoveset.character_set_hika_flags(E_MODEL_HIKASERU, _G.hikaMoveset.FLAG_ALL)

-- Actions where Hikaseru's gravity multiplier won't apply
IGNORE_GRAVITY_ACTIONS = {
    ACT_BUBBLED,
    ACT_FALL_AFTER_STAR_GRAB,
    ACT_FLYING,
    ACT_GETTING_BLOWN,
    ACT_SHOT_FROM_CANNON,
    ACT_TORNADO_TWIRLING,
    ACT_TWIRLING,
    ACT_BELLY_LONG_JUMP,
}

-- Actions Hikaseru must be in to perform an air jump
VALID_AIR_JUMP_ACTIONS = {
    ACT_FREEFALL,
    ACT_JUMP,
    ACT_DOUBLE_JUMP,
    ACT_TRIPLE_JUMP,
    ACT_SIDE_FLIP,
    ACT_BELLY_FLOP,
    ACT_WALL_KICK_AIR,
}

-- Actions a player must be in to trampoline off Hikaseru's belly, along with their properties
TRAMPOLINE_ACTION_VALS = {
    [ACT_FREEFALL] = {
        baseBounceHeight = 52.0,
        nextAction = ACT_DOUBLE_JUMP,
    },
    [ACT_JUMP] = {
        baseBounceHeight = 52.0,
        nextAction = ACT_DOUBLE_JUMP,
    },
    [ACT_DOUBLE_JUMP] = {
        baseBounceHeight = 69.0,
        nextAction = ACT_TRIPLE_JUMP,
    },
    [ACT_TRIPLE_JUMP] = {
        baseBounceHeight = 52.0,
        nextAction = ACT_DOUBLE_JUMP,
    },
    [ACT_SIDE_FLIP] = {
        baseBounceHeight = 52.0,
        nextAction = ACT_DOUBLE_JUMP,
    },
    [ACT_BACKFLIP] = {
        baseBounceHeight = 52.0,
        nextAction = ACT_DOUBLE_JUMP,
    },
    [ACT_GROUND_POUND] = {
        baseBounceHeight = 82.0,
        nextAction = ACT_DOUBLE_JUMP,
    },
    [ACT_TWIRLING] = {
        baseBounceHeight = 52.0,
        nextAction = ACT_TWIRLING,
    },
}

-- Enemies Hikaseru will pick up instead of punching
-- Stretch goal is to give each "held enemy" different properties when being held and thrown such as gravity, style of impact when it hits someone, etc.
GRABBABLE_OBJECTS = {
    id_bhvBoo,
    id_bhvBooInCastle,
    id_bhvCourtyardBooTriplet,
    id_bhvFlyGuy,
    id_bhvGhostHuntBoo,
    id_bhvGoomba,
    id_bhvKoopa,
    id_bhvMerryGoRoundBoo,
    id_bhvMoneybag,
    id_bhvMoneybagHidden,
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

gPlayerSyncTable[0].hikaState = 0

---Handles checks that need to occur on every frame
---@param m MarioState
local function hikaseru_update(m)
    if m.playerIndex ~= 0 then return end

    -- When the player is grounded, reset their air jumps and belly bounce count to zero
    if m.action & ACT_FLAG_AIR == 0 then
        gPlayerSyncTable[0].airJumpCount = 0
        gPlayerSyncTable[0].bellyBounces = 0
    end

    -- Getting the trampoline behavior to work ended up requiring some workarounds. If the player loses their INTERACT_PLAYER interact type, we can override the default bounce behavior
    gPlayerSyncTable[0].isBounceable = m.action == ACT_BELLY_TRAMPOLINE and m.actionState == 1

    -- Handles the air jump action
    if has_hika_flags(m, _G.hikaMoveset.FLAG_CAN_AIR_JUMP) and m.action & ACT_FLAG_AIR ~= 0 and m.vel.y <= 0 and gPlayerSyncTable[0].airJumpCount < HIKA_AIR_JUMP_COUNT and is_value_in_list(m.action, VALID_AIR_JUMP_ACTIONS) then
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

    -- Allows the Hikaseru player to ground pound out of a belly flop
    if m.action == ACT_BELLY_FLOP and m.controller.buttonDown & Z_TRIG ~= 0 and m.vel.y > -HIKA_AIR_JUMP_VEL and gPlayerSyncTable[0].bellyBounces > 0 then
        set_mario_action(m, ACT_GROUND_POUND, 0)
    end

    -- Allows the Hikaseru player to roll out of a ground pound
    if m.action == ACT_GROUND_POUND_LAND and m.controller.buttonDown & Z_TRIG ~= 0 and m.controller.buttonPressed & B_BUTTON ~= 0 then
        set_mario_action(m, ACT_ROLL, 0)
    end

    -- Handles certain state updates for the Hikaseru player while they're holding another player or have one in their belly
    if gPlayerSyncTable[0].eatenPlayerGlobalId then
        -- Keeping track of eaten player values to avoid softlocks and desyncs
        local eatenPlayerIndex = network_local_index_from_global(gPlayerSyncTable[0].eatenPlayerGlobalId)
        local eatenPlayer = gMarioStates[eatenPlayerIndex]

        if not eatenPlayer then
            gPlayerSyncTable[0].eatenWiggles = 0
            gPlayerSyncTable[0].eatenPlayerGlobalId = nil
            return
        end

        -- Allows other players to break out of Hikaseru's belly by mashing buttons
        if gPlayerSyncTable[0].eatenWiggles >= HIKA_EATEN_BREAKOUT_INPUTS then
            gPlayerSyncTable[0].eatenWiggles = 0
            set_mario_action(m, m.action & ACT_FLAG_AIR ~= 0 and ACT_AIR_SPIT or ACT_SPIT, 0)
        end
    elseif gPlayerSyncTable[0].heldPlayerGlobalId and m.action ~= ACT_EATING then
        -- Keeping track of held player values to avoid softlocks and desyncs
        local heldPlayerIndex = network_local_index_from_global(gPlayerSyncTable[0].heldPlayerGlobalId)
        local heldPlayer = gMarioStates[heldPlayerIndex]

        if not heldPlayer then
            -- Destroy held object / references
            if gPlayerSyncTable[0].heldObjSyncId then
                local heldObj = sync_object_get_object(gPlayerSyncTable[0].heldObjSyncId)
                if heldObj then obj_mark_for_deletion(heldObj) end
                gPlayerSyncTable[0].heldObjSyncId = nil
            end

            if m.heldObj then m.heldObj = nil end

            gPlayerSyncTable[0].heldWiggles = 0
            gPlayerSyncTable[0].heldPlayerGlobalId = nil
            set_mario_action(m, m.action & ACT_FLAG_AIR ~= 0 and ACT_FREEFALL or ACT_IDLE, 0)
            return
        end

        -- Allows other players to break out of Hikaseru's hold by mashing buttons
        if gPlayerSyncTable[0].heldWiggles >= HIKA_HOLD_BREAKOUT_INPUTS then
            gPlayerSyncTable[0].heldWiggles = 0
            set_mario_action(m, m.action & ACT_FLAG_AIR ~= 0 and ACT_AIR_THROW or ACT_THROWING, 0)
        end
    end
end

---Handles overriding existing actions with our custom ones
---@param m MarioState
---@param incomingAction integer
local function before_set_hikaseru_action(m, incomingAction)
    if m.playerIndex ~= 0 then return end

    -- Set Hikaseru's hitbox
    m.marioObj.hitboxRadius = HIKA_HITBOX_RADIUS
    m.marioObj.hitboxHeight = HIKA_HITBOX_HEIGHT

    if incomingAction == ACT_BACKFLIP and has_hika_flags(m, _G.hikaMoveset.FLAG_CAN_BELLY_TRAMPOLINE) then
        return ACT_BELLY_TRAMPOLINE
    end

    if (incomingAction == ACT_START_CROUCHING or incomingAction == ACT_CROUCH_SLIDE) and has_hika_flags(m, _G.hikaMoveset.FLAG_CAN_EAT_ENTITIES) and (gPlayerSyncTable[m.playerIndex].heldObjSyncId ~= nil or gPlayerSyncTable[m.playerIndex].heldPlayerGlobalId ~= nil) and not gPlayerSyncTable[m.playerIndex].eatenObjSyncId and not gPlayerSyncTable[m.playerIndex].eatenPlayerGlobalId then
        return ACT_EATING
    end

    -- Placeholder for the Belly Deflect mechanic
    -- if incomingAction == ACT_PUNCHING and m.controller.buttonDown & Z_TRIG ~= 0 then
    --     return ACT_BELLY_THRUST
    -- end

    if (incomingAction == ACT_PUNCHING or incomingAction == ACT_MOVE_PUNCHING) and (gPlayerSyncTable[m.playerIndex].eatenObjSyncId or gPlayerSyncTable[m.playerIndex].eatenPlayerGlobalId) then
        return ACT_SPIT
    end

    if incomingAction == ACT_JUMP_KICK and (gPlayerSyncTable[m.playerIndex].eatenObjSyncId or gPlayerSyncTable[m.playerIndex].eatenPlayerGlobalId) then
        return ACT_AIR_SPIT
    end

    if incomingAction == ACT_DIVE and has_hika_flags(m, _G.hikaMoveset.FLAG_CAN_BELLY_FLOP) then
        -- If the player is on the ground, perform a small jump leading into the belly flop
        if m.action & ACT_FLAG_AIR == 0 then
            m.vel.y = HIKA_DIVE_JUMP_VEL
        end
        return ACT_BELLY_FLOP
    end

    if incomingAction == ACT_SLIDE_KICK and has_hika_flags(m, _G.hikaMoveset.FLAG_CAN_ROLL) then
        return ACT_ROLL
    end

    if incomingAction == ACT_LONG_JUMP and has_hika_flags(m, _G.hikaMoveset.FLAG_CAN_BELLY_LONG_JUMP) then
        play_character_sound(m, CHAR_SOUND_YAHOO)
        return ACT_BELLY_LONG_JUMP
    end

    if incomingAction == ACT_GROUND_POUND_LAND then
        create_impact_effects(m)
        return
    end
end

---Handles Hikaseru's gravity multiplier
---@param m MarioState
---@param stepType integer
local function before_phys_step(m, stepType)
    if m.playerIndex ~= 0 or stepType ~= STEP_TYPE_AIR or is_value_in_list(m.action, IGNORE_GRAVITY_ACTIONS) then return end

    -- Apply gravity multiplier only if we're falling
    if m.vel.y < 0 then
        m.vel.y = math.max(m.vel.y - (4 * (m.action == ACT_GROUND_POUND and HIKA_GROUND_POUND_GRAVITY_MULT or HIKA_GRAVITY_MULT)) + 4, HIKA_TERMINAL_VELOCITY)
    end
end

-- Moveset Hooks
_G.charSelect.character_hook_moveset(CT_HIKASERU, HOOK_MARIO_UPDATE, hikaseru_update)
_G.charSelect.character_hook_moveset(CT_HIKASERU, HOOK_BEFORE_SET_MARIO_ACTION, before_set_hikaseru_action)
_G.charSelect.character_hook_moveset(CT_HIKASERU, HOOK_BEFORE_PHYS_STEP, before_phys_step)
