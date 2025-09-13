package game

// import "core:log"
import rl "vendor:raylib"


/*
# Overview
*/


Main_Menu_Page :: enum {
    Main,
    Options,
}


Main_Menu_Actions :: enum {
    None,
    Quit,
    New_Game,
}


Main_Menu :: struct {
    current_page: Main_Menu_Page,
}


open_main_menu :: proc() -> bool {
    main_menu := Main_Menu{}

    for !rl.WindowShouldClose() {
        
        action := main_menu_process(&main_menu)

        switch action {
        case .New_Game:
            return true
        case .Quit:
            return false
        case .None:
        }
    }
    return false
}


main_menu_process :: proc(main_menu: ^Main_Menu) -> Main_Menu_Actions {
    switch main_menu.current_page {
    case .Main:
        return main_menu_process_main(main_menu)
    case .Options:
    }

    return .None
}


main_menu_process_main :: proc(main_menu: ^Main_Menu) -> Main_Menu_Actions {


    return .None
}

tick_main_menu :: proc(delta_time: f32) {

}


ui_main_menu :: proc() {
    dimensions := Vector2{ 64, 12 }
    start_pos := Vector2{ PADDING, PADDING }
    PADDING :: 2

    rl.DrawText("Chronos", i32(start_pos.x), i32(start_pos.y), 16, rl.WHITE)

    // TODO: Choosing characters.

    if ui_button("New Game", dimensions, start_pos + { 0, 16 }, rl.BLACK, 4) {
        start_new_game(&game, .Fighter)
    }

    if ui_button("Quit", dimensions, start_pos + { 0, dimensions.y + PADDING + 16 }, rl.BLACK, 4) {
        game.state = .Quit
    }
}