package game
/*
# Overview
Handles the management of turns in the game.

# Creating a New Event Type
1. Create a struct to house the event data.
2. Add the new struct to the Action union.
*/


INVALID_EVENT :: Event{}

Phase :: enum {
    Waiting,
    Player_Turn,
    Enemy_Turn,
    Game_Over,
}


// Manages keeping track of turns.
Turn_Manager :: struct {
    current_phase: Phase,
    turn_time: f32,

    actions: [dynamic]Action,
}


// Runs a tick of the state machine.
state_machine :: proc(turn_manager: ^Turn_Manager) {
    switch turn_manager.current_phase{
    case .Player_Turn:
    case .Enemy_Turn:
    case .Waiting:
    case .Game_Over:
    }
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

    action: Action,

    flags: bit_set[Event_Flag],
    duration: f32,

    on_start: proc(^Event),
    on_end: proc(^Event),
    on_tick: proc(^Event, f32),
}


Action :: union {
    Action_Move,
}


Action_Move :: struct {
    direction: Direction,
    distance: u32,
    time: f32,
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
        event := pop_front(&timeline.events)
        if event.on_end != nil do event.on_end(&event)
        timeline.current_event = nil
    }
}


next_turn :: proc(turn_manager: ^Turn_Manager) {
    #partial switch turn_manager.current_phase {
    case .Player_Turn:
        turn_manager.current_phase = .Enemy_Turn
    case .Enemy_Turn:
        turn_manager.current_phase = .Player_Turn
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
    return event.action != nil && entity_handle_valid(event.owner)
}