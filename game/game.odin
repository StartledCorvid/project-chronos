package game

import "core:math/rand"
import "core:log"
import rl "vendor:raylib"

/*
# Overview
Handling of the overall game state.
*/


game: Game


Game_State :: enum {
    Not_Init,
    Main_Menu,
    Win_Screen,
    Lose_Screen,
    Win_Game,
    Gameplay,
    Quit,
}


// Holds the global values of the game.
Game :: struct {
    state: Game_State,
    main_menu: Main_Menu,
    current_world: World,
    current_fight: Fight,
    camera: rl.Camera2D,

    player_type: Character_Type,
    player: Entity_Handle,
    won_games: i32,

    character_types: [Character_Type]Character_Data,
    textures: [Texture_Name]rl.Texture,
    particles: [Particle_Name]Particle,
    abilities: [Ability_Name]Ability_Info,
    sounds: [Sound_Name]rl.Sound,
}


// Initializes the Game. Can only be called once.
init_game :: proc(allocator := context.allocator, loc := #caller_location) {
    if game.state != .Not_Init {
        log.error("Trying to initialize Game, but it is already initialized.", loc)
        return
    }

    game = Game{}

    game.state = .Main_Menu
    game.textures = load_textures()
    game.sounds = load_sounds()
    game.particles = load_particles()
    game.abilities = load_abilities()
    game.character_types = load_character_types()

    game.camera = rl.Camera2D{
        zoom = 1.0,
    }

    // Yes, this is redundant, but the game.state needs to NOT be .Not_Init before
    // calling, and setting it above is the easiest way to do that AND initialize
    // the main menu correctly.
    open_main_menu(&game)
}


// Deinitializes the Game, clearing all state and data.
deinit_game :: proc(allocator := context.allocator, loc := #caller_location) {
    assert(game.state != .Not_Init, "Game not initialized.", loc)
    game_change_state(&game, .Not_Init)
}


start_new_game :: proc(game: ^Game, player_type: Character_Type) {
    game.won_games = 0
    game.player_type = player_type

    start_fight(game)
}


start_fight :: proc(game: ^Game) {
    fight_data := rand.choice(FIGHTS[game.won_games][:])
    world_data := World_Data{
        tile_texture = fight_data.arena_tile,
        world_size = u32(fight_data.arena_size),
    }

    load_world(game, world_data)

    deinit_fight(&game.current_fight)
    init_fight(&game.current_fight, game.won_games)

    if entity_handle_valid(game.player) {
        free_entity(game.player)
    }
    game.player = new_character(&game.current_world, game.player_type)

    game_change_state(game, .Gameplay)
}


// Resets an existing Game struct to start a new run.
reset_game :: proc(game: ^Game, player_type: Character_Type) {
    game.won_games = 0

    deinit_world(&game.current_world)
    deinit_fight(&game.current_fight)

    // game.player = new_character(&game.current_world, player_type)
    game_change_state(game, .Gameplay)
}


load_world :: proc(game: ^Game, world_data: World_Data, allocator := context.allocator, loc := #caller_location) {
    assert(game.state != .Not_Init, "Game not initialized.", loc)
    assert(game != nil, "Nil Game pointer.", loc)

    deinit_world(&game.current_world)
    init_world(&game.current_world, world_data)

    half_size := f32(game.current_world.world_size * WORLD_UNITS) / 2.0
    game.camera.offset = {
        (RENDER_WIDTH / 2) - half_size,
        (RENDER_HEIGHT / 2) - half_size,
    }
}


// Changes the game's state to the given one.
game_change_state :: proc(game: ^Game, state: Game_State, loc := #caller_location) {
    assert(game != nil, "Nil Game pointer.", loc)
    assert(game.state != .Not_Init, "Game not initialized.", loc)

    game.state = state

    log.infof("Changed Game state to %v.", state)
}


// +-------------------------------------------------------------------------------------+
// |                                  !PROCESSING CALLS!                                 |
// +-------------------------------------------------------------------------------------+


// Calls a processing tick for the game.
tick :: proc(game: ^Game) {
    delta_time := rl.GetFrameTime()

    switch game.state {
    case .Not_Init:
    case .Main_Menu:   tick_main_menu(delta_time)
    case .Gameplay:    tick_gameplay(delta_time, &game.current_fight, &game.current_world)
    case .Win_Screen:  tick_win_screen(delta_time, game)
    case .Lose_Screen: tick_lose_screen(delta_time, game)
    case .Win_Game:    tick_win_game(delta_time, game)
    case .Quit:        rl.CloseWindow()
    }
}


// Calls a draw tick for the game.
draw :: proc(game: ^Game) {
    switch game.state {
    case .Not_Init:
    case .Main_Menu:   draw_main_menu(game)
    case .Gameplay:    draw_gameplay(game)
    case .Win_Screen:  draw_win_screen(game)
    case .Lose_Screen: draw_lose_screen(game)
    case .Win_Game:    draw_win_game(game)
    case .Quit:
    }
}


// Calls a UI draw tick for the game.
ui :: proc(game: ^Game) {
    switch game.state {
    case .Not_Init:
    case .Main_Menu:   ui_main_menu(game)
    case .Gameplay:    ui_gameplay(game)
    case .Win_Screen:  ui_win_screen(game)
    case .Lose_Screen: ui_lose_screen(game)
    case .Win_Game:    ui_win_game(game)
    case .Quit:
    }
}


// -------------------------------- !END PROCESSING CALLS! -------------------------------


// +-------------------------------------------------------------------------------------+
// |                                    !GAMEPLAY!                                       |
// +-------------------------------------------------------------------------------------+


// Processing tick for the Gameplay state of the game.
tick_gameplay :: proc(delta_time: f32, fight: ^Fight, world: ^World) {
    tick_fight(fight, delta_time)
    tick_world(world, delta_time)
}


// Rendering tick for the Gameplay state of the game.
draw_gameplay :: proc(game: ^Game) {
    draw_world(&game.current_world)
}


// UI rendering tick for the Gameplay state of the game.
ui_gameplay :: proc(game: ^Game) {
    ui_fight_draw_turn_timeline(game.current_fight)

    if entity_handle_valid(game.player) {
        ui_player(game.player)
    }
}


// ----------------------------------- !END GAMEPLAY! ------------------------------------
