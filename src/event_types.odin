package game
/*
# Overivew
Definitions for specific actions that can be taken by Entities.

# Creating a New Action
1. Create a struct to hold special information (if needed).
2. Add the struct to the Event_Type union.
3. Make a helper creation proc in this file.
*/


import sa "core:container/small_array"


// +-------------------------------------------------------------------------------------+
// |                                   !DEFINITIONS!                                     |
// +-------------------------------------------------------------------------------------+


// The different types of Event that can be executed.
Event_Type :: union {
    Event_Entity_Move,
    Event_Basic_Attack,
    Event_Lunge,
}


// ---------------------------------- !END DEFINITIONS! ----------------------------------


// +-------------------------------------------------------------------------------------+
// |                                    !ENTITY MOVE!                                    |
// +-------------------------------------------------------------------------------------+


// An Event type for moving an Entity.
Event_Entity_Move :: struct {
    direction: Direction, // The direction to move.
    distance: u32,        // The amount of spaces to try and move.
    time: f32,            // The time it takes to move.
}


// Creates an Event_Entity_Move Event.
event_entity_move :: proc(owner: Entity_Handle, direction: Direction, t: f32 = 0.25) -> Event {
    event := create_event(owner)
    event.type = Event_Entity_Move{
        direction = direction,
        distance = 1,
        time = t,
    }

    // on_tick -->
    event.on_tick = proc(e: ^Event, delta_time: f32) {
        move_action := e.type.(Event_Entity_Move)
        entity := get_entity(e.owner)
        move_direction := directions[move_action.direction] * i32(move_action.distance)

        // TODO: Will still play animation if tries to run into wall.
        if !world_space_empty(e.owner.world, entity.position + move_direction) {
            stop_event(e)
            return
        }

        t := e.duration / move_action.time
        target_pos := world_to_screen(move_direction)
        new_pos := lerp(Vector2{ 0, 0 },
                        target_pos,
                        t)

        entity.offset = new_pos
        if e.duration >= move_action.time {
            stop_event(e)
            entity.offset = { 0, 0 }
            entity_move(e.owner, move_action.direction, move_action.distance)
        }
    } // <-- on_tick 

    return event
}


// ---------------------------------- !END ENTITY MOVE! ----------------------------------


// +-------------------------------------------------------------------------------------+
// |                                   !BASIC ATTACK!                                    |
// +-------------------------------------------------------------------------------------+


// An Event type for an Entity doing an attack.
Event_Basic_Attack :: struct {
    direction: Direction,
    damage: i32,
}


// Creates an Event_Basic_Attack Event.
event_basic_attack :: proc(owner: Entity_Handle, direction: Direction, damage: i32) -> Event {
    event := create_event(owner)
    event.type = Event_Basic_Attack{
        direction = direction,
        damage = damage,
    }

    // on_tick -->
    event.on_tick = proc(e: ^Event, delta_time: f32) {
        attack_action := e.type.(Event_Basic_Attack)
        entity := get_entity(e.owner)
        attack_direction := directions[attack_action.direction]

        for entity_id in sa.slice(&e.owner.world._active_entities) {
            handle := new_entity_handle(e.owner.world, entity_id)
            target := get_entity(handle)

            if target.position == entity.position + attack_direction {
                damage_character(handle, attack_action.damage)
            }
        }

        // TODO: Play particles? Make that another Event?

        stop_event(e)
    } // <-- on_tick 

    return event
}


// --------------------------------- !END BASIC ATTACK! ----------------------------------


// +-------------------------------------------------------------------------------------+
// |                                       !LUNGE!                                       |
// +-------------------------------------------------------------------------------------+


// An Event that plays a simple animation consisting of the Entity
// lunging in a direction and returning to its starting position.
Event_Lunge :: struct {
    direction: Direction,
    distance: f32,
    time: f32,
}


// Creates an Event_Lunge Event.
event_lunge :: proc(owner: Entity_Handle, direction: Direction, distance: f32, t: f32 = 0.25) -> Event {
    event := create_event(owner)
    event.type = Event_Lunge{
        direction = direction,
        distance = distance,
        time = t,
    }

    // on_tick -->
    event.on_tick = proc(e: ^Event, delta_time: f32) {
        lunge_action := e.type.(Event_Lunge)

        entity := get_entity(e.owner)
        attack_direction := directions[lunge_action.direction]

        half_time := lunge_action.time / 2.0
        start_pos := Vector2{ 0, 0 }
        end_pos := world_to_screen(attack_direction) * lunge_action.distance

        if e.duration < half_time {
            t := e.duration / half_time
            entity.offset = lerp(start_pos, end_pos, t)
        } else {
            t := (e.duration - half_time) / half_time
            entity.offset = lerp(end_pos, start_pos, t)
        }

        if e.duration >= lunge_action.time {
            stop_event(e)
        }
    } // <-- on_tick 

    return event
}


// ------------------------------------- !END LUNGE! -------------------------------------


// +-------------------------------------------------------------------------------------+
// |                                    !PARTICLE!                                       |
// +-------------------------------------------------------------------------------------+


Event_Particle :: struct {
    lifetime: f32,
    loop: bool, // Should this Particle loop?
    cycle_length: f32, // The amount of time a single cycle of the loop takes.
    framerate: f32,
    texture: Texture_Atlas,
}


event_particle :: proc(owner: Entity_Handle, atlas: Texture_Atlas, t: f32 = 1.0, loop := false, fps: f32 = 60) {

}


// ----------------------------------- !END PARTICLE! ------------------------------------
