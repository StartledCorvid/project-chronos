package game

import rl "vendor:raylib"


/*
# Overview
*/



open_main_menu :: proc(game: ^Game) {
    game_change_state(game, .Main_Menu)
}


// Processing tick for the Main Menu state of the game.
tick_main_menu :: proc(delta_time: f32) {

}


// Rendering tick for the Main Menu state of the game.
draw_main_menu :: proc(game: ^Game) {

}


// UI rendering tick for the Main Menu state of the game.
ui_main_menu :: proc(game: ^Game) {
    dimensions := Vector2{ 64, 12 }
    start_pos := Vector2{ PADDING, PADDING }
    PADDING :: 2

    rl.DrawText("Chronos", i32(start_pos.x), i32(start_pos.y), 16, rl.WHITE)

    // TODO: Choosing characters.

    if ui_button("New Game", dimensions, start_pos + { 0, 16 }, rl.BLACK, 4) {
        start_new_game(game, .Fighter)
    }

    if ui_button("Quit", dimensions, start_pos + { 0, dimensions.y + PADDING + 16 }, rl.BLACK, 4) {
        game_change_state(game, .Quit)
    }
}
