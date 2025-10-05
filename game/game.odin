package game

import "core:math/rand"
import "core:log"
import rl "vendor:raylib"
import "vfiles"

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
    screen: Screen,
    fs: vfiles.Context,

    current_world: World,
    current_fight: Fight,
    camera: rl.Camera2D,

    player_data: Player_Data,
    won_games: i32,

    character_types: [Character_Type]Character_Data,
    textures: [Texture_Name]rl.Texture,
    particles: [Particle_Name]Particle,
    abilities: [Ability_Name]Ability_Info,
    sounds: [Sound_Name]rl.Sound,
}


// Initializes the Game. Can only be called once.
init_game :: proc(allocator := context.allocator, loc := #caller_location) {
    if game.screen != nil {
        log.error("Trying to initialize Game, but it is already initialized.", loc)
        return
    }

    game = Game{}

    vfiles.init_context(&game.fs, { "res" })

    game.screen = Screen_Main_Menu{}
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
    assert(game.screen != nil, "Game not initialized.", loc)
    vfiles.deinit_context(&game.fs)
    game_change_screen(nil)
}


// Starts a brand new game with the given player Character_Type.
start_new_game :: proc(player_type: Character_Type) {
    game.won_games = 0

    reset_player_data(&game.player_data)
    init_player_data(&game.player_data, player_type)

    deinit_world(&game.current_world)
    deinit_fight(&game.current_fight)

    start_fight()
}


// Starts a fight.
start_fight :: proc() {
    fight_data := rand.choice(FIGHTS[game.won_games][:])
    world_data := World_Data{
        tile_texture = fight_data.arena_tile,
        world_size = u32(fight_data.arena_size),
    }

    player_clone: Maybe(Entity)
    if player, ok := get_entity(game.player_data.entity); ok {
        player_clone = player^
    }

    load_world(world_data)

    deinit_fight(&game.current_fight)
    init_fight(&game.current_fight, game.won_games)

    if entity_handle_valid(game.player_data.entity) {
        free_entity(game.player_data.entity)
    }

    if player_clone == nil {
        game.player_data.entity = new_character(&game.current_world, game.player_data.character_type)
    } else {
        game.player_data.entity = clone_entity(&game.current_world, player_clone.?)
    }

    player_entity := get_entity(game.player_data.entity)
    player_entity.offset = { 0, 0 }
    player_entity.position = { 0, 0 }

    game_change_screen(Screen_Gameplay{})
}


load_world :: proc(world_data: World_Data, allocator := context.allocator, loc := #caller_location) {
    assert(game.screen != nil, "Game not initialized.", loc)

    deinit_world(&game.current_world)
    init_world(&game.current_world, world_data)

    half_size := f32(game.current_world.world_size * WORLD_UNITS) / 2.0
    game.camera.offset = {
        (RENDER_WIDTH / 2) - half_size,
        (RENDER_HEIGHT / 2) - half_size,
    }
}


// Changes the game's screen to the given one.
game_change_screen :: proc(screen: Screen, loc := #caller_location) {
    assert(game.screen != nil, "Game not initialized.", loc)

    switch &screen in game.screen {
    case Screen_Main_Menu: on_exit_screen_main_menu(&screen)
    case Screen_Gameplay:  on_exit_screen_gameplay(&screen)
    case Screen_Win:       on_exit_screen_win(&screen)
    case Screen_Lose:      on_exit_screen_lose(&screen)
    case Screen_Win_Game:  on_exit_screen_win_game(&screen)
    case Screen_Quit:
    }

    game.screen = screen

    switch &screen in game.screen {
    case Screen_Main_Menu: on_enter_screen_main_menu(&screen)
    case Screen_Gameplay:  on_enter_screen_gameplay(&screen)
    case Screen_Win:       on_enter_screen_win(&screen)
    case Screen_Lose:      on_enter_screen_lose(&screen)
    case Screen_Win_Game:  on_enter_screen_win_game(&screen)
    case Screen_Quit:      rl.CloseWindow()
    }

    log.infof("Changed Game screen to %v.", typeid_of(type_of(screen)))
}


// +-------------------------------------------------------------------------------------+
// |                                  !PROCESSING CALLS!                                 |
// +-------------------------------------------------------------------------------------+


// Calls a processing tick for the game.
tick :: proc() {
    delta_time := rl.GetFrameTime()

    switch &screen in game.screen {
    case Screen_Main_Menu: tick_screen_main_menu(delta_time, &screen)
    case Screen_Gameplay:  tick_screen_gameplay(delta_time, &screen)
    case Screen_Win:       tick_screen_win(delta_time, &screen)
    case Screen_Lose:      tick_screen_lose(delta_time, &screen)
    case Screen_Win_Game:  tick_screen_win_game(delta_time, &screen)
    case Screen_Quit:
    }
}


// Calls a draw tick for the game.
draw :: proc() {
    switch &screen in game.screen {
    case Screen_Main_Menu: draw_screen_main_menu(&screen)
    case Screen_Gameplay:  draw_screen_gameplay(&screen)
    case Screen_Win:       draw_screen_win(&screen)
    case Screen_Lose:      draw_screen_lose(&screen)
    case Screen_Win_Game:  draw_screen_win_game(&screen)
    case Screen_Quit:
    }
}


// Calls a UI draw tick for the game.
ui :: proc() {
    switch &screen in game.screen {
    case Screen_Main_Menu: ui_screen_main_menu(&screen)
    case Screen_Gameplay:  ui_screen_gameplay(&screen)
    case Screen_Win:       ui_screen_win(&screen)
    case Screen_Lose:      ui_screen_lose(&screen)
    case Screen_Win_Game:  ui_screen_win_game(&screen)
    case Screen_Quit:
    }
}


// -------------------------------- !END PROCESSING CALLS! -------------------------------
