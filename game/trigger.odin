package game

import "core:log"

/*
# Overview
Interface of a trigger for abilities and attacks. Actions are in charge of
triggering these on their caster and enemies. Use the procs to create specific implementations
of the interface.

# Adding a New Trigger
1. Add an entry to the Trigger enum.
*/

Trigger :: enum {
    On_Hit,      // The catalyst has hit the target.   
    When_Hit,    // The target has been hit by the catalyst.
    On_Kill,     // The target has been killed by the catalyst.
    When_Healed, // The target has been healed by the catalyst.
}

Trigger_Type :: union #no_nil {
    Trigger_On_Hit,
    Trigger_When_Hit,
    Trigger_On_Kill,
    Trigger_When_Healed,
}


// The catalyst has hit the target.
Trigger_On_Hit :: struct {

}


// The target has been hit by the catalyst.
Trigger_When_Hit :: struct {

}


// The target has been killed by the catalyst.
Trigger_On_Kill :: struct {

}


// The target has been healed by the catalyst.
Trigger_When_Healed :: struct {

}


// Middle point for trigger logic. Used to direct Trigger_Sources to Trigger_Watchers.
Trigger_Hub :: struct {
    next_id: int,
    watchers: [Trigger][dynamic]Trigger_Watcher,
} 


// Watches a type of Trigger_Reason on a specific Trigger_Hub. When that reason is
// called, activates the Trigger.
Trigger_Watcher :: struct {
    source: Item_Name,
    trigger: Trigger,
    on_trigger: proc(self_name: Item_Name, payload: Trigger_Payload),

    _id: int,
}


Trigger_Source :: struct {
    trigger: Trigger,
    on_trigger: proc(self_name: Item_Name, payload: Trigger_Payload),
}


// Used to activate a Trigger. Fill out the information and then pass to `trigger_activate`
// to activate a Trigger.
Trigger_Payload :: struct {
    trigger: Trigger,
    target: Entity_Handle,
    catalyst: Entity_Handle,
    timeline: ^Timeline,

    data: Trigger_Payload_Data,
}


// Activates a Trigger on the given Trigger_Hub.
trigger :: proc(hub: ^Trigger_Hub, payload: Trigger_Payload, loc := #caller_location) {
    assert(hub != nil, "Nil Trigger_Hub pointer.", loc)

    for watcher in hub.watchers[payload.trigger] {
        assert(watcher.on_trigger != nil, "Empty interface found on Trigger_Watcher.", loc)
        watcher.on_trigger(watcher.source, payload)
    }
}


// Registers a Trigger_Watcher on a Trigger_Hub using a Trigger_Source.
// The Trigger_Watcher will be set up to watch for the given Trigger.
// Returns the ID of the Trigger_Watcher.
register_watcher :: proc(hub: ^Trigger_Hub, source: Trigger_Source, item_source: Item_Name, loc := #caller_location) -> int {
    assert(hub != nil, "Nil Trigger_Hub pointer.", loc)
    assert(source.on_trigger != nil, "Nil on_trigger proc.", loc)

    new_watcher := Trigger_Watcher{
        source = item_source,
        trigger = source.trigger,
        on_trigger = source.on_trigger,

        _id = hub.next_id,
    }

    assert(hub.next_id < max(int), "Exceeded max Trigger_Watcher ids. How.", loc)
    hub.next_id += 1

    append(&hub.watchers[source.trigger], new_watcher)
    return new_watcher._id
}


// Removes a Trigger_Watcher from a Trigger_Hub.
unregister_watcher :: proc{
    unregister_watcher_id,
    unregister_watcher_object,
    unregister_watcher_source,
}


// Removes a Trigger_Watcher of the given type and ID from a Trigger_Hub.
unregister_watcher_id :: proc(hub: ^Trigger_Hub, trigger: Trigger, id: int, loc := #caller_location) {
    assert(hub != nil, "Nil Trigger_Hub pointer.", loc)

    for watcher, index in hub.watchers[trigger] {
        if watcher._id == id {
            unordered_remove(&hub.watchers[trigger], index)
            return
        }
    }

    panic("Trying to remove a Trigger_Watcher using an ID that was not found.", loc)
}


// Removes the given Trigger_Watcher from the Trigger_Hub.
unregister_watcher_object :: proc(hub: ^Trigger_Hub, watcher: Trigger_Watcher, loc := #caller_location) {
    assert(hub != nil, "Nil Trigger_Hub pointer.", loc)
    unregister_watcher_id(hub, watcher.trigger, watcher._id, loc)
}


// Removes the given Trigger_Watcher from the Trigger_Hub.
unregister_watcher_source :: proc(hub: ^Trigger_Hub, source: Trigger_Source, loc := #caller_location) {
    assert(hub != nil, "Nil Trigger_Hub pointer.", loc)

    for watcher in hub.watchers[source.trigger] {
        if compare_watcher_source(watcher, source) {
            unregister_watcher(hub, watcher, loc)
            return
        }
    }

    log.warnf("Couldn't find a Trigger_Watcher for Trigger_Source: %v", source)
}


compare_watcher_source :: proc(watcher: Trigger_Watcher, source: Trigger_Source) -> bool {
    return watcher.trigger == source.trigger && watcher.on_trigger == source.on_trigger
}