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
    // TODO: Use Handle (int) and clear array at end instead of
    //       multiple pops throughout.
    current_event: ^Event, 
    events: [dynamic]Event,

    sequences: [dynamic]Event_Sequence,
}


Event_Sequence :: [dynamic]Event


// Flags for configuring the state of an Event.
Event_Flag :: enum {
    Playing, // Is the Event currently playing out?
}


// An Event that can be added to the Timeline.
Event :: struct {
    owner: Entity_Handle,
    timeline: ^Timeline,

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


// Checks if the given Event is a valid, executable Event.
valid_event :: proc(event: Event) -> bool {
    return entity_handle_valid(event.owner)
}


// Creates a new event owned by the Entity passed. Adds the event to the given timeline.
create_event :: proc(owner: Entity_Handle, loc := #caller_location) -> Event {
    assert(entity_handle_valid(owner), "Invalid Entity_Handle.", loc)

    return {
        owner = owner,
    }
}


// Adds the given Event to the end Timeline.
add_event :: proc(timeline: ^Timeline, event: Event, loc := #caller_location) {
    assert(timeline != nil, "Nil Timeline pointer.", loc)
    mut_event := event
    mut_event.timeline = timeline
    append(&timeline.events, mut_event)
}


// Adds the given Event to the Timeline, inserting it right after the
// current one. If there are no Events in the Timeline, inserts it at the
// beginning.
event_add_next :: proc(timeline: ^Timeline, event: Event, loc := #caller_location) {
    assert(timeline != nil, "Nil Timeline pointer.", loc)
    
    mut_event := event
    mut_event.timeline = timeline

    // If no current Event, just add one.
    if len(timeline.events) <= 0 {
        append(&timeline.events, mut_event)
    } else {
       inject_at(&timeline.events, 1, mut_event) 
    }
}


// Tells the given Event to stop playing.
stop_event :: proc(event: ^Event, loc := #caller_location) {
    assert(event != nil, "Nil Event pointer.", loc)
    event.flags -= { .Playing }
}


// ----------------------------------- !END TIMELINE! ------------------------------------
