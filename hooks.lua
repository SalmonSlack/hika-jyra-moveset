---Handles the grab action on enemies. Only runs from the perspective of the attacking player
---@param m MarioState
---@param victim Object
local function on_attack_object(m, victim)
    if not has_hika_flags(m, _G.hikaMoveset.FLAG_CAN_GRAB_ENTITIES) or not is_value_in_list(get_id_from_behavior(victim.behavior), GRABBABLE_OBJECTS) then return end

    -- If the attack isn't a punch, we don't need to do any special actions
    if m.action ~= ACT_PUNCHING and m.action ~= ACT_MOVE_PUNCHING then
        return
    end

    -- Only create the held object if the local Hikaseru player. Everything else will get synced down the line
    local modelId = obj_get_model_id_extended(victim)
    local heldObj = spawn_sync_object(id_bhvHeldObj, modelId, m.pos.x, m.pos.y, m.pos.z, function(o)
        o.header.gfx.scale.x = victim.header.gfx.scale.x
        o.header.gfx.scale.y = victim.header.gfx.scale.y
        o.header.gfx.scale.z = victim.header.gfx.scale.z

        -- Defer coins spawning until the player throws and destroys the held object
        o.oNumLootCoins = victim.oNumLootCoins
        o.globalPlayerIndex = network_global_index_from_local(m.playerIndex)
    end)

    m.heldObj = heldObj
    network_send(true, { key = "updateHikaHeldObj", hikaPlayerGlobalId = network_global_index_from_local(m.playerIndex), hikaInvisObjSyncId = heldObj.oSyncID })
    gPlayerSyncTable[m.playerIndex].heldObjSyncId = heldObj.oSyncID

    victim.oNumLootCoins = 0
    network_send(true, { key = "updateObjLootCoins", objSyncId = victim.oSyncID, numCoins = 0 })

    obj_mark_for_deletion(victim)
    set_mario_action(m, ACT_PICKING_UP, 0)
end

---Handles the grab player action and prevents certain actions being performed on Hikaseru while he's in specific states
---The allow PvP attack hook will run from either the perspective of the attacker or the victim, so we have to account for both possibilities
---@param attacker MarioState
---@param victim MarioState
---@param interaction integer
local function allow_pvp_attack(attacker, victim, interaction)
    if (attacker.playerIndex ~= 0 and victim.playerIndex ~= 0) or not has_hika_flags(attacker, _G.hikaMoveset.FLAG_CAN_GRAB_ENTITIES) then return end

    -- Prevents players from ground pounding Hikaseru while in the trampoline state
    if gPlayerSyncTable[victim.playerIndex].isBounceable and (interaction == INT_GROUND_POUND or interaction == INT_TWIRL) then
        return false
    end

    -- If the attack isn't a punch, or the victim is already holding someone, allow the PvP interaction
    if attacker.action ~= ACT_PUNCHING and attacker.action ~= ACT_MOVE_PUNCHING or (gPlayerSyncTable[victim.playerIndex].heldObjSyncId or gPlayerSyncTable[victim.playerIndex].heldPlayerGlobalId) then
        gPlayerSyncTable[victim.playerIndex].heldObjSyncId = nil
        gPlayerSyncTable[victim.playerIndex].heldPlayerGlobalId = nil
        return true
    end

    -- Creating an invisible object to help keep the Hika player behaving like they're holding an object and to give us coordinates to apply the held player to
    local heldObj = spawn_sync_object(id_bhvInvisibleHeldObj, E_MODEL_GOOMBA, attacker.pos.x, attacker.pos.y, attacker.pos.z, function(o)
        -- Using a Goomba Model with a zeroed out scale since m.marioBodyState.heldObjLastPosition won't update on E_MODEL_NONE
        o.header.gfx.scale.x = 0
        o.header.gfx.scale.y = 0
        o.header.gfx.scale.z = 0
    end)

    -- This value desyncs when set this way so we're sending a packet to set it for all clients
    attacker.heldObj = heldObj
    network_send(true, { key = "updateHikaHeldObj", hikaPlayerGlobalId = network_global_index_from_local(attacker.playerIndex), hikaInvisObjSyncId = heldObj.oSyncID })

    gPlayerSyncTable[attacker.playerIndex].heldObjSyncId = heldObj.oSyncID
    gPlayerSyncTable[attacker.playerIndex].heldPlayerGlobalId = network_global_index_from_local(victim.playerIndex)
    gPlayerSyncTable[victim.playerIndex].holderGlobalId = network_global_index_from_local(attacker.playerIndex)

    -- Only send the packet one time from attacker to victim or from victim to attacker
    if attacker.playerIndex == 0 then
        log("allow_pvp_attack - Attacker POV, sending actHikaHeld packet to Victim")
        set_mario_action(attacker, ACT_PICKING_UP, 0)
        network_send_to(victim.playerIndex, true, { key = "actHikaHeld", hikaPlayerGlobalId = network_global_index_from_local(attacker.playerIndex) })
    elseif victim.playerIndex == 0 then
        log("allow_pvp_attack - Victim POV, sending actHikaHold packet to Attacker")
        set_mario_action(victim, ACT_HELD, 0)
        network_send_to(attacker.playerIndex, true, { key = "actHikaHold", hikaPlayerGlobalId = network_global_index_from_local(attacker.playerIndex) })
    end

    return false
end

---Handles the bounce interaction when a player interacts with Hikaseru in the trampoline state
---@param m MarioState
---@param o Object
local function on_interact(m, o)
    if m.playerIndex ~= 0 or not TRAMPOLINE_ACTION_VALS[m.action] then return end

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

---Ensures players are put into the correct states across all clients
---@param dataTable table
local function on_receive_packet(dataTable)
    if not dataTable or not dataTable.key then return end

    if dataTable.key == "updateHikaHeldObj" then
        log("Packet Receieved: updateHikaHeldObj")
        local hikaPlayer = gMarioStates[network_local_index_from_global(dataTable.hikaPlayerGlobalId)]
        if not hikaPlayer then log("No Player Found in updateHikaHeldObj") return end

        local invisObj = sync_object_get_object(dataTable.hikaInvisObjSyncId)
        hikaPlayer.heldObj = invisObj
    elseif dataTable.key == "actHikaHold" then
        log("Packet Receieved: actHikaHold")
        local hikaPlayer = gMarioStates[network_local_index_from_global(dataTable.hikaPlayerGlobalId)]
        if not hikaPlayer then log("No Player Found in actHikaHold") return end

        set_mario_action(hikaPlayer, ACT_PICKING_UP, 0)
    elseif dataTable.key == "actHikaHeld" then
        log("Packet Receieved: actHikaHeld")
        local hikaPlayer = gMarioStates[network_local_index_from_global(dataTable.hikaPlayerGlobalId)]
        if not hikaPlayer then log("No Player Found in actHikaHeld") return end
        
        local grabbedPlayer = gMarioStates[0]

        set_mario_action(grabbedPlayer, ACT_HELD, 0)
    elseif dataTable.key == "actHikaEaten" then
        -- Tells the player receiving the packet to switch to the thrown state
        log("Packet Receieved: actHikaEaten")
        local hikaPlayer = gMarioStates[network_local_index_from_global(dataTable.hikaPlayerGlobalId)]
        if not hikaPlayer then log("No Player Found in actHikaEaten") return end
        
        local eatenPlayer = gMarioStates[0]
        gPlayerSyncTable[eatenPlayer.playerIndex].eaterGlobalId = dataTable.hikaPlayerGlobalId
        gPlayerSyncTable[eatenPlayer.playerIndex].holderGlobalId = nil

        set_mario_action(eatenPlayer, ACT_EATEN, 0)
    elseif dataTable.key == "actHikaSpatOut" then
        -- Tells the player receiving the packet to switch to the spat out state
        log("Packet Receieved: actHikaSpatOut")
        local hikaPlayer = gMarioStates[network_local_index_from_global(dataTable.hikaPlayerGlobalId)]
        if not hikaPlayer then log("No Player Found in actHikaSpatOut") return end
        
        local eatenPlayer = gMarioStates[0]
        gPlayerSyncTable[eatenPlayer.playerIndex].eaterGlobalId = nil

        eatenPlayer.pos.y = hikaPlayer.pos.y + hikaPlayer.marioObj.hitboxHeight - 40
        eatenPlayer.faceAngle.y = hikaPlayer.faceAngle.y + 0x8000
        eatenPlayer.forwardVel = -HIKA_PLAYER_SPIT_STRENGTH

        set_mario_action(eatenPlayer, ACT_SPAT_OUT, 0)
    elseif dataTable.key == "updateObjLootCoins" then
        log("Packet Receieved: updateObjLootCoins")
        local obj = sync_object_get_object(dataTable.objSyncId)
        if not obj then log("No Object Found in updateObjLootCoins") return end

        obj.oNumLootCoins = dataTable.numCoins
    end
end

---Handles resetting a held player's state when thrown
---@param m MarioState
local function on_mario_update(m)
    if m.playerIndex ~= 0 then return end

    -- Ensures the player gets put into the correct state when held by Hikaseru
    if gPlayerSyncTable[0].holderGlobalId then
        local holderLocalIndex = network_local_index_from_global(gPlayerSyncTable[0].holderGlobalId)
        local holder = gMarioStates[holderLocalIndex]
        if not holder then
            cur_obj_become_tangible()
            gPlayerSyncTable[0].holderGlobalId = nil
            set_mario_action(m, m.flags & ACT_FLAG_AIR ~= 0 and ACT_FREEFALL or ACT_IDLE, 0)
        elseif holder.action == ACT_THROWING or holder.action == ACT_AIR_THROW or holder.action == ACT_AIR_THROW_LAND then
            cur_obj_become_tangible()
            m.vel.y = HIKA_PLAYER_THROW_HEIGHT
            m.forwardVel = HIKA_PLAYER_THROW_STRENGTH
            set_mario_action(m, ACT_THROWN_FORWARD, 0)
            gPlayerSyncTable[0].holderGlobalId = nil
            gPlayerSyncTable[m.playerIndex].heldObjSyncId = nil
            gPlayerSyncTable[m.playerIndex].heldPlayerGlobalId = nil
        elseif gPlayerSyncTable[network_local_index_from_global(gPlayerSyncTable[0].holderGlobalId)].heldPlayerGlobalId ~= network_global_index_from_local(0) then
            cur_obj_become_tangible()
            gPlayerSyncTable[0].holderGlobalId = nil
            set_mario_action(m, m.flags & ACT_FLAG_AIR ~= 0 and ACT_FREEFALL or ACT_IDLE, 0)
        else

        end
    end

    -- Ensures the player gets put into the correct state when eaten by Hikaseru
    if gPlayerSyncTable[0].eaterGlobalId then
        if m.action ~= ACT_EATEN and m.action ~= ACT_SPAT_OUT then
            cur_obj_become_tangible()
            cur_obj_enable_rendering()
            gPlayerSyncTable[0].eaterGlobalId = nil
        else
            local eaterLocalIndex = network_local_index_from_global(gPlayerSyncTable[0].eaterGlobalId)
            local eater = gMarioStates[eaterLocalIndex]
            if not eater then
                cur_obj_become_tangible()
                cur_obj_enable_rendering()
                gPlayerSyncTable[0].eaterGlobalId = nil
            elseif eater.action == ACT_PUNCHING or eater.action == ACT_MOVE_PUNCHING then
                cur_obj_become_tangible()
                cur_obj_enable_rendering()
                set_mario_action(m, ACT_SPAT_OUT, 0)
                gPlayerSyncTable[0].eaterGlobalId = nil
            elseif gPlayerSyncTable[network_local_index_from_global(gPlayerSyncTable[0].eaterGlobalId)].eatenPlayerGlobalId ~= network_global_index_from_local(0) then
                cur_obj_become_tangible()
                cur_obj_enable_rendering()
                set_mario_action(m, m.flags & ACT_FLAG_AIR ~= 0 and ACT_FREEFALL or ACT_IDLE, 0)
                gPlayerSyncTable[0].eaterGlobalId = nil
            end
        end
    end
end

---Resets sync properties for a player whenever they connect or disconnect
---@param m MarioState
local function on_connect(m)
    if not network_is_server() then return end
    reset_sync_table(m.playerIndex)
end

---Keeps Hika Flags in sync with the player before they perform any actions
local function before_set_mario_action()
    apply_player_hika_flags()
end

-- Event Hooks
hook_event(HOOK_ON_ATTACK_OBJECT, on_attack_object)
hook_event(HOOK_ALLOW_PVP_ATTACK, allow_pvp_attack)
hook_event(HOOK_ON_INTERACT, on_interact)
hook_event(HOOK_ON_PACKET_RECEIVE, on_receive_packet)
hook_event(HOOK_ON_WARP, function() reset_sync_table(0) end)
hook_event(HOOK_MARIO_UPDATE, on_mario_update)
hook_event(HOOK_BEFORE_SET_MARIO_ACTION, before_set_mario_action)
hook_event(HOOK_ON_PLAYER_CONNECTED, on_connect)
hook_event(HOOK_ON_PLAYER_DISCONNECTED, on_connect)
hook_event(HOOK_ON_MODS_LOADED, function() if network_is_server() then reset_sync_table(0) end end)
