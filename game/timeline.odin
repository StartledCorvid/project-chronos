package game


/*
# Overiew
A Timeline is a sequence of Events that take place in order, waiting for one to finish
before moving on to the next one in the sequence.

# Creating a New Event Type
See event_types.odin to see how to create new Event types.
*/


// +-------------------------------------------------------------------------------------+
// |                                      !TYPES!                                        |
// +-------------------------------------------------------------------------------------+


// A sequence of Events. Executes the current Event before moving on to the next one.
Timeline :: struct {
    // The index of the Event that is currently being excuted.
    current_event: int,

    // The sequence of Events to execute.
    sequence: [dynamic]Event, 
}


// ------------------------------------- !END TYPES! -------------------------------------


// +-------------------------------------------------------------------------------------+
// |                                    !TIMELINE!                                       |
// +-------------------------------------------------------------------------------------+


// Returns true if the given Timeline is still running, or
// false if it is not.
timeline_running :: proc(timeline: Timeline) -> bool {
    return len(timeline.sequence) > 0
}


// Gets a pointer to the current Event in the given Timeline, or nil if there
// is not one present.
timeline_current_event :: proc(timeline: ^Timeline, loc := #caller_location) -> ^Event {
    assert(timeline != nil, "Nil Timeline pointer.", loc)

    sequence_length := len(timeline.sequence)

    if sequence_length <= 0 || timeline.current_event >= sequence_length {
        return nil
    }
    return &timeline.sequence[timeline.current_event]
}


// Updates the Timeline forward a frame, if it has an Event queued up.
tick_timeline :: proc(timeline: ^Timeline, delta_time: f32) {
    // If the Timeline is not running, skip.
    if !timeline_running(timeline^) {
        return
    }

    // If there is no current event in the Timeline, skip.
    current_event := timeline_current_event(timeline)
    if current_event == nil {
        return
    }

    // Check if the owner Entity of the Event is still valid.
    if current_event.owner != nil && !entity_handle_valid(current_event.owner.?) {
        event_finish(current_event)
    }

    // Check if the current Event is finished.
    if .Finished in current_event._flags {
        timeline.current_event += 1

        // Reached the end of the timeline.
        if timeline.current_event >= len(timeline.sequence) {
            timeline_reset(timeline)
        }

        return
    }

    // Call on_tick for the current Event.
    assert(current_event.on_tick != nil, "Nil `on_tick` procedure in Event.")
    current_event.on_tick(timeline, current_event, delta_time)
}


// Resets the Event sequence on the given Timeline.
timeline_reset :: proc(timeline: ^Timeline, loc := #caller_location) {
    assert(timeline != nil, "Nil Timeline pointer.", loc)

    timeline.current_event = 0
    clear(&timeline.sequence)
}


// Adds the given Event to the end of the Timeline.
timeline_add :: proc(timeline: ^Timeline, event: Event, loc := #caller_location) {
    assert(timeline != nil, "Nil Timeline pointer.", loc)
    append(&timeline.sequence, event)
}


// Adds the given Event to the Timeline, inserting it right after the
// current one. If there are no Events in the Timeline, inserts it at the
// beginning.
timeline_add_next :: proc(timeline: ^Timeline, event: Event, loc := #caller_location) {
    assert(timeline != nil, "Nil Timeline pointer.", loc)

    // If no current Event, just add one.
    if len(timeline.sequence) <= 0 {
        append(&timeline.sequence, event)
    } else {
       inject_at(&timeline.sequence, 1, event) 
    }
}


// Tells the given Event to stop playing.
event_finish :: proc(event: ^Event, loc := #caller_location) {
    assert(event != nil, "Nil Event pointer.", loc)
    event._flags += { .Finished }
}


// ----------------------------------- !END TIMELINE! ------------------------------------
