package game


import "core:math/rand"
import sa "core:container/small_array"
import rl "vendor:raylib"


/*
# Overivew
Definitions for specific actions that can be taken by Entities.

# Creating a New Action
1. Create a struct to hold special information (if needed).
2. Add the struct to the Event_Type union.
3. Make a helper creation proc in this file.
*/


// +-------------------------------------------------------------------------------------+
// |                                   !DEFINITIONS!                                     |
// +-------------------------------------------------------------------------------------+


// The different types of Event that can be executed.
Event_Type :: union {
    Event_Deal_Damage,
    Event_Entity_Move,
    Event_Basic_Attack,
    Event_Lunge,
    Event_Shake,
    Event_Destroy_Entity,
    Event_Create_Particle,
    Event_Branch,
    Event_Play_Sound,
}


// ---------------------------------- !END DEFINITIONS! ----------------------------------


// +-------------------------------------------------------------------------------------+
// |                                    !DEAL DAMAGE!                                    |
// +-------------------------------------------------------------------------------------+


// An Event that deals damage to a target.
Event_Deal_Damage :: struct {
    damage: int,
    target: Entity_Handle,
}


// Creates an Event_Deal_damage Event.
event_deal_damage :: proc(owner: Entity_Handle, damage: int, target: Entity_Handle) -> Event {
    event := create_event(owner)
    event.type = Event_Deal_Damage{
        damage = damage,
        target = target,
    }

    // on_tick -->
    event.on_tick = proc(e: ^Event, delta_time: f32) {
        damage_event := e.type.(Event_Deal_Damage)
        damage_character(damage_event.target, i32(damage_event.damage))
        stop_event(e)
    } // <-- on_tick 

    return event
}


// ---------------------------------- !END DEAL DAMAGE! ----------------------------------


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
        move_direction := DIRECTIONS[move_action.direction] * i32(move_action.distance)

        if !world_space_empty(e.owner.world, entity.position + move_direction) {
            stop_event(e)
            return
        }

        t := e.duration / move_action.time
        target_pos := grid_to_world_point(move_direction)
        new_pos := lerp(Vector2{ 0, 0 },
                        to_vector2(target_pos),
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
        attack_direction := DIRECTIONS[attack_action.direction]

        for entity_id in sa.slice(&e.owner.world._active_entities) {
            handle := new_entity_handle(e.owner.world, entity_id)
            target := get_entity(handle)

            if target.position == entity.position + attack_direction {
                damage_character(handle, attack_action.damage)
            }
        }

        new_particle(entity.position + attack_direction, Particle_Name.Puff)

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
        attack_direction := DIRECTIONS[lunge_action.direction]

        half_time := lunge_action.time / 2.0
        start_pos := Vector2{ 0, 0 }
        end_pos := to_vector2(grid_to_world_point(attack_direction)) * lunge_action.distance

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
// |                                       !SHAKE!                                       |
// +-------------------------------------------------------------------------------------+


// An Event that plays a simple animation consisting of the Entity
// shaking around.
Event_Shake :: struct {
    intensity: f32, // The farthest the character can move.
    time: f32,      // The amount of time the shaking takes.
}


// Creates an Event_Lunge Event.
event_shake :: proc(owner: Entity_Handle, intensity: f32, t: f32 = 0.25) -> Event {
    event := create_event(owner)
    event.type = Event_Shake{
        intensity = intensity,
        time = t,
    }

    // on_tick -->
    event.on_tick = proc(e: ^Event, delta_time: f32) {
        event_shake := e.type.(Event_Shake)
        entity := get_entity(e.owner)
        
        entity.offset = {
            rand.float32() * event_shake.intensity,
            rand.float32() * event_shake.intensity,
        }

        if e.duration >= event_shake.time {
            entity.offset = { 0, 0 }
            stop_event(e)
        }
    } // <-- on_tick 

    return event
}


// ------------------------------------- !END SHAKE! -------------------------------------


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


// +-------------------------------------------------------------------------------------+
// |                                  !DESTROY ENTITY!                                   |
// +-------------------------------------------------------------------------------------+


// Data for destroying an Entity.
Event_Destroy_Entity :: struct {
    entity: Entity_Handle,
}


// Creates an event that calls for a specific Entity to be freed, if it is still valid.
event_destroy_entity :: proc(owner: Entity_Handle, entity_to_destroy: Entity_Handle) -> Event {
    event := create_event(owner)
    event.type = Event_Destroy_Entity{
        entity = entity_to_destroy,
    }

    // on_tick -->
    event.on_tick = proc(e: ^Event, delta_time: f32) {
        destroy_entity_event := e.type.(Event_Destroy_Entity)
        if entity_handle_valid(destroy_entity_event.entity) {
            free_entity(destroy_entity_event.entity)
        }
        stop_event(e)
    } // <-- on_tick 

    return event
}


// -------------------------------- !END DESTROY ENTITY! ---------------------------------


// +-------------------------------------------------------------------------------------+
// |                                  !CREATE PARTICLE!                                  |
// +-------------------------------------------------------------------------------------+


// Data for the particle to create.
Event_Create_Particle :: struct {
    particle: Particle_Name,
    location: World_Coords,
    // Should the timeline wait for the particle to finish before continuing to
    // the next event?
    wait_for_finish: bool,

    _created_particle: Entity_Handle,
}


// Creates an event that calls for a particle to be created.
event_create_particle :: proc(owner: Entity_Handle, particle: Particle_Name, location: World_Coords, wait_for_finish: bool = false) -> Event {
    event := create_event(owner)
    event.type = Event_Create_Particle{
        particle = particle,
        location = location,
        wait_for_finish = wait_for_finish,
    }

    event.on_start = proc(e: ^Event) {
        create_particle_event := e.type.(Event_Create_Particle)
        create_particle_event._created_particle = new_particle(create_particle_event.location, create_particle_event.particle)
    }

    // on_tick -->
    event.on_tick = proc(e: ^Event, delta_time: f32) {
        create_particle_event := e.type.(Event_Create_Particle)

        if !entity_handle_valid(create_particle_event._created_particle) || !create_particle_event.wait_for_finish {
            stop_event(e)
        }
    } // <-- on_tick 

    return event
}


// -------------------------------- !END CREATE PARTICLE! --------------------------------


// +-------------------------------------------------------------------------------------+
// |                                       !BRANCH!                                      |
// +-------------------------------------------------------------------------------------+


// Data for an event that waits for a few sub-timelines to finish.
Event_Branch :: struct {
    timelines: [dynamic]Timeline,
}


// Creates an event that calls for a particle to be created.
event_branch :: proc(owner: Entity_Handle, timeline_count: int) -> Event {
    event := create_event(owner)
    event.type = Event_Branch{
        timelines = make([dynamic]Timeline, timeline_count),
    }

    // on_tick -->
    event.on_tick = proc(e: ^Event, delta_time: f32) {
        data := e.type.(Event_Branch)

        still_running := false
        for &timeline in data.timelines {
            if len(timeline.events) > 0 {
                still_running = true
                tick_timeline(&timeline, delta_time)
            }
        }

        if !still_running {
            delete(data.timelines)
            stop_event(e)
        }
    } // <-- on_tick

    return event
}


// ------------------------------------- !END BRANCH! ------------------------------------


// +-------------------------------------------------------------------------------------+
// |                                     !PLAY SOUND!                                    |
// +-------------------------------------------------------------------------------------+


// Data for an event that triggers a sound to play.
Event_Play_Sound :: struct {
    sound: Sound_Name,
    // TODO: Pitch, volume, etc.
    // TODO: Wait for end bool.
}


// Creates an event that calls for a particle to be created.
event_play_sound :: proc(owner: Entity_Handle, sound: Sound_Name) -> Event {
    event := create_event(owner)
    event.type = Event_Play_Sound{
        sound = sound,
    }

    // on_tick -->
    event.on_tick = proc(e: ^Event, delta_time: f32) {
        data := e.type.(Event_Play_Sound)
        rl.PlaySound(game.sounds[data.sound])
        stop_event(e)
    } // <-- on_tick

    return event
}


// ----------------------------------- !END PLAY SOUND! ----------------------------------