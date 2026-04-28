---Initializes a generic held object to take the place of an enemy picked up by a player
---@param o Object
local function held_obj_init(o)
    -- Flags
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE | OBJ_FLAG_COMPUTE_DIST_TO_MARIO | OBJ_FLAG_HOLDABLE
    o.oInteractType = INTERACT_GRABBABLE
    o.oInteractStatus = INT_GROUND_POUND
    o.oHeldState = HELD_HELD
    o.oBehParams = 0 -- Tells us whether the object is in the eaten state or not

    -- Hitbox
    o.hitboxRadius = 300
    o.hitboxHeight = 500
    o.hitboxDownOffset = 0
    o.hurtboxRadius = 300
    o.hurtboxHeight = 500

    -- Physics
    o.oGravity = -1.7
    o.oDragStrength = 0.0
    o.oBuoyancy = 1.4
    o.oFriction = 1.0
    o.oBounciness = 10.0

    -- Rotation
    o.header.gfx.sharedChild.extraFlags = o.header.gfx.sharedChild.extraFlags | GRAPH_EXTRA_ROTATE_HELD
    o.oFaceAnglePitch = 0
    o.oFaceAngleYaw = 0x4000
    o.oFaceAngleRoll = 0x4000
end

---Handles the custom object holding interactions. Credits to wibblus and their Ario moveset for the bulk of the logic in this function
---@param o Object
local function held_obj_loop(o)
    local m = gMarioStates[network_local_index_from_global(o.heldByPlayerIndex)]
    if o.oHeldState == HELD_FREE then
        if o.oBehParams == 0 then
            -- Thrown from held state
            o.oForwardVel = HIKA_OBJ_THROW_STRENGTH
            o.oFaceAnglePitch = o.oFaceAnglePitch + 0xF00

            -- o.oGravity = approach_f32(o.oGravity, -1.5, 0.1, 0.1)
            o.oVelY = approach_f32(o.oVelY, -16.0, 0.5, 0.5)

            cur_obj_update_floor_and_resolve_wall_collisions(45)
            obj_attack_collided_from_other_object(o)
            cur_obj_move_standard(45)

            if o.oTimer > 60 or o.oMoveFlags & OBJ_MOVE_HIT_WALL ~= 0 or o.oMoveFlags & OBJ_COL_FLAG_GROUNDED ~= 0 then
                spawn_mist_particles()
                if o.oNumLootCoins % 5 == 0 then
                    obj_spawn_loot_blue_coins(o, o.oNumLootCoins // 5, 20.0, 150)
                else
                    obj_spawn_loot_yellow_coins(o, o.oNumLootCoins, 20.0)
                end
                obj_mark_for_deletion(o)
                play_sound(SOUND_OBJ_ENEMY_DEATH_HIGH, o.header.gfx.cameraToObject)
            end
        elseif o.oBehParams == 1 then
            -- Thrown from eaten state

            -- Object travels in a straight line for awhile before gravity takes effect
            if o.oTimer < 60 then
                o.oGravity = 0
            else
                o.oGravity = -1.5
            end

            o.oForwardVel = HIKA_OBJ_SPIT_STRENGTH
            o.oFaceAnglePitch = o.oFaceAnglePitch + 0xF00

            cur_obj_update_floor_and_resolve_wall_collisions(45)
            obj_attack_collided_from_other_object(o)
            cur_obj_move_standard(45)

            if o.oTimer > 120 or o.oMoveFlags & OBJ_MOVE_HIT_WALL ~= 0 or o.oMoveFlags & OBJ_COL_FLAG_GROUNDED ~= 0 then
                spawn_mist_particles()
                if o.oNumLootCoins % 5 == 0 then
                    obj_spawn_loot_blue_coins(o, o.oNumLootCoins // 5, 20.0, 150)
                else
                    obj_spawn_loot_yellow_coins(o, o.oNumLootCoins, 20.0)
                end
                obj_mark_for_deletion(o)
                play_sound(SOUND_OBJ_ENEMY_DEATH_HIGH, o.header.gfx.cameraToObject)
            end
        end
    elseif o.oHeldState == HELD_HELD then
        -- Object will render automatically in the player's hands, so we disable rendering here to prevent a duplicate object
        cur_obj_disable_rendering()
        cur_obj_become_intangible()
    elseif o.oHeldState == HELD_THROWN then
        cur_obj_enable_rendering()
        cur_obj_become_tangible()
        cur_obj_set_pos_relative(m.marioObj, 30, 80, 100)
        o.oMoveAngleYaw = m.faceAngle.y

        o.oTimer = 0
        o.oHeldState = HELD_FREE
        o.oInteractType = 0

        o.oVelY = o.oBehParams == 0 and 30 or 0

        play_sound(SOUND_OBJ_EVIL_LAKITU_THROW, o.header.gfx.cameraToObject)
    elseif o.oHeldState == HELD_DROPPED then
        if o.oBehParams == 1 then cur_obj_disable_rendering() return end

        local m = gMarioStates[network_local_index_from_global(o.globalPlayerIndex)]

        -- Getting Eaten
        if m.action == ACT_EATING then
            cur_obj_enable_rendering()
            cur_obj_set_pos_relative(m.marioObj, 30, 80, 100)
        elseif gPlayerSyncTable[m.playerIndex].eatenPlayerGlobalId or (gPlayerSyncTable[m.playerIndex].eatenObjSyncId and gPlayerSyncTable[m.playerIndex].eatenObjSyncId ~= o.oSyncID) then
            -- Dropping held object while another object is in Hikaseru's mouth
            cur_obj_enable_rendering()
            cur_obj_update_floor_and_resolve_wall_collisions(45)
            obj_attack_collided_from_other_object(o)
            cur_obj_move_standard(45)
        end
    end
end

id_bhvHeldObj = hook_behavior(nil, OBJ_LIST_DESTRUCTIVE, false, held_obj_init, held_obj_loop, 'bhvHikaHeldObj')
id_bhvEatenObj = hook_behavior(nil, OBJ_LIST_GENACTOR, false, held_obj_init, held_obj_loop, 'bhvHikaEatenObj')
