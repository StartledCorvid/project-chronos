package game


/*
# Overview
Interface of a trigger for abilities and attacks. Actions are in charge of
triggering these on their caster and enemies. Use the procs to create specific implementations
of the interface.

# Adding a New Trigger Reason
1. Add an entry to the Trigger_Reason enum.
*/

Trigger_Reason :: enum {
    On_Hit,   // The Entity has hit something.
    When_Hit, // The Entity has been hit by something.
}


Trigger_Source :: int

Trigger_List :: map[Trigger_Source]Trigger
Triggers :: [Trigger_Reason]Trigger_List


// Interface for something that happens when a trigger is met.
Trigger :: struct {
    source: Trigger_Source,
    on_trigger: proc(payload: Trigger_Payload),
}

Trigger_Payload :: struct {
    target: Entity_Handle,
    catalyst: Entity_Handle,
    timeline: ^Timeline,
}


get_trigger :: proc(trigger_reason: Trigger_Reason, character: ^Character, loc := #caller_location) -> []Trigger {
    assert(character != nil, "Nil character pointer.", loc)

    return nil
}


// Triggers a slice of Triggers. The target is who the Trigger is attached to, and the
// catalyst is an optional parameter for the Entity that caused the trigger to be done.
// If left blank, will default to the target (if used). Timeline passes in a timeline
// to use. If it is left nil, then it will use the current fight's timeline by default.
do_trigger :: proc(triggers: []Trigger, payload: Trigger_Payload) {
    actual_payload := payload
    
    if actual_payload.timeline == nil {
        actual_payload.timeline = &game.current_fight.timeline
    }

    if !entity_handle_valid(actual_payload.catalyst) {
        actual_payload.catalyst = actual_payload.target
    }

    for trigger in triggers {
        trigger.on_trigger(actual_payload)
    }
}