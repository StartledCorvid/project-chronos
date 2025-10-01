package game

import "core:log"
import "core:math/rand"
import rl "vendor:raylib"


/*
# Overivew
An Event is something that can be done in a Timeline. They are events in a sequence.

# Creating a New Action
1. Create a struct to hold special information (if needed).
2. Add the struct to the Event_Type union.
3. Make a helper creation proc in this file.
*/


// +-------------------------------------------------------------------------------------+
// |                                   !DEFINITIONS!                                     |
// +-------------------------------------------------------------------------------------+


// Specialized data structures for each type of Event that can be executed.
Event_Type :: union #no_nil {
    Event_Branch,
    Event_Wait_For_Timeline,
    Event_Wait,
    Event_Deal_Damage,
    Event_Entity_Move,
    Event_Translate_Offset,
    Event_Offset_Travel,
    Event_Shake,
    Event_Destroy_Entity,
    Event_Create_Particle,
    Event_Play_Sound,
}


// Flags for the state of an Event.
Event_Flag :: enum {
    Finished, // The Event has played out and is finished.
}


// Interface for an event that can occur within a Timeline.
Event :: struct {
    // State flags for the Event.
    _flags: bit_set[Event_Flag],

    // If set, the execution of this Event will be tied to the existence of the given
    // Entity. If the Entity is no longer valid, it will be skipped. If left nil,
    // will always be executed.
    owner: Maybe(Entity_Handle),

    // See definition of Event_Type for more information.
    type: Event_Type,

    // Interfaced procedure for the Event. Will be called every tick that this is
    // the current Event in the Timeline. Parameters are the Timeline executing it,
    // a pointer to the Event, and the delta_time of the frame.
    on_tick: proc(^Timeline, ^Event, f32),
}


// ---------------------------------- !END DEFINITIONS! ----------------------------------


// +-------------------------------------------------------------------------------------+
// |                                       !BRANCH!                                      |
// +-------------------------------------------------------------------------------------+


// An Event that creates sub-Timelines, executing each one parallel to each other.
// Finishes once every Timeline is finished.
Event_Branch :: struct {
    timelines: [dynamic]Timeline,
}


// Creates an Event_Branch instance. `branches` is how many parallel branches to make.
// `owner` is the optional owner of this Event.
event_branch :: proc(branches: int, owner: Maybe(Entity_Handle) = nil) -> Event {
    return Event{
        owner = owner,
        type = Event_Branch{
            timelines = make([dynamic]Timeline, branches),
        },

        on_tick = proc(_: ^Timeline, e: ^Event, delta_time: f32) {
            data := &e.type.(Event_Branch)

            still_running := false
            for &timeline in data.timelines {
                if timeline_running(timeline) {
                    still_running = true
                    tick_timeline(&timeline, delta_time)
                }
            }

            if !still_running {
                delete(data.timelines)
                event_finish(e)
            }
        }, // <-- on_tick
    }
}


// ------------------------------------- !END BRANCH! ------------------------------------


// +-------------------------------------------------------------------------------------+
// |                                 !WAIT FOR TIMELINE!                                 |
// +-------------------------------------------------------------------------------------+


// An Event that stalls until another Timeline finishes.
Event_Wait_For_Timeline :: struct {
    timeline: ^Timeline,
}


// Creates an Event_Wait_For_Timeline instance. `timeline` is a pointer to the Timeline to
// wait for.
event_wait_for_timeline :: proc(timeline: ^Timeline, owner: Maybe(Entity_Handle) = nil, loc := #caller_location) -> Event {
    assert(timeline != nil, "Nil Timeline pointer.", loc)

    return Event{
        owner = owner,
        type = Event_Wait_For_Timeline{
            timeline = timeline,
        },

        on_tick = proc(parent_timeline: ^Timeline, e: ^Event, _: f32) {
            data := e.type.(Event_Wait_For_Timeline)
            assert(parent_timeline != data.timeline, "Cannot wait for own Timeline to finish.")

            if !timeline_running(data.timeline^) {
                event_finish(e)
            }
        }, // <-- on_tick
    }
}


// ------------------------------- !END WAIT FOR TIMELINE! -------------------------------


// +-------------------------------------------------------------------------------------+
// |                                       !WAIT!                                        |
// +-------------------------------------------------------------------------------------+


// An Event that stalls for a given duration.
Event_Wait :: struct {
    wait_time: f32,

    _passed_time: f32,
}


// Creates an Event_Wait instance. `wait_time` is the amount of time (in seconds) to wait.
event_wait :: proc(wait_time: f32, owner: Maybe(Entity_Handle) = nil) -> Event {
    return Event{
        owner = owner,
        type = Event_Wait{
            wait_time = wait_time,
        },

        on_tick = proc(parent_timeline: ^Timeline, e: ^Event, delta_time: f32) {
            data := &e.type.(Event_Wait)
            data._passed_time += delta_time

            if data._passed_time >= data.wait_time {
                event_finish(e)
            }
        }, // <-- on_tick
    }
}


// ------------------------------------- !END WAIT! --------------------------------------


// +-------------------------------------------------------------------------------------+
// |                                    !DEAL DAMAGE!                                    |
// +-------------------------------------------------------------------------------------+


// An Event that deals damage to a target.
Event_Deal_Damage :: struct {
    damage: int,
    attacker: Maybe(Entity_Handle),
    target: Entity_Handle,
}


// Creates an Event_Deal_Damage instance. `damage` is the amount of damage to deal.
// `attacker` is an optional Entity_Handle that points to the Entity that is dealing the
// damage. `target` is the Entity to deal the damage to.
event_deal_damage :: proc(damage: int, attacker: Maybe(Entity_Handle), target: Entity_Handle, owner: Maybe(Entity_Handle) = nil) -> Event {
    return {
        owner = owner,
        type = Event_Deal_Damage{
            damage   = damage,
            attacker = attacker,
            target   = target,
        },

        on_tick = proc(_: ^Timeline, e: ^Event, _: f32) {
            data := e.type.(Event_Deal_Damage)
            if entity_handle_valid(data.target) {
                damage_character(data.attacker, data.target, data.damage)
            }
            event_finish(e)
        }, // <-- on_tick
    }
}


// ---------------------------------- !END DEAL DAMAGE! ----------------------------------


// +-------------------------------------------------------------------------------------+
// |                                    !ENTITY MOVE!                                    |
// +-------------------------------------------------------------------------------------+


// An Event that moves an Entity.
Event_Entity_Move :: struct {
    entity: Entity_Handle, // The Entity to move.
    direction: Direction,  // The direction to move.
    duration: f32,         // The time it takes to move.

    _time_passed: f32,
}


// Creates an Event_Entity_Move instance. `entity` is the Entity to move. `direction` is
// the Direction to move in. `duration` is the amount of time that it should take to
// complete the move.
event_entity_move :: proc(entity: Entity_Handle, direction: Direction, duration: f32, owner: Maybe(Entity_Handle) = nil) -> Event {
    return {
        owner = owner,
        type = Event_Entity_Move{
            entity    = entity,
            direction = direction,
            duration  = duration,
        },

        on_tick = proc(_: ^Timeline, e: ^Event, delta_time: f32) {
            data := &e.type.(Event_Entity_Move)

            entity, entity_valid := get_entity(data.entity)
            if !entity_valid {
                event_finish(e)
                return
            }

            move_direction := DIRECTIONS[data.direction]

            data._time_passed += delta_time
            t := data._time_passed / data.duration

            target_pos := grid_to_world_point(move_direction)
            new_pos := lerp(Vector2{ 0, 0 }, to_vector2(target_pos), t)
            entity.offset = new_pos

            if data._time_passed >= data.duration {
                entity_move(entity, data.direction, 1)
                entity.offset = { 0, 0 }
                event_finish(e)
            }
        }, // <-- on_tick
    }
}


// ---------------------------------- !END ENTITY MOVE! ----------------------------------


// +-------------------------------------------------------------------------------------+
// |                                   !TRANSLATE OFFSET!                                |
// +-------------------------------------------------------------------------------------+


// An Event that adds to the Entity's offset position.
Event_Translate_Offset :: struct {
    entity: Entity_Handle,
    translation: Vector2,
    duration: f32,

    _time_passed: f32,
    _start_offset: Vector2,
}


// Creates an Event_Translate_Offset instance. `entity_handle` is the Entity to apply the offset
// translation to. `translation` is the translation to apply. `duration` is the amount of
// time it takes to apply the translation.
event_translate_offset :: proc(entity_handle: Entity_Handle, translation: Vector2, duration: f32, owner: Maybe(Entity_Handle) = nil) -> Event {
    assert(entity_handle_valid(entity_handle), "Invalid Entity_Handle.")
    entity := get_entity(entity_handle)

    return {
        owner = owner,
        type = Event_Translate_Offset{
            entity      = entity_handle,
            translation = translation,
            duration    = duration,

            _start_offset = entity.offset,
        },

        on_tick = proc(_: ^Timeline, e: ^Event, delta_time: f32) {
            data := &e.type.(Event_Translate_Offset)

            entity, entity_valid := get_entity(data.entity)
            if !entity_valid {
                event_finish(e)
                return
            }

            data._time_passed += delta_time
            t := data._time_passed / data.duration

            target_pos := data._start_offset + data.translation
            new_pos := lerp(data._start_offset, target_pos, t)
            entity.offset = new_pos

            if data._time_passed >= data.duration {
                entity.offset = data._start_offset + data.translation
                event_finish(e)
            }
        }, // <-- on_tick
    }
}


// -------------------------------- !END TRANSLATE OFFSET! -------------------------------


// +-------------------------------------------------------------------------------------+
// |                                     !OFFSET TRAVEL!                                 |
// +-------------------------------------------------------------------------------------+


// An Event that moves an Entity from one offset to another in the given time.
Event_Offset_Travel :: struct {
    entity: Entity_Handle,
    start_pos: Maybe(Vector2),
    end_pos: Vector2,
    duration: f32,

    _time_passed: f32,
}


// Creates an Event_Offset_Travel instance. `entity_handle` is the Entity to apply the offset
// to. `start_pos` is the optional position to start at. If nil, will travel from the offset
// it is already at. `end_pos` is the offset to end on. `duration` is the amount of time the
// travel takes.
event_offset_travel :: proc(entity_handle: Entity_Handle, start_pos: Maybe(Vector2), end_pos: Vector2, duration: f32, owner: Maybe(Entity_Handle) = nil) -> Event {
    return {
        owner = owner,
        type = Event_Offset_Travel{
            entity    = entity_handle,
            start_pos = start_pos,
            end_pos   = end_pos,
            duration  = duration,
        },

        on_tick = proc(_: ^Timeline, e: ^Event, delta_time: f32) {
            data := &e.type.(Event_Offset_Travel)

            entity, entity_valid := get_entity(data.entity)
            if !entity_valid {
                event_finish(e)
                return
            }

            if data.start_pos == nil {
                data.start_pos = entity.offset
            }

            data._time_passed += delta_time
            t := data._time_passed / data.duration

            new_pos := lerp(data.start_pos.?, data.end_pos, t)
            entity.offset = new_pos

            if data._time_passed >= data.duration {
                log.debugf("end_pos: %v", data.end_pos)
                entity.offset = data.end_pos
                event_finish(e)
            }
        }, // <-- on_tick
    }
}


// Creates an Event_Offset_Travel instance. This resets the Entity's offset to 0.
// `entity_handle` is a Entity_Handle that points to the Entity to reset the offset on.
// `duration` is the amount of time the movement back to (0, 0) takes.
event_reset_offset :: proc(entity_handle: Entity_Handle, duration: f32, owner: Maybe(Entity_Handle) = nil) -> Event {
    return event_offset_travel(entity_handle, nil, { 0, 0 }, duration, owner)
}


// --------------------------------- !END OFFSET TRAVEL! ---------------------------------


// +-------------------------------------------------------------------------------------+
// |                                       !SHAKE!                                       |
// +-------------------------------------------------------------------------------------+


// An Event that plays a simple animation consisting of the Entity shaking around.
Event_Shake :: struct {
    entity: Entity_Handle,
    intensity: f32,
    duration: f32,

    _time_passed: f32,
    _start_offset: Vector2,
}


// Creates an Event_Shake instance. `entity_handle` is a Entity_Handle that points to the
// Entity to shake. `intensity` is the farthest possible distance that a shake can go.
// `duration` is the amount of time the shake lasts.
event_shake :: proc(entity_handle: Entity_Handle, intensity: f32, duration: f32, owner: Maybe(Entity_Handle) = nil) -> Event {
    assert(entity_handle_valid(entity_handle), "Invalid Entity_Handle.")
    entity := get_entity(entity_handle)

    return {
        owner = owner,
        type = Event_Shake{
            entity    = entity_handle,
            intensity = intensity,
            duration  = duration,

            _start_offset = entity.offset,
        },

        on_tick = proc(_: ^Timeline, e: ^Event, delta_time: f32) {
            data := &e.type.(Event_Shake)

            entity, entity_valid := get_entity(data.entity)
            if !entity_valid {
                event_finish(e)
                return
            }

            data._time_passed += delta_time

            entity.offset = {
                rand.float32() * data.intensity,
                rand.float32() * data.intensity,
            }

            if data._time_passed >= data.duration {
                entity.offset = data._start_offset
                event_finish(e)
            }
        }, // <-- on_tick
    }
}


// ------------------------------------- !END SHAKE! -------------------------------------


// +-------------------------------------------------------------------------------------+
// |                                  !DESTROY ENTITY!                                   |
// +-------------------------------------------------------------------------------------+


// An Event that destroys a given Entity.
Event_Destroy_Entity :: struct {
    entity: Entity_Handle,
}


// Creates an Event_Destroy_Entity instance. `entity_handle` is a Entity_Handle that points
// to the Entity to destroy.
event_destroy_entity :: proc(entity_handle: Entity_Handle, owner: Maybe(Entity_Handle) = nil) -> Event {
    return {
        owner = owner,
        type = Event_Destroy_Entity{
            entity = entity_handle,
        },

        on_tick = proc(_: ^Timeline, e: ^Event, _: f32) {
            data := e.type.(Event_Destroy_Entity)
            if entity_handle_valid(data.entity) {
                free_entity(data.entity)
            }
            event_finish(e)
        }, // <-- on_tick
    }
}


// -------------------------------- !END DESTROY ENTITY! ---------------------------------


// +-------------------------------------------------------------------------------------+
// |                                  !CREATE PARTICLE!                                  |
// +-------------------------------------------------------------------------------------+


// An Event that creates a Particle.
Event_Create_Particle :: struct {
    particle: Particle_Name,
    location: World_Coords,

    // Should the timeline wait for the particle to finish before continuing to
    // the next event?
    wait_for_finish: bool,

    _created_particle: Maybe(Entity_Handle),
}


// Creates an Event_Create_Particle instance. `particle` is the Particle_Name of the particle
// to create. `location` is the World_Coords to create the Particle at. `wait_for_finish`
// is optional and determines if the Timeline is paused until the Particle is done playing.
event_create_particle :: proc(particle: Particle_Name, location: World_Coords, wait_for_finish: bool = false, owner: Maybe(Entity_Handle) = nil) -> Event {
    return {
        owner = owner,
        type = Event_Create_Particle{
            particle        = particle,
            location        = location,
            wait_for_finish = wait_for_finish,
        },

        on_tick = proc(_: ^Timeline, e: ^Event, _: f32) {
            data := &e.type.(Event_Create_Particle)

            if data._created_particle == nil {
                data._created_particle = new_particle(data.location, data.particle)
            }

            if !entity_handle_valid(data._created_particle.?) || !data.wait_for_finish {
                event_finish(e)
            }
        }, // <-- on_tick
    }
}


// -------------------------------- !END CREATE PARTICLE! --------------------------------


// +-------------------------------------------------------------------------------------+
// |                                     !PLAY SOUND!                                    |
// +-------------------------------------------------------------------------------------+


// An Event that plays a sound.
Event_Play_Sound :: struct {
    sound: Sound_Name,
    wait_for_finish: bool,
    // TODO: Pitch, volume, etc.

    _playing: bool,
}


// Creates an Event_Play_Sound instance. `sound` is the Sound_Name of the sound to play.
// `wait_for_end` determines if the Timeline should wait for the sound to finish before
// moving on.
event_play_sound :: proc(sound: Sound_Name, wait_for_end: bool = false, owner: Maybe(Entity_Handle) = nil) -> Event {
    return {
        owner = owner,
        type = Event_Play_Sound{
            sound = sound,
        },

        on_tick = proc(_: ^Timeline, e: ^Event, _: f32) {
            data := &e.type.(Event_Play_Sound)
            sound := game.sounds[data.sound]

            if !data._playing {
                rl.PlaySound(sound)
                data._playing = true
            }

            if (data.wait_for_finish && !rl.IsSoundPlaying(sound)) || !data.wait_for_finish {
                event_finish(e)
            }
        }, // <-- on_tick
    }
}


// ----------------------------------- !END PLAY SOUND! ----------------------------------