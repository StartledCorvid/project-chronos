package game
/*
# Overview
Handles the management of turns in the game.

# Creating a New Event Type
1. Create a struct to house the event data.
2. Add the new struct to the Action union.
*/

import "core:log"
import sa "core:container/small_array"
import "core:slice"


// +-------------------------------------------------------------------------------------+
// |                                   !DEFINITIONS!                                     |
// +-------------------------------------------------------------------------------------+


// An Event that is not valid.
INVALID_EVENT :: Event{}


// ---------------------------------- !END DEFINITIONS! ----------------------------------


// +-------------------------------------------------------------------------------------+
// |                                      !TYPES!                                        |
// +-------------------------------------------------------------------------------------+


// The different phases of the game that can be active in teh state machine.
Fight_Phase :: enum {
    Starting,
    Turn,
    Processing,
    Player_Lose,
    Player_Win,
}


// Manages the current fight.
Fight :: struct {
    phase: Fight_Phase,
    timeline: Timeline,

    current_turn: int,
    current_character: Entity_Handle,
    turn_order: [dynamic]Entity_Handle,
}


// ------------------------------------- !END TYPES! -------------------------------------


// +-------------------------------------------------------------------------------------+
// |                                        !FIGHT!                                      |
// +-------------------------------------------------------------------------------------+


// Creates a new Fight instance and intializes it.
new_fight :: proc(allocator := context.allocator, loc := #caller_location) -> ^Fight {
    fight := new(Fight, allocator, loc)
    fight.phase = .Starting
    return fight
}


// Frees a Fight instance.
free_fight :: proc(fight: ^Fight, allocator := context.allocator, loc := #caller_location) {
    assert(fight != nil, "Invalid Fight pointer.", loc)

    delete(fight.turn_order, loc)
    free(fight, allocator, loc)
}


// Starts a new Round in the Fight.
new_round :: proc(fight: ^Fight, loc := #caller_location) {
    assert(game.current_world != nil, "No World loaded.", loc)

    world := game.current_world
    clear(&fight.turn_order)

    for entity_id in sa.slice(&world._active_entities) {
        entity := world.entities[entity_id]

        if _, ok := entity.type.(Character); ok {
            handle := new_entity_handle(world, entity_id)
            append(&fight.turn_order, handle)
        }
    }

    slice.sort_by(fight.turn_order[:], compare_character_speed)
    fight.current_turn = 0

    assert(len(fight.turn_order) > 0, "No Characters in Fight.", loc)

    fight.current_character = fight.turn_order[fight.current_turn]

    log.debug("Starting new round.")
}


// Calls for a processing tick of the Fight.
fight_tick :: proc(fight: ^Fight, delta_time: f32, loc := #caller_location) {
    assert(fight != nil, "Nil Fight pointer.", loc)

    switch fight.phase {
    case .Starting:
        // TODO: Begin fight animation, spawn Characters, etc.
        new_round(fight)
        fight_change_phase(fight, .Turn)
    case .Turn:
        turn_tick(fight)
    case .Processing:
        processing_tick(fight, delta_time)
    case .Player_Lose:
    case .Player_Win:
    }
}


// Asks the Character whose turn it currently is to decide what to do.
turn_tick :: proc(fight: ^Fight) {
    assert(len(fight.turn_order) > 0, "Trying processing a turn when no Characters active.")

    entity := get_entity(fight.current_character)
    character := &entity.type.(Character)

    assert(character.base.on_turn != nil, "Character has no behavior set.")
    if character.base.on_turn(entity, &fight.timeline) {
        fight_change_phase(fight, .Processing)
    }
}


// Does a processing tick, playing out the results of an turn choice.
processing_tick :: proc(fight: ^Fight, delta_time: f32) {
    timeline_tick(&fight.timeline, delta_time)
    if len(fight.timeline.events) <= 0 {
        fight_next_turn(fight)
        // TODO: Check if Player has won or lost.
        fight_change_phase(fight, .Turn)
    }
}


// Moves the Fight on to the next turn, starting a new Round if past the last turn.
fight_next_turn :: proc(fight: ^Fight) {
    fight.current_turn += 1
    if fight.current_turn >= len(fight.turn_order) {
        new_round(fight)
        return
    }
    fight.current_character = fight.turn_order[fight.current_turn]

    for !entity_handle_valid(fight.current_character) {
        if fight.current_turn >= len(fight.turn_order) {
            new_round(fight)
            return
        }

        fight.current_turn += 1
        fight.current_character = fight.turn_order[fight.current_turn]
    }

    log.debugf("Starting next turn for %v", get_entity(fight.current_character).type.(Character).base.display_name)
}


// Changes the current phase of the given Fight.
@(private="file")
fight_change_phase :: proc(fight: ^Fight, new_phase: Fight_Phase) {
    if fight.phase == new_phase do return
    fight.phase = new_phase
    log.debugf("Entering phase %v", fight.phase)
}


// Returns true if handle_a's Character speed is less than handle_b's Character speed.
@(private="file")
compare_character_speed :: proc(handle_a: Entity_Handle, handle_b: Entity_Handle) -> bool {
    entity_a := get_entity(handle_a)
    entity_b := get_entity(handle_b)

    character_a, a_ok := entity_a.type.(Character)
    character_b, b_ok := entity_b.type.(Character)

    assert(a_ok && b_ok, "One of the Entity_Handles points to an Entity that is not a Character.")

    return character_a.base.stats[.Speed] < character_b.base.stats[.Speed]
}


// ------------------------------------- !END FIGHT! -------------------------------------




// Manages keeping track of turns.
Turn_Manager :: struct {
    turn_time: f32,
    timeline: Timeline,
}


timeline_blocked :: proc(timeline: Timeline) -> bool {
    return timeline.current_event != nil &&
           .Playing in timeline.current_event.flags &&
           .Blocks not_in timeline.current_event.flags
}


init_turn_manager :: proc(turn_manager: ^Turn_Manager, loc := #caller_location) {
    assert(turn_manager != nil, "Nil Turn_Manager pointer.", loc)
}


Timeline :: struct {
    current_event: ^Event,
    events: [dynamic]Event,
}

Event_Flag :: enum {
    Playing, // Is the Event currently playing out?
    Blocks, // Does the event block turn processing?
}


Event :: struct {
    owner: Entity_Handle,

    type: Event_Type,

    flags: bit_set[Event_Flag],
    duration: f32,

    on_start: proc(^Event),
    on_end: proc(^Event),
    on_tick: proc(^Event, f32),
}


// Updates the Timeline forward a frame, if it has an Event queued up.
timeline_tick :: proc(timeline: ^Timeline, delta_time: f32) {
    if len(timeline.events) <= 0 {
        return
    }

    current_event := &timeline.events[0]

    // on_start
    if timeline.current_event == nil {
        timeline.current_event = current_event
        current_event.flags += { .Playing }

        if current_event.on_start != nil {
            current_event.on_start(current_event)
        }
    }

    // on_tick
    current_event.duration += delta_time
    if current_event.on_tick != nil {
        current_event.on_tick(current_event, delta_time)
    }

    // on_end
    if .Playing not_in current_event.flags {
        timeline.current_event = nil
        event := pop_front(&timeline.events)
        if event.on_end != nil do event.on_end(&event)
    }
}


// Creates a new event owned by the Entity passed. Adds the event to the given timeline.
create_event :: proc(owner: Entity_Handle, loc := #caller_location) -> Event {
    assert(entity_handle_valid(owner), "Invalid Entity_Handle.", loc)

    return {
        owner = owner,
    }
}


// Adds the given event to the Timeline.
add_event :: proc(timeline: ^Timeline, event: Event, loc := #caller_location) {
    assert(timeline != nil, "Nil Timeline pointer.", loc)
    append(&timeline.events, event)
}


// Checks if the given Event is a valid, executable Event.
valid_event :: proc(event: Event) -> bool {
    return entity_handle_valid(event.owner)
}


stop_event :: proc(event: ^Event, loc := #caller_location) {
    assert(event != nil, "Nil Event pointer.", loc)
    event.flags -= { .Playing }
}


event_end_turn :: proc(owner: Entity_Handle) -> Event {
    event := create_event(owner)
    event.type = nil
    event.flags += { .Blocks }

    // on_tick -->
    event.on_tick = proc(e: ^Event, _: f32) {
        if e.duration > 1.0 {
            // TODO: Some sort of transition.
            stop_event(e)
        }
    } // <-- on_tick


    // on_end -->
    event.on_end = proc(e: ^Event) {
        // next_turn(&game.turn_manager)
    } // <-- on_end

    return event
}