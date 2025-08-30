package game
/*
# Overiew
Handling for Timelines and Event system.

# Creating a New Event Type
See event_types.odin to see how to create new Event types.
*/


// +-------------------------------------------------------------------------------------+
// |                                      !TYPES!                                        |
// +-------------------------------------------------------------------------------------+


// Keeps track of Events as they play out. Keeps a queue of them.
Timeline :: struct {
    current_event: ^Event,
    events: [dynamic]Event,
}


// Flags for configuring the state of an Event.
Event_Flag :: enum {
    Playing, // Is the Event currently playing out?
    Blocks, // Does the event block turn processing?
}


// An Event that can be added to the Timeline.
Event :: struct {
    owner: Entity_Handle,

    type: Event_Type,

    flags: bit_set[Event_Flag],
    duration: f32,

    on_start: proc(^Event),
    on_end: proc(^Event),
    on_tick: proc(^Event, f32),
}


// ------------------------------------- !END TYPES! -------------------------------------


// +-------------------------------------------------------------------------------------+
// |                                    !TIMELINE!                                       |
// +-------------------------------------------------------------------------------------+


timeline_blocked :: proc(timeline: Timeline) -> bool {
    return timeline.current_event != nil &&
           .Playing in timeline.current_event.flags &&
           .Blocks not_in timeline.current_event.flags
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


// ----------------------------------- !END TIMELINE! ------------------------------------
