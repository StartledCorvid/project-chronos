package game

import rl "vendor:raylib"


/*
# Overview
The handling of the different screens of the game.
*/


// +-------------------------------------------------------------------------------------+
// |                                   !WIN SCREEN!                                      |
// +-------------------------------------------------------------------------------------+


// Processing tick for the Win Screen state of the game.
tick_win_screen :: proc(delta_time: f32, game: ^Game) {
    if rl.IsMouseButtonPressed(.LEFT) {
        if game.won_games < len(FIGHTS) {
            start_fight(game)
        } else {
            game_change_state(game, .Win_Game)
        }
    }
}


// Rendering tick for the Win Screen state of the game.
draw_win_screen :: proc(game: ^Game) {
    draw_world(&game.current_world)
}


// UI rendering tick for the Win Screen state of the game.
ui_win_screen :: proc(game: ^Game) {
    rl.DrawText("Win! Click to Continue", 0, 0, 8, rl.GREEN)
}


// ---------------------------------- !END WIN SCREEN! -----------------------------------


// +-------------------------------------------------------------------------------------+
// |                                  !LOSE SCREEN!                                      |
// +-------------------------------------------------------------------------------------+


// Processing tick for the Lose Screen state of the game.
tick_lose_screen :: proc(delta_time: f32, game: ^Game) {
    if rl.IsMouseButtonPressed(.LEFT) {
        open_main_menu(game)
    }
}


// Rendering tick for the Lose Screen state of the game.
draw_lose_screen :: proc(game: ^Game) {
    
}


// UI rendering tick for the Lose Screen state of the game.
ui_lose_screen :: proc(game: ^Game) {
    rl.DrawText("Lose! Click to Continue", 0, 0, 8, rl.GREEN)
}


// --------------------------------- !END LOSE SCREEN! -----------------------------------


// +-------------------------------------------------------------------------------------+
// |                                    !WIN GAME!                                       |
// +-------------------------------------------------------------------------------------+


// Processing tick for the Win Game state of the game.
tick_win_game :: proc(delta_time: f32, game: ^Game) {
    if rl.IsMouseButtonPressed(.LEFT) {
        open_main_menu(game)
    }
}


// Rendering tick for the Win Game state of the game.
draw_win_game :: proc(game: ^Game) {
    
}


// UI rendering tick for the Win Game state of the game.
ui_win_game :: proc(game: ^Game) {
    rl.DrawText("You have won the game!", 0, 0, 8, rl.GREEN)
    rl.DrawText("Click to continue.", 0, 8, 8, rl.WHITE)
}


// ----------------------------------- !END WIN GAME! ------------------------------------