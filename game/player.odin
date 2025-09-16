package game

import rl "vendor:raylib"
import "core:fmt"


/*
# Overview
Mainly handles the management of the Player's turn.
*/


// +-------------------------------------------------------------------------------------+
// |                                     !PLAYER!                                        |
// +-------------------------------------------------------------------------------------+


// Called every tick that it is the Player's turn.
player_turn :: proc(self: ^Entity, timeline: ^Timeline) -> bool {
	handle := new_entity_handle(&game.current_world, self^)

	// Movement.
	if move_action := query_player_move(self); valid_event(move_action) {
		add_event(timeline, move_action)
		return true
	}

	// Attacks.
	if direction, pressed := query_player_attack(); pressed {
		add_event(timeline, event_lunge(handle, direction, 0.5, 0.15))
		add_event(timeline, event_basic_attack(handle, direction, 1)) // TODO: Handle variant damage.
		return true
	}

	return false
}


// Checks if the player is inputting a move action.
@(private="file")
query_player_move :: proc(self: ^Entity) -> Event {
	free_directions := get_free_directions(self.position)
	handle := new_entity_handle(&game.current_world, self^)

	if is_action_pressed(.Move_Down) && .Down in free_directions {
		return event_entity_move(handle, .Down)
	} else if is_action_pressed(.Move_Up) && .Up in free_directions {
		return event_entity_move(handle, .Up)
	} else if is_action_pressed(.Move_Right) && .Right in free_directions {
		return event_entity_move(handle, .Right)
	} else if is_action_pressed(.Move_Left) && .Left in free_directions {
		return event_entity_move(handle, .Left)
	}

	return INVALID_EVENT
}


// Checks if the player is inputting an attack action.
@(private="file")
query_player_attack :: proc() -> (Direction, bool) {
	if is_action_pressed(.Attack_Down) {
		return .Down, true
	} else if is_action_pressed(.Attack_Up) {
		return .Up, true
	} else if is_action_pressed(.Attack_Right) {
		return .Right, true
	} else if is_action_pressed(.Attack_Left) {
		return .Left, true
	}

	return .Down, false
}


// ------------------------------------- !END PLAYER! ------------------------------------


// +-------------------------------------------------------------------------------------+
// |                                       !UI!                                          |
// +-------------------------------------------------------------------------------------+


// Draws the user interface for the player info.
draw_player_ui :: proc(handle: Entity_Handle, loc := #caller_location) {
	player := get_entity(handle)
	character, ok := player.type.(Character)
	assert(ok, "Entity is not a Character.", loc)

	health_bar_dim := Vector2{ 16, 8 }
	current_health := f32(character.hit_points)
	max_health := f32(get_max_hp(character.base.stats))

	ui_draw_bar({ 0, 0 }, health_bar_dim, current_health / max_health, rl.RED, rl.BLACK)

	health_text := fmt.ctprintf("%v/%v", current_health, max_health)
	rl.DrawText(health_text, i32(health_bar_dim.x), 0, 8, rl.RED)
}


// ------------------------------------- !END UI! ----------------------------------------


ui_draw_bar :: proc(position: Vector2, dimensions: Vector2, fill: f32, fill_color: rl.Color, background_color: rl.Color) {
	rl.DrawRectangleV(position, dimensions, background_color)

	fill_width := dimensions.x * fill
	rl.DrawRectangleV(position, { fill_width, dimensions.y }, fill_color)
}