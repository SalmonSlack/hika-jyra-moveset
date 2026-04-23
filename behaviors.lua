---Initializes a generic held object to take the place of an enemy picked up by a player
---@param o Object
local function held_obj_init(o)
    -- Flags
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE | OBJ_FLAG_COMPUTE_DIST_TO_MARIO | OBJ_FLAG_HOLDABLE
    o.oInteractType = INTERACT_GRABBABLE
    o.oHeldState = HELD_HELD

    -- Hitbox
    o.hitboxRadius = 60
    o.hitboxHeight = 100
    o.hitboxDownOffset = 0

    -- Physics
    o.oGravity = -1.5
    o.oDragStrength = 0.0
    o.oBuoyancy = 1.0
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
        o.oForwardVel = HIKA_OBJ_THROW_STRENGTH
        o.oFaceAnglePitch = o.oFaceAnglePitch + 0xF00

        cur_obj_update_floor_and_resolve_wall_collisions(45)
        cur_obj_move_standard(45)

        if o.oTimer > 60 or o.oMoveFlags & OBJ_MOVE_HIT_WALL ~= 0 or o.oMoveFlags & OBJ_COL_FLAG_GROUNDED ~= 0 then
            spawn_mist_particles()
            obj_mark_for_deletion(o)
            play_sound(SOUND_OBJ_ENEMY_DEATH_HIGH, o.header.gfx.cameraToObject)
        end
    elseif o.oHeldState == HELD_HELD then
        cur_obj_disable_rendering()
        cur_obj_become_intangible()
    elseif o.oHeldState == HELD_THROWN or o.oHeldState == HELD_DROPPED then
        cur_obj_enable_rendering()
        cur_obj_become_tangible()
        cur_obj_set_pos_relative(m.marioObj, 30, 80, 100)
        o.oMoveAngleYaw = m.faceAngle.y

        o.oTimer = 0
        o.oBehParams = 1
        o.oHeldState = HELD_FREE
        o.oInteractType = 0

        play_sound(SOUND_OBJ_EVIL_LAKITU_THROW, o.header.gfx.cameraToObject)
    end
end

id_bhvHeldObj = hook_behavior(nil, OBJ_LIST_GENACTOR, false, held_obj_init, held_obj_loop, 'bhvHikaHeldObj')
id_bhvEatenObj = hook_behavior(nil, OBJ_LIST_GENACTOR, false, held_obj_init, held_obj_loop, 'bhvHikaEatenObj')
