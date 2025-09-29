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


// Opens up the Main Menu of the game.
open_main_menu :: proc(game: ^Game) {
    game_change_screen(Screen_Main_Menu{
        page = .Home,
        selected_character = nil,
    })
}


// Changes the page that the main menu is currently on.
main_menu_change_page :: proc(main_menu: ^Screen_Main_Menu, page: Main_Menu_Page) {
    main_menu.page = page
}


// Draw the home screen of the main menu.
ui_main_menu_home :: proc(screen: ^Screen_Main_Menu) {
    dimensions := Vector2{ 64, 12 }
    start_pos := Vector2{ PADDING, PADDING }
    PADDING :: 2

    rl.DrawText("Chronos", i32(start_pos.x), i32(start_pos.y), 16, rl.WHITE)

    if ui_button("New Game", dimensions, start_pos + { 0, 16 }, rl.BLACK, 4) {
        main_menu_change_page(screen, .New_Game)
    }

    if ui_button("Quit", dimensions, start_pos + { 0, dimensions.y + PADDING + 16 }, rl.BLACK, 4) {
        game_change_screen(Screen_Quit{})
    }
}


// Draw the new game screen of the game.
ui_main_menu_new_game :: proc(screen: ^Screen_Main_Menu) {
    rl.DrawText("Choose a Character", 2, 2, 16, rl.WHITE)

    PADDING :: 2
    CHARACTER_BACKGROUND_SIZE :: 18
    tl_corner := Vector2{ PADDING, 16 + PADDING }
    for character_type in PLAYER_CHARACTERS {
        rl.DrawRectangleV(tl_corner, { CHARACTER_BACKGROUND_SIZE, CHARACTER_BACKGROUND_SIZE }, rl.BLACK)

        if screen.selected_character != nil && screen.selected_character == character_type {
            rl.DrawRectangleLines(i32(tl_corner.x), i32(tl_corner.y), CHARACTER_BACKGROUND_SIZE, CHARACTER_BACKGROUND_SIZE, rl.GREEN)
        }

        character_info := game.character_types[character_type]
        icon := get_texture(character_info.icon)

        icon_position := ui_center_pos(tl_corner, CHARACTER_BACKGROUND_SIZE, { f32(icon.width), f32(icon.height) })

        rl.DrawTextureV(icon, icon_position, rl.WHITE)

        click_box := rl.Rectangle{
            width = CHARACTER_BACKGROUND_SIZE,
            height = CHARACTER_BACKGROUND_SIZE,
            x = tl_corner.x,
            y = tl_corner.y,
        }

        mouse_pos := to_vector2(screen_to_render_point(rl.GetMousePosition()))
        if rl.IsMouseButtonReleased(.LEFT) && rl.CheckCollisionPointRec(mouse_pos, click_box) {
            screen.selected_character = character_type
        }

        tl_corner += { CHARACTER_BACKGROUND_SIZE + PADDING, 0 }
    }

    // TODO: Draw selected character stats.

    if screen.selected_character != nil && ui_button("Play", { 64, 12 }, { RENDER_WIDTH - 66, RENDER_HEIGHT - 14 }, rl.BLACK, 4) {
        start_new_game(screen.selected_character.?)
    }

    if ui_button("Back", { 64, 12 }, { PADDING, RENDER_HEIGHT - 14 }, rl.BLACK, 4) {
        main_menu_change_page(screen, .Home)
    }
}