package game

import "core:strings"
import rl "vendor:raylib"


/*
# Overview
Helper procs for UI handling using Raylib.

# Spaces
Because of the adjustments that go on to scale the rendering space to the
resolution of the window, there are a few different spaces.
- Screen: A point on the screen/window of the game.
- Render: A point on the render texture of the game.
- World: A point within the world of the game. Does not have to be on the screen.
*/


// A point on the screen/window of the game.
Screen_Point :: Vector2
// A point on the render texture of the game.
Render_Point :: Vector2i
// A point within the world of the game. Does not have to be on the screen.
World_Point  :: World_Coords


// +-------------------------------------------------------------------------------------+
// |                                   !CONVERSIONS!                                     |
// +-------------------------------------------------------------------------------------+


// Given a point on the render texture of the game, converts the point to its
// corresponding point on the screen/window.
render_to_screen_point :: proc(render_point: Render_Point) -> Screen_Point {
    relative_x := f32(render_point.x / RENDER_WIDTH)
    relative_y := f32(render_point.y / RENDER_HEIGHT)

    return {
        relative_x * WINDOW_WIDTH,
        relative_y * WINDOW_HEIGHT,
    }
}


// Given a point on the render texture of the game, converts it
// to its corresponding point in the world.
render_to_world_point :: proc(render_point: Render_Point) -> World_Point {
    return render_point - to_vector2i(game.camera.offset)
}


// Given a point in the world, converts the point to a point on the screen.
// Note that this might result in a point outside of the screen.
world_to_screen_point :: proc(world_point: World_Point) -> Screen_Point {
    render_point := world_to_render_point(world_point)
    return render_to_screen_point(render_point)
}


// Given a point in the game's world, returns its corresponding point on the
// render texture.
world_to_render_point :: proc(world_point: World_Point) -> Render_Point {
    return world_point + to_vector2i(game.camera.offset)
}


// Given a point on the screen/window of the game, converts the point
// to its corresponding point in the world.
screen_to_world_point :: proc(screen_point: Screen_Point) -> World_Point {
    render_point := screen_to_render_point(screen_point)
    return render_to_world_point(render_point)
}


// Given a point on the screen/window, returns its corresponding point on the
// render texture.
screen_to_render_point :: proc(screen_point: Screen_Point) -> Render_Point {
    relative_x := screen_point.x / WINDOW_WIDTH
    relative_y := screen_point.y / WINDOW_HEIGHT

    return {
        i32(relative_x * RENDER_WIDTH),
        i32(relative_y * RENDER_HEIGHT),
    }
}


// ---------------------------------- !END CONVERSIONS! ----------------------------------

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

    mouse_pos := screen_to_render_point(rl.GetMousePosition())
    return rl.IsMouseButtonReleased(.LEFT) && rl.CheckCollisionPointRec(to_vector2(mouse_pos), rect)
}