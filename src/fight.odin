package game
/*
# Overview
Handles the management of Fights, Rounds, and turns in the game.
*/

import "core:log"
import "core:slice"
import sa "core:container/small_array"


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

    log.debugf("Starting next turn for %v", get_entity(fight.current_character).id)
}


// Changes the current phase of the given Fight.
@(private="file")
fight_change_phase :: proc(fight: ^Fight, new_phase: Fight_Phase) {
    if fight.phase == new_phase do return
    fight.phase = new_phase
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
