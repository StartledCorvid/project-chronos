package game

import rl "vendor:raylib"


/*
# Overview
The handling of the different screens of the game.
*/

// Data types specific to different game Screens.
Screen :: union {
    Screen_Main_Menu,
    Screen_Gameplay,
    Screen_Win,
    Screen_Lose,
    Screen_Win_Game,
    Screen_Quit,
}


// +-------------------------------------------------------------------------------------+
// |                                   !MAIN MENU!                                       |
// +-------------------------------------------------------------------------------------+


// Holds data regarding the main menu of the game.
Screen_Main_Menu :: struct {
    page: Main_Menu_Page,
    selected_character: Maybe(Character_Type),
}


// Called when the game state first changes to Screen_Main_Menu.
on_enter_screen_main_menu :: proc(screen: ^Screen_Main_Menu) {

}


// Called when the game state leaves Screen_Main_Menu.
on_exit_screen_main_menu :: proc(screen: ^Screen_Main_Menu) {

}


// Processing tick for the Main Menu state of the game.
tick_screen_main_menu :: proc(delta_time: f32, screen: ^Screen_Main_Menu) {

}


// Rendering tick for the Main menu state of the game.
draw_screen_main_menu :: proc(screen: ^Screen_Main_Menu) {
    
}


// UI rendering tick for the Main Menu state of the game.
ui_screen_main_menu :: proc(screen: ^Screen_Main_Menu) {
    switch screen.page {
    case .Home:     ui_main_menu_home(screen)
    case .New_Game: ui_main_menu_new_game(screen)
    case .Options:
    }
}


// ---------------------------------- !END MAIN MENU! ------------------------------------


// +-------------------------------------------------------------------------------------+
// |                                 !GAMEPLAY SCREEN!                                   |
// +-------------------------------------------------------------------------------------+


// Data for the Gameplay screen of the game.
Screen_Gameplay :: struct {

}


// Called when the game first enters the Gameplay screen.
on_enter_screen_gameplay :: proc(screen: ^Screen_Gameplay) {

}


// Called whenever the game exits the gameplay screen.
on_exit_screen_gameplay :: proc(screen: ^Screen_Gameplay) {

}


// Processing tick for the Gameplay state of the game.
tick_screen_gameplay :: proc(delta_time: f32, screen: ^Screen_Gameplay) {
    tick_fight(&game.current_fight, delta_time)
    tick_world(&game.current_world, delta_time)
}


// Rendering tick for the Gameplay state of the game.
draw_screen_gameplay :: proc(screen: ^Screen_Gameplay) {
    draw_world(&game.current_world)
}


// UI rendering tick for the Gameplay state of the game.
ui_screen_gameplay :: proc(screen: ^Screen_Gameplay) {
    ui_fight_draw_turn_timeline(game.current_fight)

    if entity_handle_valid(game.player) {
        ui_player(game.player)
    }
}


// -------------------------------- !END GAMEPLAY SCREEN! --------------------------------


// +-------------------------------------------------------------------------------------+
// |                                   !WIN SCREEN!                                      |
// +-------------------------------------------------------------------------------------+


// This screen is called when the player wins a fight. It will present a choice of reward
// and the option to carry on to the next fight.
Screen_Win :: struct {
    rewards: [dynamic]Item_Name,
}


// Called when the game state first changes to Screen_Win.
on_enter_screen_win :: proc(screen: ^Screen_Win) {
    REWARD_COUNT :: 2
    MAX_OFFSET   :: 0.1 // Offset for the maximum reward index.
    
    if game.won_games >= len(FIGHTS) {
        game_change_screen(Screen_Win_Game{})
        return
    }

    for _ in 0..<REWARD_COUNT {
        random_reward := get_drop()
        append(&screen.rewards, random_reward)
    }
}


// Called when the game state leaves Screen_Win.
on_exit_screen_win :: proc(screen: ^Screen_Win) {
    delete(screen.rewards)
}


// Processing tick for the Win Screen state of the game.
tick_screen_win :: proc(delta_time: f32, screen: ^Screen_Win) {
}


// Rendering tick for the Win Screen state of the game.
draw_screen_win :: proc(screen: ^Screen_Win) {
    draw_world(&game.current_world)
}


// UI rendering tick for the Win Screen state of the game.
ui_screen_win :: proc(screen: ^Screen_Win) {
    CENTER_OF_SCREEN :: Vector2i{ RENDER_WIDTH / 2, RENDER_HEIGHT / 2 }
    HEADING_PADDING  :: 2
    HEADING_SIZE     :: 8
    PROMPT_SIZE      :: 4
    REWARD_PADDING   :: 2

    rl.DrawRectangleV({ 0, 0 }, { RENDER_WIDTH, RENDER_HEIGHT }, { 0, 0, 0, 200 })

    // Heading
    {
        text: cstring = "Fight Won!"
        width := rl.MeasureText(text, HEADING_SIZE)
        rl.DrawText(text, CENTER_OF_SCREEN.x - (width / 2), 2, HEADING_SIZE, rl.WHITE)
    }

    // Prompt
    {
        text: cstring = "Choose a Reward"
        width := rl.MeasureText(text, PROMPT_SIZE)
        rl.DrawText(text, CENTER_OF_SCREEN.x - (width / 2), HEADING_PADDING + HEADING_SIZE + HEADING_PADDING, PROMPT_SIZE, rl.WHITE)
    }

    // Rewards
    item_pos := CENTER_OF_SCREEN
    for reward in screen.rewards {
        pressed, button_size := ui_item_button(ITEMS[reward], to_vector2(item_pos))
        item_pos.y += i32(button_size.y + UI_PADDING.y)

        if pressed {
            player := get_entity(game.player)
            equip_item(player, reward) // TODO: Need to preserve the player Entity between fights.
            start_fight()
        }
    }
}


// ---------------------------------- !END WIN SCREEN! -----------------------------------


// +-------------------------------------------------------------------------------------+
// |                                  !LOSE SCREEN!                                      |
// +-------------------------------------------------------------------------------------+


// Data for the lose screen.
Screen_Lose :: struct {

}


// Called when the game's screen first changes to the Lose screen.
on_enter_screen_lose :: proc(screen: ^Screen_Lose) {

}


// Called when the game leaves the Lose screen.
on_exit_screen_lose :: proc(screen: ^Screen_Lose) {

}


// Processing tick for the Lose Screen state of the game.
tick_screen_lose :: proc(delta_time: f32, screen: ^Screen_Lose) {
    if rl.IsMouseButtonPressed(.LEFT) {
        open_main_menu(&game)
    }
}


// Rendering tick for the Lose Screen state of the game.
draw_screen_lose :: proc(screen: ^Screen_Lose) {
    
}


// UI rendering tick for the Lose Screen state of the game.
ui_screen_lose :: proc(screen: ^Screen_Lose) {
    rl.DrawText("Lose! Click to Continue", 0, 0, 8, rl.GREEN)
}


// --------------------------------- !END LOSE SCREEN! -----------------------------------


// +-------------------------------------------------------------------------------------+
// |                                    !WIN GAME!                                       |
// +-------------------------------------------------------------------------------------+


// Data for the screen that is shown when the player wins the game.
Screen_Win_Game :: struct {

}


// Called when the game state first changes to Screen_Win_Game.
on_enter_screen_win_game :: proc(screen: ^Screen_Win_Game) {

}


// Called when the game state leaves Screen_Win_Game.
on_exit_screen_win_game :: proc(screen: ^Screen_Win_Game) {

}



// Processing tick for the Win Game state of the game.
tick_screen_win_game :: proc(delta_time: f32, screen: ^Screen_Win_Game) {
    if rl.IsMouseButtonPressed(.LEFT) {
        open_main_menu(&game)
    }
}


// Rendering tick for the Win Game state of the game.
draw_screen_win_game :: proc(screen: ^Screen_Win_Game) {
    
}


// UI rendering tick for the Win Game state of the game.
ui_screen_win_game :: proc(screen: ^Screen_Win_Game) {
    rl.DrawText("You have won the game!", 0, 0, 8, rl.GREEN)
    rl.DrawText("Click to continue.", 0, 8, 8, rl.WHITE)
}


// ----------------------------------- !END WIN GAME! ------------------------------------


// No data for quitting right now. Does not draw anything.
// Just used as a tag.
Screen_Quit :: struct {}