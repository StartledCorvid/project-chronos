package game

import "core:math/rand"
import "core:log"
import "core:slice"
import rl "vendor:raylib"
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


Fight_Level :: []Fight_Info


Fight_Info :: struct {
    arena_size: int,
    arena_tile: Texture_Name,
    composition: []Character_Type,
}


// ------------------------------------- !END TYPES! -------------------------------------


// +-------------------------------------------------------------------------------------+
// |                                        !FIGHT!                                      |
// +-------------------------------------------------------------------------------------+


init_fight :: proc(fight: ^Fight, fight_index: i32) {
    characters := generate_fight(fight_index)

    for character_type in characters {
        enemy := new_character(&game.current_world, character_type)
        random_pos := random_world_point(game.current_world)

        for !world_space_empty(&game.current_world, random_pos) do random_pos = random_world_point(game.current_world)
        get_entity(enemy).position = random_pos
    }

    fight.phase = .Starting
}


deinit_fight :: proc(fight: ^Fight) {
    fight.current_character = Entity_Handle{}
    fight.current_turn = 0
    fight.phase = .Starting

    clear(&fight.turn_order)
}


// Starts a new Round in the Fight.
new_round :: proc(fight: ^Fight, loc := #caller_location) {
    world := &game.current_world
    clear(&fight.turn_order)

    for entity_id in sa.slice(&world._active_entities) {
        entity := world.entities[entity_id]

        if is_character(&entity) {
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
tick_fight :: proc(fight: ^Fight, delta_time: f32, loc := #caller_location) {
    assert(fight != nil, "Nil Fight pointer.", loc)

    switch fight.phase {
    case .Starting:
        // TODO: Begin fight animation, spawn Characters, etc.
        new_round(fight)
        fight_change_phase(fight, .Turn)
    case .Turn:
        tick_fight_turn(fight)
    case .Processing:
        tick_fight_processing(fight, delta_time)
    case .Player_Lose:
        deinit_fight(fight)
        game_change_screen(Screen_Lose{})
    case .Player_Win:
        game.won_games += 1
        game_change_screen(Screen_Win{})
    }
}


// Asks the Character whose turn it currently is to decide what to do.
tick_fight_turn :: proc(fight: ^Fight) {
    assert(len(fight.turn_order) > 0, "Trying processing a turn when no Characters active.")

    entity := get_entity(fight.current_character)
    character := to_character(entity)

    assert(character.base.on_turn != nil, "Character has no behavior set.")
    if character.base.on_turn(entity, &fight.timeline) {
        fight_change_phase(fight, .Processing)
    }
}


// Does a processing tick, playing out the results of an turn choice.
tick_fight_processing :: proc(fight: ^Fight, delta_time: f32) {
    tick_timeline(&fight.timeline, delta_time)
    if len(fight.timeline.sequence) <= 0 {
        fight_next_turn(fight)
        fight_change_phase(fight, .Turn)

        character := to_character(fight.current_character)
        for &slot in character.ability_slots {
            slot.cooldown = max(0, slot.cooldown - 1)
        }
    }

    if !entity_handle_valid(game.player) {
        fight_change_phase(fight, .Player_Lose)
    } else if !fight_has_enemy(fight) {
        fight_change_phase(fight, .Player_Win)
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
        fight.current_turn += 1

        if fight.current_turn >= len(fight.turn_order) {
            new_round(fight)
            return
        }

        fight.current_character = fight.turn_order[fight.current_turn]
    }
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
    character_a, a_ok := to_character(handle_a)
    character_b, b_ok := to_character(handle_b)

    assert(a_ok && b_ok, "One of the Entity_Handles points to an Entity that is not a Character.")

    return character_a.base.stats[.Speed] < character_b.base.stats[.Speed]
}


// ------------------------------------- !END FIGHT! -------------------------------------


// +-------------------------------------------------------------------------------------+
// |                                 !FIGHT GENERATION!                                  |
// +-------------------------------------------------------------------------------------+


// Populates the given Fight using the FIGHTS list. Supposed to match the
// difficulty as closely as possible.
generate_fight :: proc(fight_index: i32, allocator := context.allocator, loc := #caller_location) -> []Character_Type {
    assert(fight_index >= 0 && fight_index < len(FIGHTS), "Fight out of bounds", loc)

    random_fight := rand.choice(FIGHTS[fight_index][:])
    return random_fight.composition
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
    MID_SCREEN :: f32(RENDER_WIDTH) / 2.0

    start_pos := MID_SCREEN - (f32(TIMELINE_WIDTH) / 2.0)
    rl.DrawRectangleV({ start_pos, TIMELINE_PADDING_Y + (TIMELINE_HEIGHT / 2) }, { TIMELINE_WIDTH, TIMELINE_HEIGHT }, rl.BLACK)

    total_offset := f32(0)

    for handle, index in fight.turn_order {
        if index < fight.current_turn || !entity_handle_valid(handle) {
            continue
        }

        character, ok := to_character(handle)
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
