package game
/*
# Overivew
Definitions for specific actions that can be taken by Entities.

# Creating a New Action
1. Create a struct to hold special information (if needed).
2. Add the struct to the Event_Type union.
3. Make a helper creation proc in this file.
*/


// The different types of Event that can be executed.
Event_Type :: union {
    Event_Entity_Move,
}


// +-------------------------------------------------------------------------------------+
// |                                    !ENTITY MOVE!                                    |
// +-------------------------------------------------------------------------------------+


// An Event type for moving an Entity.
Event_Entity_Move :: struct {
    direction: Direction, // The direction to move.
    distance: u32, // The amount of spaces to try and move.
    time: f32, // The time it takes to move.
}


// Creates an Event_Entity_Move Event.
event_entity_move :: proc(owner: Entity_Handle, direction: Direction, t: f32 = 0.25) -> Event {
    event := create_event(owner)
    event.type = Event_Entity_Move{
        direction = direction,
        distance = 1,
        time = t,
    }
    event.flags += { .Blocks }

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