package game
/*
# Overview
An Entity is a world object. This can be the player, an enemy, or a box. Basically
anything that can be spawned in the world.

# Creating New Entity Type
1. Create a struct to represent the data unqiue to this type.
2. Add the new struct type to the Entity_Type union below.
3. Put an entry in the switch in `entity_tick` below.
*/

import "core:log"
import "core:fmt"
import sa "core:container/small_array"
import rl "vendor:raylib"


// +-------------------------------------------------------------------------------------+
// |                                   !DEFINITIONS!                                     |
// +-------------------------------------------------------------------------------------+


// The maximum amount of Entities allowed at one time.
MAX_ENTITIES :: 120


// A reference to an Entity.
Entity_Handle :: distinct Handle


// ---------------------------------- !END DEFINITIONS! ----------------------------------


// +-------------------------------------------------------------------------------------+
// |                                      !TYPES!                                        |
// +-------------------------------------------------------------------------------------+


// A reference to something in the World.
Handle :: struct {
    id: int,
    generation: int,

    world: ^World,
}


// Attribute flags for an Entity.
Entity_Flag :: enum {
    Valid,      // Is a valid instance.
    Hittable,   // Can be hit by attacks.
    Solid,      // Can collide with other Entities.
}


// Entity data.
Entity :: struct {
    display_name: string,
    id: int,
    flags: bit_set[Entity_Flag],

    animator: Animator,
    type: Entity_Type,

    position: World_Coords,
    offset: [2]f32,

    _active_id: int,
    _generation: int,
}


// Variations of an Entity.
Entity_Type :: union {
    Character,
    Object,
}


// ------------------------------------- !END TYPES! -------------------------------------


// +-------------------------------------------------------------------------------------+
// |                                       !HANDLE!                                      |
// +-------------------------------------------------------------------------------------+


// Checks if the given Entity_Handle is valid.
entity_handle_valid :: proc(handle: Entity_Handle, loc := #caller_location) -> bool {
    if handle.world == nil || handle.id >= MAX_ENTITIES {
        return false
    }

    entity := handle.world.entities[handle.id]
    return entity._generation == handle.generation && .Valid in entity.flags
}



// Gets a pointer to the Entity the handle points to. Returns nil if it does
// not point to a valid Entity.
get_entity :: proc(handle: Entity_Handle, loc := #caller_location) -> ^Entity {
    is_valid := entity_handle_valid(handle)
    if !is_valid do return nil

    return &handle.world.entities[handle.id]
}


// Creates a new Entity_Handle from an Entity.
new_entity_handle :: proc{
    new_entity_handle_from_instance,
    new_entity_handle_from_id,
}


// Creates a new Entity_Handle from an instance of a Entity.
new_entity_handle_from_instance :: proc(world: ^World, entity: Entity, loc := #caller_location) -> Entity_Handle {
    assert(world != nil, "Nil World pointer.", loc)
    assert(entity.id < MAX_ENTITIES, "Invalid Entity ID.", loc)

    return {
        id = entity.id,
        generation = entity._generation,

        world = world,
    }
}


// Creates a new Entity_Handle from an Entity id.
new_entity_handle_from_id :: proc(world: ^World, id: int, loc := #caller_location) -> Entity_Handle {
    assert(world != nil, "Nil World pointer.", loc)
    assert(id < MAX_ENTITIES, "Invalid Entity ID.", loc)

    entity := world.entities[id]
    if .Valid not_in entity.flags {
        log.errorf("Trying to create an Entity_Handle using an invalid ID (%v)", id, loc)
        return {}
    }

    return {
        id = entity.id,
        generation = entity._generation,

        world = world,
    }
}


// ------------------------------------- !END HANDLE! ------------------------------------


// +-------------------------------------------------------------------------------------+
// |                                    !ENTITY!                                         |
// +-------------------------------------------------------------------------------------+


// Creates a new instance of a Entity.
new_entity :: proc(world: ^World, loc := #caller_location) -> Entity_Handle {
    assert(world != nil, "Nil World pointer.", loc)

    if sa.len(world._inactive_entities) <= 0 {
        log.error("Could not find a free Entity slot.", loc)
        return Entity_Handle{}
    }

    new_id := sa.pop_front(&world._inactive_entities)
    new_entity := &world.entities[new_id]

    new_entity.id = new_id
    new_entity.flags = { .Valid }

    handle := new_entity_handle(world, new_entity^, loc)

    new_entity._active_id = sa.len(world._active_entities)
    sa.append(&world._active_entities, new_id)

    return handle
}


// Removes the given Entity from the world.
free_entity :: proc(handle: Entity_Handle, loc := #caller_location) {
    freed_entity := get_entity(handle, loc)
    assert(freed_entity != nil, "Got a nil Entity from Handle.", loc)

    freed_entity._generation += 1
    freed_entity.flags -= { .Valid }

    // Remove from active Entity list.
    sa.unordered_remove(&handle.world._active_entities, freed_entity._active_id, loc)

    if sa.len(handle.world._active_entities) > 0 {
        moved_id := sa.get(handle.world._active_entities, freed_entity._active_id)
        moved_entity := &handle.world.entities[moved_id]
        moved_entity._active_id = freed_entity._active_id
    }

    // Add to inactive Entity list.
    sa.append(&handle.world._inactive_entities, freed_entity.id)
}


// ------------------------------------- !END ENTITY! ------------------------------------


// +-------------------------------------------------------------------------------------+
// |                                  !PROCESSING!                                       |
// +-------------------------------------------------------------------------------------+


// Does a processing tick on an Entity.
entity_tick :: proc(handle: Entity_Handle, delta_time: f32) {
    entity := get_entity(handle)

    switch type in entity.type {
    case Character:
        // player_tick(handle, delta_time)
    case Object:
    }
}


// Draws the given Entity.
entity_draw :: proc(handle: Entity_Handle) {
    entity := get_entity(handle)

    screen_position := world_to_screen(entity.position) + entity.offset
    rl.DrawTextureV(entity.animator.texture, screen_position, rl.WHITE)

    // Draw the ID of the Character.
    if _, ok := entity.type.(Character); ok {
        mouse_pos := window_to_screen(rl.GetMousePosition())
        character_box := rl.Rectangle{
            width = WORLD_UNITS,
            height = WORLD_UNITS,
            x = screen_position.x,
            y = screen_position.y,
        }
        if rl.CheckCollisionPointRec(mouse_pos, character_box) {
            text := fmt.ctprintf("%v", entity.id)
            rl.DrawText(text, i32(screen_position.x), i32(screen_position.y), 16, rl.WHITE)
        }
    }
}


// ----------------------------------- !END PROCESSING! ----------------------------------


// +-------------------------------------------------------------------------------------+
// |                                  !OPERATIONS!                                       |
// +-------------------------------------------------------------------------------------+


// Moves the Entity in the given direction. Distance sets how far the movement is.
// Stops once it reaches a Solid.
entity_move :: proc(handle: Entity_Handle, direction: Direction, distance: u32 = 1, loc := #caller_location) {
    entity := get_entity(handle, loc)

    final_point := entity.position
    for i in 1..=distance {
        point := entity.position + (directions[direction] * i32(i))
        if world_space_empty(handle.world, point) {
            final_point = point
        } else {
            break
        }
    }

    entity.position = final_point
    entity.position.x = clamp(entity.position.x, 0, i32(handle.world.world_size) - 1)
    entity.position.y = clamp(entity.position.y, 0, i32(handle.world.world_size) - 1)
}

// ----------------------------------- !END OPERATIONS! ----------------------------------
