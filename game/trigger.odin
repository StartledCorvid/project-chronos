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


Trigger_Hub :: [Trigger_Type][dynamic]Trigger_Listener


Trigger_Type :: enum {
    On_Hit,
    When_Hit,
    On_Kill,
    When_Healed,
}

Trigger_Source :: struct {
    on_trigger: proc(self: Trigger_Listener, payload: Trigger_Payload),
    type: Trigger_Type,
}


Trigger_Listener :: struct {
    on_trigger: proc(self: Trigger_Listener, payload: Trigger_Payload),
    source: ^Item_Instance,
    type: Trigger_Type,
}


Trigger_Payload :: union {
    Trigger_On_Hit,
    Trigger_When_Hit,
    Trigger_On_Kill,
    Trigger_When_Healed,
}


// The attacker has hit the target.
Trigger_On_Hit :: struct {
    target: Entity_Handle,
    attacker: Entity_Handle,
    total_damage: int,
}


// The target was hit by the attacker.
Trigger_When_Hit :: struct {
    target: Entity_Handle,
    attacker: Entity_Handle,
    total_damage: int,
}


// The target was killed by attacker.
Trigger_On_Kill :: struct {
    target: Entity_Handle,
    attacker: Entity_Handle,
}


// The target has been healed by the catalyst.
Trigger_When_Healed :: struct {
    target: Entity_Handle,
    healer: Entity_Handle,
    heal_amount: int,
}


@(private)
payload_to_enum :: proc(payload: Trigger_Payload) -> Trigger_Type {
    switch data in payload {
    case Trigger_On_Hit:      return .On_Hit
    case Trigger_When_Hit:    return .When_Hit
    case Trigger_On_Kill:     return .On_Kill
    case Trigger_When_Healed: return .When_Healed
    }
    panicf("Couldn't find payload enum for: %v", payload)
    return .When_Hit
}


// Activates a Trigger on the given Trigger_Hub.
trigger :: proc(payload: Trigger_Payload, loc := #caller_location) {
    type := payload_to_enum(payload)

    for listener in game.triggers[type] {
        assert(listener.on_trigger != nil, "Empty interface found on Trigger_Watcher.", loc)
        listener.on_trigger(listener, payload)
    }
}


register_trigger :: proc(listener: Trigger_Listener, loc := #caller_location) {
    assert(len(game.triggers) < max(int), "Exceeded max Trigger_Watcher ids. How.", loc)
    append(&game.triggers[listener.type], listener)
}


unregister_trigger :: proc(listener: Trigger_Listener, loc := #caller_location) {
    for stored_listener, index in game.triggers[listener.type] {
        if equal_listeners(stored_listener, listener) {
            unordered_remove(&game.triggers[listener.type], index)
            return
        }
    }

    log.warnf("Trying to remove a Trigger_Listener that isn't registered: %v", listener)
}


@(private)
equal_listeners :: proc(a, b: Trigger_Listener) -> bool {
    return a.on_trigger == b.on_trigger &&
           a.source     == b.source     &&
           a.type       == b.type
}