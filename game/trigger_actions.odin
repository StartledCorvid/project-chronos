package game



/*
# Overview
Procedures for triggers.
*/


Trigger_Payload_Data :: union {
    int,   
}


// Heals the target when triggered.
triggered_when_healed :: proc(payload: Trigger_Payload, heal_amount: int) {
    if !entity_handle_valid(payload.target) {
        return
    }

    heal_character(payload.target, 1, payload.catalyst)
}