package game

import "core:strings"
import rl "vendor:raylib"


/*
# Overview
Helper procs for UI handling using Raylib.
*/


// Converts the Window position to a position on the screen.
window_to_screen :: proc(window_pos: rl.Vector2) -> rl.Vector2 {
    relative_x := window_pos.x / f32(rl.GetRenderWidth())
    relative_y := window_pos.y / f32(rl.GetRenderHeight())

    return { RES_X * relative_x, RES_Y * relative_y, }
}


window_to_world :: proc(window_pos: rl.Vector2) -> rl.Vector2 {
    return window_to_screen(window_pos) - game.camera.offset
}


// Draws a UI button. Returns true if it is clicked.
ui_button :: proc(text: string, dimensions: Vector2, position: Vector2, rect_color: rl.Color, text_size: i32, text_color := rl.WHITE) -> bool {
    rect := rl.Rectangle{
        width = dimensions.x,
        height = dimensions.y,
        x = position.x,
        y = position.y,
    }

    rl.DrawRectangleRec(rect, rect_color)
    rl.DrawText(strings.clone_to_cstring(text), i32(position.x), i32(position.y), text_size, text_color)

    mouse_pos := window_to_screen(rl.GetMousePosition())
    return rl.IsMouseButtonReleased(.LEFT) && rl.CheckCollisionPointRec(mouse_pos, rect)
}