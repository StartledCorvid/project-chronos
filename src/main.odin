package game
/*
import "core:encoding/base32"
import "core:math/rand"
# Overview

*/

import "core:log"
import "core:os"
import "core:fmt"
import "core:mem"
import "core:strings"
import rl "vendor:raylib"



WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

RES_X :: 320
RES_Y :: 180

PANEL_SIZE :: 64

WINDOW_TITLE :: "Chronos"

TARGET_FPS :: 60


main :: proc() {
	// == Leak Tracker.
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)
		defer {
			if len(track.allocation_map) > 0 {
				for _, entry in track.allocation_map {
					log.warnf("%v leaked %v bytes.", entry.location, entry.size)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	// == Logger.
	c_log := log.create_console_logger()
	defer log.destroy_console_logger(c_log)

    log_file, err := os.open("chronos.log", os.O_WRONLY | os.O_CREATE | os.O_TRUNC)
    assert(err == nil, "Problem setting up the file logger.")
    defer os.close(log_file)

	f_log := log.create_file_logger(log_file)
	defer log.destroy_file_logger(f_log)

	logger := log.create_multi_logger(f_log, c_log)
	defer log.destroy_multi_logger(logger)

	context.logger = logger

	// == Inint Raylib.
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
	defer rl.CloseWindow()

	rl.SetTargetFPS(TARGET_FPS)
	rl.SetExitKey(.KEY_NULL)
	rl.SetWindowMinSize(RES_X, RES_Y)

	rl.SetConfigFlags({ .VSYNC_HINT })

    target_texture := rl.LoadRenderTexture(RES_X, RES_Y)
    defer rl.UnloadRenderTexture(target_texture)
    rl.SetTextureFilter(target_texture.texture, .POINT)

	// == Game state.
	init_game()
	defer deinit_game()

	// TODO: Loading different levels.
	world := new_world(world_data_list[.Default])
	game.current_world = world
	half_size := f32(game.current_world.world_size * WORLD_UNITS) / 2.0
	game.camera.offset = {
		(RES_X / 2) - half_size,
		(RES_Y / 2) - half_size,
	}

	fight := new_fight()
	defer free_fight(fight)

	// == Random stuff.
	game.player = new_character(world, .Fighter)

	for _ in 0..<2 {
		enemy := new_character(world, .Goblin)
		random_pos := random_world_point(world^)
		for !world_space_empty(world, random_pos) do random_pos = random_world_point(world^)
		get_entity(enemy).position = random_pos
	}

	
	// == Game loop.
	for !rl.WindowShouldClose() {
		// -- Input.

		// -- Processing.
		// TODO: Process animations. Maybe make a general tick method that does both.
		//       Or handle in the draw call.
		delta_time := rl.GetFrameTime()
		fight_tick(fight, delta_time)
		world_tick(world, delta_time)

		// -- Rendering.
        rl.BeginTextureMode(target_texture)
		rl.ClearBackground(rl.GRAY)

		rl.BeginMode2D(game.camera)
		world_draw(world)
		rl.EndMode2D()

		mouse_pos := window_to_screen(rl.GetMousePosition()) + game.camera.offset
        rl.DrawCircle(i32(mouse_pos.x), i32(mouse_pos.y), 4.0, rl.RED)

        mouse_pos_text := fmt.ctprintf("mouse_pos = (%v, %v)", mouse_pos.x, mouse_pos.y)
        rl.DrawText(mouse_pos_text, RES_X - 128, 0, 8, rl.WHITE)

        render_size_text := fmt.ctprintf("render_size = (%v, %v)", rl.GetRenderWidth(), rl.GetScreenHeight())
        rl.DrawText(render_size_text, RES_X - 128, 8, 8, rl.WHITE)

        screen_size_text := fmt.tprintf("screen_size = (%v, %v)", rl.GetScreenWidth(), rl.GetScreenHeight())
        // rl.DrawText(screen_size_text, RES_X - i32(len(screen_size_text)), 16, 8, rl.WHITE)
        draw_text_aligned(screen_size_text, 8, .Max, .None, { 0, 16 })

		draw_left_panel()
		draw_right_panel()

        rl.EndTextureMode()

        draw_screen(target_texture)
	}
}


draw_left_panel :: proc() {
	rl.DrawRectangleV({ 0, 0 }, { PANEL_SIZE, RES_Y }, rl.BLACK)

	
}


draw_right_panel :: proc() {
	rl.DrawRectangleV({ RES_X - PANEL_SIZE, 0 }, { PANEL_SIZE, RES_Y }, rl.BLACK)
}


Text_Alignment :: enum{
	None,
	Min,
	Max,
	Center,
}

draw_text_aligned :: proc(text: string, size: f32, horizontal: Text_Alignment, vertical: Text_Alignment, offset: Vector2 = { 0, 0, }) {
	c_text := strings.clone_to_cstring(text)
	defer delete(c_text)

	// width := rl.MeasureText(c_text, i32(size))

	spacing: f32 = size

	font := rl.GetFontDefault()
	dim := rl.MeasureTextEx(font, c_text, f32(size), spacing)

	h_offset: f32 = 0.0
	switch horizontal {
	case .None:
	case .Min:
		h_offset = 0
	case .Max:
		h_offset = RES_X - dim.x
	case .Center:
		h_offset = (RES_X / 2.0) - (dim.x / 2.0)
	}

	v_offset: f32 = 0.0
	switch vertical {
	case .None:
	case .Min:
		v_offset = 0
	case .Max:
		v_offset = RES_Y - size
	case .Center:
		v_offset = (RES_Y / 2.0) - (size / 2.0)
	}

	rl.DrawTextEx(
		font,
		c_text,
		{
			h_offset + offset.x,
			v_offset + offset.y,
		},
		size,
		spacing,
		rl.WHITE,
	)
}


window_to_screen :: proc(window_pos: rl.Vector2) -> rl.Vector2 {
	relative_x := window_pos.x / f32(rl.GetRenderWidth())
	relative_y := window_pos.y / f32(rl.GetRenderHeight())

	return { RES_X * relative_x, RES_Y * relative_y, } - game.camera.offset
}


// Draws the given Raylib RenderTexture to the screen, scaling it to fit. 
draw_screen :: proc(target_texture: rl.RenderTexture) {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

    scale := min(f32(rl.GetScreenWidth()) / RES_X, f32(rl.GetScreenHeight()) / RES_Y)
	source_rect := rl.Rectangle{ 
		x = 0,
		y = 0,
		width = f32(target_texture.texture.width),
		height = -f32(target_texture.texture.height),
	}

	dest_rect := rl.Rectangle{
		x = (f32(rl.GetScreenWidth()) - (f32(RES_X) * scale)) * 0.5,
		y = (f32(rl.GetScreenHeight()) - (f32(RES_Y) * scale)) * 0.5,
		width = RES_X * scale,
		height = RES_Y * scale,
	}

	rl.DrawTexturePro(texture = target_texture.texture,
		             source   = source_rect,
		             dest     = dest_rect,
		             origin   = { 0, 0 },
		             rotation = 0,
		             tint     = rl.WHITE)

	rl.EndDrawing()
}
