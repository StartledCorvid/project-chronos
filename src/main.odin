package game
/*
import "core:math/rand"
# Overview

*/

import rl "vendor:raylib"


WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

RES_X :: 320
RES_Y :: 180

WINDOW_TITLE :: "Chronos"

TARGET_FPS :: 60

WORLD_SIZE :: 10


main :: proc() {
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
	// TODO: Loading different levels.
	world: World

	character_list := load_characters()
	enemy_list := load_enemies()

	// == Random stuff.
	new_player(&world, character_list[.Fighter])

	enemy := new_enemy(&world, enemy_list[.Goblin])
	for !space_empty(&world, enemy.position) do enemy.position = random_world_point()
	
	dirt_texture := rl.LoadTexture("res/images/dirt_tile.png")

	// == Game loop.
	for !rl.WindowShouldClose() {
		// -- Input.

		// -- Processing.
		update_combatants(&world, rl.GetFrameTime())

		// -- Rendering.
        rl.BeginTextureMode(target_texture)
		rl.ClearBackground(rl.GRAY)

		draw_world(&world, dirt_texture)

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
