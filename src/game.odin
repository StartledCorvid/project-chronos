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
    Gameplay,
}


// Holds the global values of the game.
Game :: struct {
    state: Game_State,
    current_world: ^World,
    camera: rl.Camera2D,

    player: Entity_Handle,

    character_types: [Character_Type]Character_Data,
    textures: [Texture_Name]rl.Texture,
}


init_game :: proc(allocator := context.allocator, loc := #caller_location) {
    if game.state != .Not_Init {
        log.error("Trying to initialize Game, but it is already initialized.", loc)
        return
    }

    game = Game{}

    game.state = .Main_Menu
    game.textures = load_textures()
    game.character_types = load_character_types()

    game.camera = rl.Camera2D{
        zoom = 1.0,
    }
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
    game.state = .Gameplay
}


unload_world :: proc(allocator := context.allocator, loc := #caller_location) {
    assert(game.current_world != nil, "No World currently loaded.", loc)
    free_world(game.current_world, allocator, loc)
}