package game

import "core:fmt"
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


// Returns a position that is the top left corner of something centered in `area_size`.
// `centered_size` is the size of the element that is being centered. Offset is
// the top left corner position of the area to center it on.
ui_center_pos :: proc(offset: Vector2, area_size: Vector2, centered_size: Vector2) -> Vector2 {
    relative_position := Vector2{
        (area_size.x - centered_size.x) / 2,
        (area_size.y - centered_size.y) / 2,
    }

    return offset + relative_position
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

    mouse_pos := screen_to_render_point(rl.GetMousePosition())
    return rl.IsMouseButtonReleased(.LEFT) && rl.CheckCollisionPointRec(to_vector2(mouse_pos), rect)
}


UI_COLOR_BACKGROUND :: rl.Color{ 75, 75, 75, 255 }
UI_COLOR_MAIN_TEXT  :: rl.WHITE

UI_PADDING :: Vector2{ 2, 2 }

UI_TEXT_HEADING_SIZE :: 8
UI_TEXT_DETAIL_SIZE  :: 2


// Draws a button that gives the player the displayed Item when clicked.
ui_item_button :: proc(item: Item, position: Vector2) -> (bool, Vector2) {
    item_icon    := get_texture(item.icon)
    rarity_color := RARITY_COLORS[item.rarity]

    name_text        := fmt.ctprintf("%v", item.name)
    description_text := fmt.ctprintf("%v", item.description)

    name_width        := f32(rl.MeasureText(name_text, UI_TEXT_HEADING_SIZE))
    description_width := f32(rl.MeasureText(description_text, UI_TEXT_DETAIL_SIZE))

    rarity_rect := rl.Rectangle{
        width = f32(item_icon.width) + (5 * UI_PADDING.x) + max(name_width, description_width),
        height = f32(item_icon.height) + (4 * UI_PADDING.y),

        x = position.x,
        y = position.y,
    }

    background_rect := rl.Rectangle{
        width = rarity_rect.width - (2 * UI_PADDING.x),
        height = rarity_rect.height - (2 * UI_PADDING.y),

        x = position.x + UI_PADDING.x,
        y = position.y + UI_PADDING.y,
    }

    mouse_pos := screen_to_render_point(rl.GetMousePosition())
    pressed := rl.IsMouseButtonReleased(.LEFT) && rl.CheckCollisionPointRec(to_vector2(mouse_pos), rarity_rect)

    rl.DrawRectangleRec(rarity_rect, rarity_color)
    rl.DrawRectangleRec(background_rect, UI_COLOR_BACKGROUND)

    icon_pos := Vector2{ background_rect.x, background_rect.y } + UI_PADDING
    rl.DrawTextureV(item_icon, icon_pos, rl.WHITE)

    heading_pos := icon_pos + { f32(item_icon.width) + UI_PADDING.x, 0 }
    rl.DrawText(name_text, i32(heading_pos.x), i32(heading_pos.y), UI_TEXT_HEADING_SIZE, UI_COLOR_MAIN_TEXT)

    return pressed, {
        rarity_rect.width,
        rarity_rect.height,
    }
}


// Draws a tooltip for the given Item, with an anchor point on position.
ui_item_tooltip :: proc(item: Item, position: Vector2) {
    TOOLTIP_WIDTH :: 24
    HALF_WIDTH    :: RENDER_WIDTH / 2
    HALF_HEIGHT   :: RENDER_HEIGHT / 2

    HEADING_SIZE :: 8
    DETAIL_SIZE  :: 2

    tooltip_height := f32(UI_PADDING.y * 2)

    // == Gather information for displaying the Item.
    rarity_color := RARITY_COLORS[item.rarity]

    heading_text     := fmt.ctprintf("%v", item.name)
    // description_text := fmt.ctprintf("%v", item.description)
    // type_text        := fmt.ctprintf("%v", item.type)

    // == Determine dimensions.
    name_background_size := Vector2{
        TOOLTIP_WIDTH - (2 * UI_PADDING.x),
        (2 * UI_PADDING.y) + HEADING_SIZE,
    }

    tooltip_height += name_background_size.y


    // == Set the anchor point depending on where on the screen the target pos is.
    anchor_point := position
    if anchor_point.x < HALF_WIDTH {
        anchor_point.x -= TOOLTIP_WIDTH
    }

    if anchor_point.y > HALF_HEIGHT {
        anchor_point.y -= tooltip_height
    }

    tooltip_size := Vector2{ TOOLTIP_WIDTH, tooltip_height }

    // == Draw

    // -- Background
    rl.DrawRectangleV(anchor_point, tooltip_size, rarity_color)

    // -- Item Name
    rl.DrawRectangleV(anchor_point + UI_PADDING, name_background_size, UI_COLOR_BACKGROUND)
    name_text_pos := to_vector2i(anchor_point + (UI_PADDING * 2))
    rl.DrawText(heading_text, name_text_pos.x, name_text_pos.y, HEADING_SIZE, UI_COLOR_MAIN_TEXT)

    // -- Item Description
}