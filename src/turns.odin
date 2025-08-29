package game
/*
# Overview
Handles the management of turns in the game.
*/


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
    owner: Combatant_Handle,

    flags: bit_set[Event_Flag],
    time: f32,

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
    current_event.time += delta_time
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

