package game

import "core:math/rand"
import "core:log"
// import "core:fmt"
import "core:slice"
import rl "vendor:raylib"
// import "core:math/rand"
import sa "core:container/small_array"


/*
# Overview
Handles the management of Fights, Rounds, and turns in the game.

# Adding a New Fight
1. Create a fight JSON file in the res/fights/ directory.
2. Run the gen program (or the gen.bat script).
*/


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


Fight_Info :: struct {
    rating: i32, // The difficulty rating of the fight.
    composition: []Character_Type, // The Character_Types of the enemies in the fight.
}


// ------------------------------------- !END TYPES! -------------------------------------


// +-------------------------------------------------------------------------------------+
// |                                        !FIGHT!                                      |
// +-------------------------------------------------------------------------------------+


// Creates a new Fight instance and intializes it.
new_fight :: proc(difficulty: i32, allocator := context.allocator, loc := #caller_location) -> ^Fight {
    fight := new(Fight, allocator, loc)

    characters := generate_fight(difficulty, allocator, loc)
    log.debugf("Generated fight: %v", characters)

    for character_type in characters {
        enemy := new_character(game.current_world, character_type)
        random_pos := random_world_point(game.current_world^)

        for !world_space_empty(game.current_world, random_pos) do random_pos = random_world_point(game.current_world^)
        get_entity(enemy).position = random_pos
    }

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
        free_fight(fight)
        game.state = .Lose_Screen
    case .Player_Win:
        game.won_games += 1
        game.state = .Win_Screen
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
        next_phase := get_next_phase(fight)

        if next_phase == .Turn {
            fight_next_turn(fight)
        }

        fight_change_phase(fight, next_phase)
    }
}


fight_has_enemy :: proc(fight: ^Fight) -> bool {
    for handle in fight.turn_order {
        if handle.id == game.player.id do continue
        if entity_handle_valid(handle) {
            return true
        }
    }

    return false
}


get_next_phase :: proc(fight: ^Fight) -> Fight_Phase {
    if !entity_handle_valid(game.player) {
        return .Player_Lose
    } else if !fight_has_enemy(fight) {
        return .Player_Win
    }

    return .Turn
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
    log.infof("Changed Fight phase to '%v'.", fight.phase)
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


// +-------------------------------------------------------------------------------------+
// |                                 !FIGHT GENERATION!                                  |
// +-------------------------------------------------------------------------------------+


// Populates the given Fight using the FIGHTS list. Supposed to match the
// difficulty as closely as possible.
generate_fight :: proc(difficulty: i32, allocator := context.allocator, loc := #caller_location) -> []Character_Type {
    potential_fights := get_closest_fights(difficulty)
    chosen_fight := rand.choice(potential_fights[:])

    return chosen_fight.composition
}


@(private="file")
get_closest_fights :: proc(difficulty: i32) -> []Fight_Info {
    lower_index := 0
    upper_index := len(FIGHTS) - 1
    middle_index := (upper_index + lower_index) / 2

    for upper_index != lower_index {
        if upper_index - 1 == lower_index {
            upper_difference := abs(difficulty - FIGHTS[upper_index].rating)
            lower_difference := abs(difficulty - FIGHTS[lower_index].rating)

            if upper_difference > lower_difference {
                middle_index = lower_index
            } else if lower_difference > upper_difference {
                middle_index = upper_index
            } else if upper_difference == lower_difference {
                middle_index = lower_index
            }

            break
        }

        fight := FIGHTS[middle_index]
        
        if difficulty > fight.rating {
            lower_index = middle_index
        } else if difficulty < fight.rating {
            upper_index = middle_index
        } else if difficulty == fight.rating {
            break
        }

        middle_index = (upper_index + lower_index) / 2
    }

    selected_rating := FIGHTS[middle_index].rating

    min_index := middle_index
    for (min_index - 1) > 0 && FIGHTS[min_index - 1].rating == selected_rating {
        min_index -= 1
    }

    max_index := middle_index
    length := len(FIGHTS)
    for max_index < length && FIGHTS[max_index].rating == selected_rating {
        max_index += 1
    }

    log.debugf("Total fights: %v", FIGHTS)
    log.debugf("When generating fight: {{ difficulty: %v, selected_rating: %v, min: %v, max: %v, middle_index: %v }}", difficulty, selected_rating, min_index, max_index, middle_index)

    return FIGHTS[min_index:max_index]
}


// ------------------------------- !END FIGHT GENERATION! --------------------------------



// +-------------------------------------------------------------------------------------+
// |                                          !UI!                                       |
// +-------------------------------------------------------------------------------------+


// Draws the timeline UI for the fight.
ui_fight_draw_turn_timeline :: proc(fight: Fight) {
    TIMELINE_WIDTH :: 100
    TIMELINE_HEIGHT :: 2
    TIMELINE_PADDING_Y :: 2
    TIMELINE_ENTRY_SPACING :: 2
    MID_SCREEN :: f32(RES_X) / 2.0

    start_pos := MID_SCREEN - (f32(TIMELINE_WIDTH) / 2.0)
    rl.DrawRectangleV({ start_pos, TIMELINE_PADDING_Y + (TIMELINE_HEIGHT / 2) }, { TIMELINE_WIDTH, TIMELINE_HEIGHT }, rl.BLACK)

    total_offset := f32(0)

    for handle, index in fight.turn_order {
        if index < fight.current_turn || !entity_handle_valid(handle) {
            continue
        }
        entity := get_entity(handle)
        character, ok := entity.type.(Character)
        if !ok {
            log.errorf("An Entity that is not a Character got included in the Timeline.")
            continue
        }

        icon_image := get_texture(character.base.icon)

        // TODO: Center timeline? Adjust the throughline timeline width (black line above).
        icon_pos := start_pos + total_offset

        rl.DrawTextureV(icon_image, { icon_pos, 0 }, rl.WHITE)

        total_offset += f32(icon_image.width) + TIMELINE_ENTRY_SPACING
    }
}


// --------------------------------------- !END UI! --------------------------------------
