package game
/*
import "core:math/rand"
# Overview

*/

import "core:log"
import "core:os"
import rl "vendor:raylib"


WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

RES_X :: 320
RES_Y :: 180

WINDOW_TITLE :: "Chronos"

TARGET_FPS :: 60

WORLD_SIZE :: 10


main :: proc() {
	c_log := log.create_console_logger()
	defer log.destroy_console_logger(c_log)

    log_file, err := os.open("log.txt", os.O_WRONLY | os.O_CREATE | os.O_TRUNC)
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
	defer free_world(world)

	// == Random stuff.
	new_player(world, game.character_types[.Fighter])

	// enemy := new_enemy(world, enemy_list[.Goblin])
	// random_pos := random_world_point()
	// for !space_empty(world, random_pos) do random_pos = random_world_point()
	// enemy.position = random_pos

	game.turn_manager.current_phase = .Player_Turn
	
	// == Game loop.
	for !rl.WindowShouldClose() {
		// -- Input.

		// -- Processing.
		world_tick(world, rl.GetFrameTime())

		// -- Rendering.
        rl.BeginTextureMode(target_texture)
		rl.ClearBackground(rl.GRAY)

		world_draw(world)

        rl.EndTextureMode()

        draw_screen(target_texture)
	}
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
