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
    current_world: World,
    current_fight: Fight,
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

    game.state = .Gameplay
}


// Resets an existing Game struct to start a new run.
reset_game :: proc(game: ^Game, player_type: Character_Type) {
    game.won_games = 0

    deinit_world(&game.current_world)
    deinit_fight(&game.current_fight)

    // game.player = new_character(&game.current_world, player_type)
    game.state = .Gameplay
}


deinit_game :: proc(allocator := context.allocator, loc := #caller_location) {
    assert(game.state != .Not_Init, "Game not initialized.", loc)
}


load_world :: proc(game: ^Game, world_data: World_Data, allocator := context.allocator, loc := #caller_location) {
    assert(game.state != .Not_Init, "Game not initialized.", loc)
    assert(game != nil, "Nil Game pointer.", loc)

    deinit_world(&game.current_world)
    init_world(&game.current_world, world_data)

    half_size := f32(game.current_world.world_size * WORLD_UNITS) / 2.0
    game.camera.offset = {
        (RES_X / 2) - half_size,
        (RES_Y / 2) - half_size,
    }
}


return_to_main_menu :: proc(game: ^Game) {
    game.state = .Main_Menu

    deinit_world(&game.current_world)
    deinit_fight(&game.current_fight)
}



tick_game :: proc(game: ^Game) {
    delta_time := rl.GetFrameTime()

    switch game.state {
    case .Not_Init:
    case .Main_Menu:
        tick_main_menu(delta_time)
    case .Gameplay:
        tick_gameplay(delta_time, &game.current_fight, &game.current_world)
    case .Win_Screen:
        if rl.IsMouseButtonPressed(.LEFT) {
            if game.won_games < len(FIGHTS) {
                start_fight(game)
            } else {
                game.state = .Win_Game
            }
        }
    case .Lose_Screen:
        if rl.IsMouseButtonPressed(.LEFT) {
            return_to_main_menu(game)
        }
    case .Win_Game:
        if rl.IsMouseButtonPressed(.LEFT) {
            return_to_main_menu(game)
        }
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
        world_draw(&game.current_world)
    case .Win_Screen:
        world_draw(&game.current_world)
    case .Lose_Screen:
    case .Win_Game:
    case .Quit:
    }
}


ui_game :: proc(game: ^Game) {
    switch game.state {
    case .Not_Init:
    case .Main_Menu:
        ui_main_menu()
    case .Gameplay:
        ui_fight_draw_turn_timeline(game.current_fight)

        if entity_handle_valid(game.player) {
            draw_player_ui(game.player)
        }
    case .Win_Screen:
        rl.DrawText("Win! Click to Continue", 0, 0, 8, rl.GREEN)
    case .Lose_Screen:
        rl.DrawText("Lose! Click to Continue", 0, 0, 8, rl.GREEN)
    case .Win_Game:
        rl.DrawText("You have won the game!", 0, 0, 8, rl.GREEN)
        rl.DrawText("Click to continue.", 0, 8, 8, rl.WHITE)
    case .Quit:
    }
}