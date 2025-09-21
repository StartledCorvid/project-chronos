package game

import rl "vendor:raylib"


/*
# Overview
*/


// The different pages that can be open in the game.
Main_Menu_Page :: enum {
    Home,
    New_Game,
    Options,
}


// Holds data regarding the main menu of the game.
Main_Menu :: struct {
    page: Main_Menu_Page,
    selected_character: Maybe(Character_Type),
}


// Opens up the Main Menu of the game.
open_main_menu :: proc(game: ^Game) {
    game_change_state(game, .Main_Menu)
    game.main_menu = {
        page = .Home,
        selected_character = nil,
    }
}


// Changes the page that the main menu is currently on.
main_menu_change_page :: proc(main_menu: ^Main_Menu, page: Main_Menu_Page) {
    main_menu.page = page
}


// Processing tick for the Main Menu state of the game.
tick_main_menu :: proc(delta_time: f32) {

}


// Rendering tick for the Main Menu state of the game.
draw_main_menu :: proc(game: ^Game) {

}


// UI rendering tick for the Main Menu state of the game.
ui_main_menu :: proc(game: ^Game) {
    switch game.main_menu.page {
    case .Home:     ui_main_menu_home(game)
    case .New_Game: ui_main_menu_new_game(game)
    case .Options:
    }
}


// Draw the home screen of the main menu.
ui_main_menu_home :: proc(game: ^Game) {
    dimensions := Vector2{ 64, 12 }
    start_pos := Vector2{ PADDING, PADDING }
    PADDING :: 2

    rl.DrawText("Chronos", i32(start_pos.x), i32(start_pos.y), 16, rl.WHITE)

    if ui_button("New Game", dimensions, start_pos + { 0, 16 }, rl.BLACK, 4) {
        main_menu_change_page(&game.main_menu, .New_Game)
    }

    if ui_button("Quit", dimensions, start_pos + { 0, dimensions.y + PADDING + 16 }, rl.BLACK, 4) {
        game_change_state(game, .Quit)
    }
}


// Draw the new game screen of the game.
ui_main_menu_new_game :: proc(game: ^Game) {
    rl.DrawText("Choose a Character", 2, 2, 16, rl.WHITE)

    PADDING :: 2
    CHARACTER_BACKGROUND_SIZE :: 18
    tl_corner := Vector2{ PADDING, 16 + PADDING }
    for character_type in PLAYER_CHARACTERS {
        rl.DrawRectangleV(tl_corner, { CHARACTER_BACKGROUND_SIZE, CHARACTER_BACKGROUND_SIZE }, rl.BLACK)

        if game.main_menu.selected_character != nil && game.main_menu.selected_character == character_type {
            rl.DrawRectangleLines(i32(tl_corner.x), i32(tl_corner.y), CHARACTER_BACKGROUND_SIZE, CHARACTER_BACKGROUND_SIZE, rl.GREEN)
        }

        character_info := game.character_types[character_type]
        icon := get_texture(character_info.icon)

        icon_position := Vector2{
            (CHARACTER_BACKGROUND_SIZE - f32(icon.width)) / 2,
            (CHARACTER_BACKGROUND_SIZE - f32(icon.height)) / 2,
        }

        rl.DrawTextureV(icon, tl_corner + icon_position, rl.WHITE)

        click_box := rl.Rectangle{
            width = CHARACTER_BACKGROUND_SIZE,
            height = CHARACTER_BACKGROUND_SIZE,
            x = tl_corner.x,
            y = tl_corner.y,
        }

        mouse_pos := to_vector2(screen_to_render_point(rl.GetMousePosition()))
        if rl.IsMouseButtonReleased(.LEFT) && rl.CheckCollisionPointRec(mouse_pos, click_box) {
            game.main_menu.selected_character = character_type
        }

        tl_corner += { CHARACTER_BACKGROUND_SIZE + PADDING, 0 }
    }

    // TODO: Draw selected character stats.

    if game.main_menu.selected_character != nil && ui_button("Play", { 64, 12 }, { RENDER_WIDTH - 66, RENDER_HEIGHT - 14 }, rl.BLACK, 4) {
        start_new_game(game, game.main_menu.selected_character.?)
    }

    if ui_button("Back", { 64, 12 }, { PADDING, RENDER_HEIGHT - 14 }, rl.BLACK, 4) {
        main_menu_change_page(&game.main_menu, .Home)
    }
}