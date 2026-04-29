-- name: [CS] Hikaseru
-- description: Hikaseru v0.1 \nTraverse the Super Mario 64 universe with Hikaseru!\n\nCredits\n\nHikaseru Belongs to \\#4287f5\\MidnightLab\n\\#dcdcdc\\Mod Developed by \\#cf9e3c\\Slack\n\\#dcdcdc\\Code Donations by \\#8742f5\\wibblus

---@diagnostic disable: undefined-field
if not _G.charSelectExists then return end
_G.charSelect = _G.charSelect -- Redefining charSelect to avoid undefined-field errors in this file
---@diagnostic enable: undefined-field

-- Adding Hikaseru to Character Select
E_MODEL_HIKASERU = smlua_model_util_get_id('hikaseru_geo')
local NAME = "Hikaseru"
local DESC = { "Desc1", "Desc2" }
local CREDITS = "Model by MidnightLab\nMoveset Developed by Slack\nCode Donations by wibblus"
local COLOR = { r = 93, g = 178, b = 183 }
local TEXTURE = get_texture_info("toonTurtleLife")
CT_HIKASERU = _G.charSelect.character_add(NAME, DESC, CREDITS, COLOR, E_MODEL_HIKASERU, CT_WARIO, TEXTURE)

-- Audio
SOUND_AIR_JUMP_1 = audio_sample_load('hika_air_jump_1.ogg')
SOUND_AIR_JUMP_2 = audio_sample_load('hika_air_jump_2.ogg')
SOUND_BOUNCE_1 = audio_sample_load('hika_boing_1.ogg')
SOUND_BOUNCE_2 = audio_sample_load('hika_boing_2.ogg')
SOUND_BOUNCE_3 = audio_sample_load('hika_boing_3.ogg')
SOUND_STRAIN_1 = audio_sample_load('hika_strain_1.ogg')
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
HIKA_TERMINAL_VELOCITY = -150.0 -- The maximum speed Hikaseru can fall at
HIKA_GRAVITY_MULT = 1.25 -- The multiplier for how much gravity affects Hikaseru
HIKA_BELLY_FLOP_FORWARD_VEL = 22.0 -- The maximum speed Hikaseru can move during a belly flop
HIKA_AIR_JUMP_VEL = 40.0 -- The maximum height of each air jump
HIKA_AIR_JUMP_COUNT = 5 -- The number of air jumps Hikaseru can perform before touching ground
HIKA_DIVE_JUMP_VEL = 50.0 -- The height Hikaseru will jump when initiating a belly flop from the ground
HIKA_ROLL_JUMP_VEL = 40.0 -- The maximum height Hikaseru can reach when jumping during a roll
HIKA_OBJ_THROW_STRENGTH = 70.0 -- The speed objects travel when thrown by Hikaseru
HIKA_OBJ_SPIT_STRENGTH = 140.0 -- The speed objects travel when spat out of Hikaseru's mouth
HIKA_PLAYER_THROW_STRENGTH = 70.0 -- The speed players travel when thrown by Hikaseru
HIKA_PLAYER_SPIT_STRENGTH = 140.0 -- The speed players travel when spat out of Hikaseru's mouth
HIKA_BELLY_LONG_JUMP_PEAK_VEL = 60.0 -- The maximum speed Hikaseru can reach during a belly long jump
HIKA_TRAMPOLINE_MAX_HEIGHT = 240.00 -- The maximum height a player can bounce to when bouncing off a Hikaseru in the trampoline state 
HIKA_TRAMPOLINE_VEL_INFLUENCE = 0.5 -- The amount a player's downward velocity should affect their bounce height off of a Hikaseru in the trampoline state
HIKA_TRAMPOLINE_BOUNCE_STRENGTH = 1.5 -- The multiplier for how much higher a player should bounce off of a Hikaseru in the trampoline state after other factors are calculated
HIKA_HOLD_BREAKOUT_INPUTS = 8
HIKA_EATEN_BREAKOUT_INPUTS = 30

-- Actions where Hikaseru's gravity multiplier won't apply
local IGNORE_GRAVITY_ACTIONS = {
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
local VALID_AIR_JUMP_ACTIONS = {
    ACT_FREEFALL,
    ACT_JUMP,
    ACT_DOUBLE_JUMP,
    ACT_TRIPLE_JUMP,
    ACT_SIDE_FLIP,
    ACT_BELLY_FLOP,
    ACT_WALL_KICK_AIR,
}

-- Actions a player must be in to trampoline off Hikaseru's belly, along with their properties
local TRAMPOLINE_ACTION_VALS = {
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
local GRABBABLE_OBJECTS = {
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

---Resets all sync table values to their defaults for a given player index
---@param localIndex integer
local function reset_sync_table(localIndex)
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
end

if network_is_server() then
    reset_sync_table(0)
end

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

    -- Allows the Hikaseru player to ground pound out of a belly flop
    if m.action == ACT_BELLY_FLOP and m.controller.buttonDown & Z_TRIG ~= 0 and m.vel.y > -HIKA_AIR_JUMP_VEL and gPlayerSyncTable[0].bellyBounces > 0 then
        set_mario_action(m, ACT_GROUND_POUND, 0)
    end

    -- Allows the Hikaseru player to roll out of a ground pound
    if m.action == ACT_GROUND_POUND_LAND and m.controller.buttonDown & Z_TRIG ~= 0 and m.controller.buttonPressed & B_BUTTON ~= 0 then
        set_mario_action(m, ACT_ROLL, 0)
    end

    -- Allows other players to break out of Hikaseru's hands / belly by mashing buttons
    if gPlayerSyncTable[0].eatenPlayerGlobalId and gPlayerSyncTable[0].eatenWiggles >= HIKA_EATEN_BREAKOUT_INPUTS and (m.action ~= ACT_AIR_SPIT and m.action ~= ACT_THROWING) then
        gPlayerSyncTable[0].eatenWiggles = 0
        gPlayerSyncTable[0].eatenPlayerGlobalId = nil
        set_mario_action(m, ACT_AIR_SPIT, 0)
    elseif gPlayerSyncTable[0].heldPlayerGlobalId and gPlayerSyncTable[0].heldWiggles >= HIKA_HOLD_BREAKOUT_INPUTS and m.action ~= ACT_EATING then
        gPlayerSyncTable[0].heldWiggles = 0
        gPlayerSyncTable[0].heldPlayerGlobalId = nil
        set_mario_action(m, m.action & ACT_FLAG_AIR ~= 0 and ACT_AIR_THROW or ACT_THROWING, 0)
    end
end

---Handles overriding existing actions with our custom ones
---@param m MarioState
---@param incomingAction integer
local function before_set_hikaseru_action(m, incomingAction)
    if m.playerIndex ~= 0 then return end
    if incomingAction == ACT_BACKFLIP then
        return ACT_BELLY_TRAMPOLINE
    end

    if (incomingAction == ACT_START_CROUCHING or incomingAction == ACT_CROUCH_SLIDE) and (gPlayerSyncTable[m.playerIndex].heldObjSyncId ~= nil or gPlayerSyncTable[m.playerIndex].heldPlayerGlobalId ~= nil) and not gPlayerSyncTable[m.playerIndex].eatenObjSyncId and not gPlayerSyncTable[m.playerIndex].eatenPlayerGlobalId then
        return ACT_EATING
    end

    if incomingAction == ACT_PUNCHING and m.controller.buttonDown & Z_TRIG ~= 0 then
        return ACT_BELLY_THRUST
    end

    if (incomingAction == ACT_PUNCHING or incomingAction == ACT_MOVE_PUNCHING) and (gPlayerSyncTable[m.playerIndex].eatenObjSyncId or gPlayerSyncTable[m.playerIndex].eatenPlayerGlobalId) then
        log_to_console("Do we hit this...?")
        return ACT_SPIT
    end

    if incomingAction == ACT_JUMP_KICK and (gPlayerSyncTable[m.playerIndex].eatenObjSyncId or gPlayerSyncTable[m.playerIndex].eatenPlayerGlobalId) then
        return ACT_AIR_SPIT
    end

    if incomingAction == ACT_THROWING or incomingAction == ACT_AIR_THROW or incomingAction == ACT_AIR_THROW_LAND then
        gPlayerSyncTable[m.playerIndex].heldObjSyncId = nil
        gPlayerSyncTable[m.playerIndex].heldPlayerGlobalId = nil
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

    if incomingAction == ACT_LONG_JUMP then
        play_character_sound(m, CHAR_SOUND_YAHOO)
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
    m.vel.x = 0
    m.vel.y = 0
    m.vel.z = 0

    local modelId = obj_get_model_id_extended(victim)
    local heldObj = spawn_sync_object(id_bhvHeldObj, modelId, m.pos.x, m.pos.y, m.pos.z, function(o)
        o.header.gfx.scale.x = victim.header.gfx.scale.x
        o.header.gfx.scale.y = victim.header.gfx.scale.y
        o.header.gfx.scale.z = victim.header.gfx.scale.z

        -- Defer coins spawning until the player throws and destroys the held object
        o.oNumLootCoins = victim.oNumLootCoins
        victim.oNumLootCoins = 0
        o.globalPlayerIndex = network_global_index_from_local(m.playerIndex)
    end)

    m.heldObj = heldObj
    gPlayerSyncTable[m.playerIndex].heldObjSyncId = heldObj.oSyncID

    obj_mark_for_deletion(victim)
    set_mario_action(m, ACT_HOLD_IDLE, 0)
end

---Overrides certain PvP interactions
---@param attacker MarioState
---@param victim MarioState
---@param interaction integer
local function allow_pvp_attack(attacker, victim, interaction)
    if attacker.playerIndex ~= 0 then return end

    -- Prevents players from ground pounding Hikaseru while in the trampoline state
    if gPlayerSyncTable[victim.playerIndex].isBounceable and (interaction == INT_GROUND_POUND or interaction == INT_TWIRL) then
        return false
    end

    -- If the attack isn't a punch, we don't need to do any special actions
    if attacker.action ~= ACT_PUNCHING and attacker.action ~= ACT_MOVE_PUNCHING then
        return true
    end

    -- Zero out velocity to keep the player from sliding
    attacker.slideVelX = 0
    attacker.slideVelZ = 0
    attacker.forwardVel = 0
    attacker.vel.x = 0
    attacker.vel.y = 0
    attacker.vel.z = 0
    
    -- Creating an invisible object to help keep the Hika player behaving like they're holding an object and to give us coordinates to apply the held player to
    local heldObj = spawn_sync_object(id_bhvInvisibleHeldObj, E_MODEL_GOOMBA, attacker.pos.x, attacker.pos.y, attacker.pos.z, function(o)
        o.header.gfx.scale.x = 0
        o.header.gfx.scale.y = 0
        o.header.gfx.scale.z = 0
    end)

    attacker.heldObj = heldObj

    gPlayerSyncTable[0].heldObjSyncId = heldObj.oSyncID
    gPlayerSyncTable[0].heldPlayerGlobalId = network_global_index_from_local(victim.playerIndex)

    set_mario_action(attacker, ACT_HOLD_IDLE, 0)
    network_send_to(victim.playerIndex, true, { key = "actHikaHeld", hikaPlayerGlobalId = network_global_index_from_local(0), hikaInvisObjSyncId = heldObj.oSyncID })

    return false
end

---Handles the bounce interaction. Unlike most of the code, this hook is focusing on the non Hikaseru player
---@param m MarioState
---@param o Object
local function on_interact(m, o)
    if m.playerIndex ~= 0 or m.vel.y >= 0 or not TRAMPOLINE_ACTION_VALS[m.action] then return end
    
    -- Get the Hikaseru player and confirm both players are in a valid state to allow for a bounce
    local mV = get_mario_state_from_object(o)
    if not mV or not gPlayerSyncTable[mV.playerIndex].isBounceable then return end

    -- Calculate the bounce height based on the player's downward velocity and current action
    local velInfluence = math.abs(m.vel.y * HIKA_TRAMPOLINE_VEL_INFLUENCE)
    local baseBounceHeight = TRAMPOLINE_ACTION_VALS[m.action].baseBounceHeight
    local bounceHeight = math.min((baseBounceHeight + velInfluence) * HIKA_TRAMPOLINE_BOUNCE_STRENGTH, HIKA_TRAMPOLINE_MAX_HEIGHT)
    m.vel.y = bounceHeight
    mV.marioObj.header.gfx.animInfo.animFrame = 32
end

---Ensures audio and visual updates are seen for all players
---@param dataTable table
local function on_receive_packet(dataTable)
    log_to_console("Packet Received")
    if not dataTable or not dataTable.key then return end

    -- 
    if dataTable.key == "actHikaHeld" then
        log_to_console("Packet Receieved: actHikaHeld")
        local hikaPlayer = gMarioStates[network_local_index_from_global(dataTable.hikaPlayerGlobalId)]
        if not hikaPlayer then log_to_console("No Player Found in actHikaHeld") return end

        local invisObj = sync_object_get_object(dataTable.hikaInvisObjSyncId)
        hikaPlayer.heldObj = invisObj
        
        local grabbedPlayer = gMarioStates[0]
        gPlayerSyncTable[0].holderGlobalId = dataTable.hikaPlayerGlobalId

        set_mario_action(grabbedPlayer, ACT_HELD, 0)
    elseif dataTable.key == "actHikaEaten" then
        -- Tells the player receiving the packet to switch to the thrown state
        log_to_console("Packet Receieved: actHikaEaten")
        local hikaPlayer = gMarioStates[network_local_index_from_global(dataTable.hikaPlayerGlobalId)]
        if not hikaPlayer then log_to_console("No Player Found in actHikaEaten") return end
        
        local eatenPlayer = gMarioStates[0]
        gPlayerSyncTable[eatenPlayer.playerIndex].eaterGlobalId = dataTable.hikaPlayerGlobalId
        gPlayerSyncTable[eatenPlayer.playerIndex].holderGlobalId = nil

        set_mario_action(eatenPlayer, ACT_EATEN, 0)
    elseif dataTable.key == "actHikaSpatOut" then
        -- Tells the player receiving the packet to switch to the spat out state
        log_to_console("Packet Receieved: actHikaSpatOut")
        local hikaPlayer = gMarioStates[network_local_index_from_global(dataTable.hikaPlayerGlobalId)]
        if not hikaPlayer then log_to_console("No Player Found in actHikaSpatOut") return end
        
        local eatenPlayer = gMarioStates[0]
        gPlayerSyncTable[eatenPlayer.playerIndex].eaterGlobalId = nil

        eatenPlayer.faceAngle.y = -hikaPlayer.faceAngle.y
        eatenPlayer.forwardVel = HIKA_PLAYER_SPIT_STRENGTH

        set_mario_action(eatenPlayer, ACT_SPAT_OUT, 0)
    end
end

---Handles resetting a held player's state when thrown
local function on_mario_update(m)
    if m.playerIndex ~= 0 then return end

    -- Ensures the player gets put into the correct state when Hika throws them
    if gPlayerSyncTable[0].holderGlobalId then
        if m.action ~= ACT_HELD then
            gPlayerSyncTable[0].holderGlobalId = nil
        else
            local holderLocalIndex = network_local_index_from_global(gPlayerSyncTable[0].holderGlobalId)
            local holder = gMarioStates[holderLocalIndex]
            if not holder then
                gPlayerSyncTable[0].holderGlobalId = nil
            elseif holder.action == ACT_THROWING or holder.action == ACT_AIR_THROW or holder.action == ACT_AIR_THROW_LAND then
                cur_obj_become_tangible()
                m.vel.y = 50.0
                m.forwardVel = HIKA_PLAYER_THROW_STRENGTH
                set_mario_action(m, ACT_THROWN_FORWARD, 0)
                gPlayerSyncTable[0].holderGlobalId = nil
            end
        end
    end

    if gPlayerSyncTable[0].eaterGlobalId then
        if m.action ~= ACT_EATEN then
            gPlayerSyncTable[0].eaterGlobalId = nil
        else
            local eaterLocalIndex = network_local_index_from_global(gPlayerSyncTable[0].eaterGlobalId)
            local eater = gMarioStates[eaterLocalIndex]
            if not eater then
                gPlayerSyncTable[0].eaterGlobalId = nil
            elseif eater.action == ACT_PUNCHING or eater.action == ACT_MOVE_PUNCHING then
                cur_obj_enable_rendering()
                set_mario_action(m, ACT_SPAT_OUT, 0)
                gPlayerSyncTable[0].eaterGlobalId = nil
            end
        end
    end

    if m.controller.buttonPressed & L_JPAD ~= 0 then
        -- Log ALL the attributes on the local player's gPlayerSyncTable
        log_to_console("=================")
        log_to_console("LOCAL PLAYER'S gPlayerSyncTable")
        log_to_console("gPlayerSyncTable[0].holderGlobalId: " .. tostring(gPlayerSyncTable[0].holderGlobalId))
        log_to_console("gPlayerSyncTable[0].heldObjSyncId: " .. tostring(gPlayerSyncTable[0].heldObjSyncId))
        log_to_console("gPlayerSyncTable[0].heldPlayerGlobalId: " .. tostring(gPlayerSyncTable[0].heldPlayerGlobalId))
        -- log_to_console("gPlayerSyncTable[0].eatenObjSyncId: " .. tostring(gPlayerSyncTable[0].eatenObjSyncId))
        -- log_to_console("gPlayerSyncTable[0].eatenPlayerGlobalId: " .. tostring(gPlayerSyncTable[0].eatenPlayerGlobalId))
        log_to_console("gPlayerSyncTable[0].heldWiggles: " .. tostring(gPlayerSyncTable[0].heldWiggles))
        log_to_console("gPlayerSyncTable[0].eatenWiggles: " .. tostring(gPlayerSyncTable[0].eatenWiggles))
        log_to_console("=================")
        log_to_console("OTHER PLAYER'S gPlayerSyncTable")
        log_to_console("gPlayerSyncTable[1].holderGlobalId: " .. tostring(gPlayerSyncTable[1].holderGlobalId))
        log_to_console("gPlayerSyncTable[1].heldObjSyncId: " .. tostring(gPlayerSyncTable[1].heldObjSyncId))
        log_to_console("gPlayerSyncTable[1].heldPlayerGlobalId: " .. tostring(gPlayerSyncTable[1].heldPlayerGlobalId))
        -- log_to_console("gPlayerSyncTable[1].eatenObjSyncId: " .. tostring(gPlayerSyncTable[1].eatenObjSyncId))
        -- log_to_console("gPlayerSyncTable[1].eatenPlayerGlobalId: " .. tostring(gPlayerSyncTable[1].eatenPlayerGlobalId))
        log_to_console("gPlayerSyncTable[1].heldWiggles: " .. tostring(gPlayerSyncTable[1].heldWiggles))
        log_to_console("gPlayerSyncTable[1].eatenWiggles: " .. tostring(gPlayerSyncTable[1].eatenWiggles))
    end
end

---Resets sync properties for a player whenever they connect or disconnect
---@param m MarioState
local function on_connect(m)
    if not network_is_server() then return end
    reset_sync_table(m.playerIndex)
end

-- Moveset Hooks
_G.charSelect.character_hook_moveset(CT_HIKASERU, HOOK_MARIO_UPDATE, hikaseru_update)
_G.charSelect.character_hook_moveset(CT_HIKASERU, HOOK_BEFORE_SET_MARIO_ACTION, before_set_hikaseru_action)
_G.charSelect.character_hook_moveset(CT_HIKASERU, HOOK_BEFORE_PHYS_STEP, before_phys_step)

-- Event Hooks
hook_event(HOOK_ON_ATTACK_OBJECT, on_attack_object)
hook_event(HOOK_ALLOW_PVP_ATTACK, allow_pvp_attack)
hook_event(HOOK_ON_INTERACT, on_interact)
hook_event(HOOK_ON_PACKET_RECEIVE, on_receive_packet)
hook_event(HOOK_ON_WARP, function() reset_sync_table(0) end)
hook_event(HOOK_MARIO_UPDATE, on_mario_update)
hook_event(HOOK_ON_PLAYER_CONNECTED, on_connect)
hook_event(HOOK_ON_PLAYER_DISCONNECTED, on_connect)
