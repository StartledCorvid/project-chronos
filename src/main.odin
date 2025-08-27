package game
/*
# Overview

*/

import rl "vendor:raylib"


WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

RES_X :: 320
RES_Y :: 180

WINDOW_TITLE :: "Chronos"

TARGET_FPS :: 60

WORLD_UNITS :: 16
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
	arena: Combat_Arena

	character_list := load_characters()
	enemy_list := load_enemies()

	// == Random stuff.
	new_player(&arena, character_list[.Fighter])
	new_enemy(&arena, enemy_list[.Goblin])
	dirt_texture := rl.LoadTexture("res/images/dirt_tile.png")

	// == Game loop.
	for !rl.WindowShouldClose() {
		// -- Input.

		// -- Processing.
		update_combatants(&arena, rl.GetFrameTime())

		// -- Rendering.
        rl.BeginTextureMode(target_texture)
		rl.ClearBackground(rl.GRAY)

		draw_world(dirt_texture)
		draw_combatants(&arena)

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


to_world_units :: proc(grid_position: [2]i32) -> rl.Vector2 {
	return rl.Vector2{
		f32(grid_position.x) * WORLD_UNITS,
		f32(grid_position.y) * WORLD_UNITS,
	}
}


draw_world :: proc(texture: rl.Texture) {
	for x in 0..<WORLD_SIZE {
		for y in 0..<WORLD_SIZE {
			position := to_world_units({ i32(x), i32(y) })
			rl.DrawTextureV(texture, position, rl.WHITE)
		}
	}
}