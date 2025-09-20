package game

import "core:log"
import "core:os"
import "core:mem"
import rl "vendor:raylib"


/*
# Overview

*/


WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

RENDER_WIDTH :: 320
RENDER_HEIGHT :: 180

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
	rl.SetWindowMinSize(RENDER_WIDTH, RENDER_HEIGHT)

	rl.SetConfigFlags({ .VSYNC_HINT })

    target_texture := rl.LoadRenderTexture(RENDER_WIDTH, RENDER_HEIGHT)
    defer rl.UnloadRenderTexture(target_texture)
    rl.SetTextureFilter(target_texture.texture, .POINT)

	// == Game state.
	init_game()
	defer deinit_game()
	
	// == Game loop.
	for !rl.WindowShouldClose() {
		// -- Input.

		// -- Processing.
		tick(&game)

		// -- Rendering.
        rl.BeginTextureMode(target_texture)
		rl.ClearBackground(rl.GRAY)

		rl.BeginMode2D(game.camera)
		draw(&game)

		rl.EndMode2D()
		ui(&game)

        rl.EndTextureMode()

        draw_screen(target_texture)
	}
}


// Draws the given Raylib RenderTexture to the screen, scaling it to fit. 
draw_screen :: proc(target_texture: rl.RenderTexture) {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

    scale := min(f32(rl.GetScreenWidth()) / RENDER_WIDTH, f32(rl.GetScreenHeight()) / RENDER_HEIGHT)
	source_rect := rl.Rectangle{ 
		x = 0,
		y = 0,
		width = f32(target_texture.texture.width),
		height = -f32(target_texture.texture.height),
	}

	dest_rect := rl.Rectangle{
		x = (f32(rl.GetScreenWidth()) - (f32(RENDER_WIDTH) * scale)) * 0.5,
		y = (f32(rl.GetScreenHeight()) - (f32(RENDER_HEIGHT) * scale)) * 0.5,
		width = RENDER_WIDTH * scale,
		height = RENDER_HEIGHT * scale,
	}

	rl.DrawTexturePro(texture = target_texture.texture,
		             source   = source_rect,
		             dest     = dest_rect,
		             origin   = { 0, 0 },
		             rotation = 0,
		             tint     = rl.WHITE)

	rl.EndDrawing()
}
