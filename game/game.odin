package game
/*
# Overview
Handling of the overall game state.
*/

import "core:log"
import rl "vendor:raylib"

game: Game

Game_State :: enum {
    Not_Init,
    Main_Menu,
    Win_Screen,
    Lose_Screen,
    Gameplay,
    Quit,
}


// Holds the global values of the game.
Game :: struct {
    state: Game_State,
    current_world: ^World,
    current_fight: ^Fight,
    camera: rl.Camera2D,

    player_type: Character_Type,
    player: Entity_Handle,
    won_games: i32,

    character_types: [Character_Type]Character_Data,
    textures: [Texture_Name]rl.Texture,
    particles: [Particle_Name]Particle,
}


init_game :: proc(allocator := context.allocator, loc := #caller_location) {
    if game.state != .Not_Init {
        log.error("Trying to initialize Game, but it is already initialized.", loc)
        return
    }

    game = Game{}

    game.state = .Main_Menu
    game.textures = load_textures()
    game.particles = load_particles()
    game.character_types = load_character_types()

    game.camera = rl.Camera2D{
        zoom = 1.0,
    }
}


start_new_game :: proc(game: ^Game, player_type: Character_Type) {
    game.won_games = 0
    game.player_type = player_type

    start_fight(game)
}


start_fight :: proc(game: ^Game) {
    load_world(.Default)

    if game.current_fight != nil {
        free_fight(game.current_fight)
    }
    game.current_fight = new_fight()
    
    game.player = new_character(game.current_world, game.player_type)

    game.state = .Gameplay
}


// Resets an existing Game struct to start a new run.
reset_game :: proc(game: ^Game, player_type: Character_Type) {
    game.won_games = 0

    game.player = new_character(game.current_world, player_type)
    game.state = .Gameplay

    game.current_fight = new_fight()
}


deinit_game :: proc(allocator := context.allocator, loc := #caller_location) {
    assert(game.state != .Not_Init, "Game not initialized.", loc)

    if game.current_world != nil {
        unload_world(allocator, loc)
    }
}


load_world :: proc(world: World_Names, allocator := context.allocator, loc := #caller_location) {
    assert(game.state != .Not_Init, "Game not initialized.", loc)

    if game.current_world != nil {
        unload_world(allocator, loc)
    }

    game.current_world = new_world(world_data_list[world], allocator, loc)

    half_size := f32(game.current_world.world_size * WORLD_UNITS) / 2.0
    game.camera.offset = {
        (RES_X / 2) - half_size,
        (RES_Y / 2) - half_size,
    }
}


unload_world :: proc(allocator := context.allocator, loc := #caller_location) {
    assert(game.current_world != nil, "No World currently loaded.", loc)
    free_world(game.current_world, allocator, loc)
}



tick_game :: proc(game: ^Game) {
    delta_time := rl.GetFrameTime()

    switch game.state {
    case .Not_Init:
    case .Main_Menu:
        tick_main_menu(delta_time)
    case .Gameplay:
        tick_gameplay(delta_time, game.current_fight, game.current_world)
    case .Win_Screen:
        if rl.IsMouseButtonPressed(.LEFT) {
            start_fight(game)
        }
    case .Lose_Screen:
    case .Quit:
        rl.CloseWindow()
    }
}


draw_game :: proc(game: ^Game) {
    switch game.state {
    case .Not_Init:
    case .Main_Menu:
    case .Gameplay:
        // TODO: Process animations. Maybe make a general tick method that does both.
        //       Or handle in the draw call.
        world_draw(game.current_world)
    case .Win_Screen:
        world_draw(game.current_world)
    case .Lose_Screen:
    case .Quit:
    }
}


ui_game :: proc(game: ^Game) {
    switch game.state {
    case .Not_Init:
    case .Main_Menu:
        ui_main_menu()
    case .Gameplay:
        ui_fight_draw_turn_timeline(game.current_fight^)

        if entity_handle_valid(game.player) {
            draw_player_ui(game.player)
        }
    case .Win_Screen:
        rl.DrawText("Win! Click to Continue", 0, 0, 8, rl.GREEN)
    case .Lose_Screen:
    case .Quit:
    }
}