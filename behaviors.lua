---@param o Object
local function held_obj_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE | OBJ_FLAG_SET_FACE_YAW_TO_MOVE_YAW | OBJ_FLAG_HOLDABLE

    o.hitboxRadius = 60
    o.hitboxHeight = 100
    o.hitboxDownOffset = 0

    o.oGravity = 0.0
    o.oDragStrength = 0.0
    o.oBuoyancy = 1.0
    o.oFriction = 1.0
    o.oBounciness = 0.0
    o.oInteractType = INTERACT_GRABBABLE

    cur_obj_become_intangible()

    cur_obj_init_animation(0)
end

---Keeps an object held in a player's hands
---@param o Object
local function held_obj_loop(o)
    local m = gMarioStates[network_local_index_from_global(o.heldByPlayerIndex)]
    if o.oHeldState == HELD_THROWN then
        cur_obj_enable_rendering()
        cur_obj_become_tangible()
        cur_obj_set_pos_relative(m.marioObj, 30, 80, 100)
        o.oMoveAngleYaw = m.faceAngle.y

        o.oTimer = 0
        o.oBehParams = 1
        o.oHeldState = HELD_FREE
        o.oInteractType = 0

        play_sound(SOUND_OBJ_MRI_SHOOT, o.header.gfx.cameraToObject)
    else
        -- cur_obj_set_pos_relative(m.marioObj, 30, 60, 100)
        -- o.oHeldState = HELD_FREE
        -- spawn_mist_particles()
        -- obj_mark_for_deletion(o)
    end

    o.oFaceAnglePitch = o.oFaceAnglePitch + 0xF00
end

id_bhvHeldObj = hook_behavior(nil, OBJ_LIST_GENACTOR, false, held_obj_init, held_obj_loop, 'bhvHikaHeldObj')
id_bhvEatenObj = hook_behavior(nil, OBJ_LIST_GENACTOR, false, held_obj_init, held_obj_loop, 'bhvHikaEatenObj')