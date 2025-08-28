package game
/*
# Overview
Handles Player Combatants.
*/


// +---------------------------------------------------------------------------+
// |                                  !TYPES!                                  |
// +---------------------------------------------------------------------------+


// The player's Combatant.
Player :: struct {
	character: Player_Character,
}


// -------------------------------- !END TYPES! --------------------------------


// +---------------------------------------------------------------------------+
// |                                   !PLAYER!                                |
// +---------------------------------------------------------------------------+


// Creates a new player in the arena. Use free_combatant to free it.
new_player :: proc(world: ^World, character: Player_Character, loc := #caller_location) -> Combatant_Handle {
	assert(world != nil, "Nil World pointer.", loc)

	player_handle := new_combatant(world, loc)
	player := get_combatant(player_handle)

	player.hit_points = get_max_hp(character.stats)
	player.type = Player{
		character = character,
	}

	// TODO: Temporary. Remove this.
	player.animator.texture = character.icon

	return new_combatant_handle(world, player^)
}


// Does the frame-by-frame processing for the player.
update_player :: proc(player_handle: Combatant_Handle, delta_time: f32) {
	player := get_combatant(player_handle)

	movement := World_Coords{}
	if is_action_pressed(.Move_Down) {
		movement.y = 1
	}
	if is_action_pressed(.Move_Up) {
		movement.y = -1
	}
	if is_action_pressed(.Move_Right) {
		movement.x = 1
	}
	if is_action_pressed(.Move_Left) {
		movement.x = -1
	}

	next_pos := player.position + movement
	if space_empty(player_handle.world, next_pos) {
		player.position = next_pos
	}

	player.position.x = clamp(player.position.x, 0, WORLD_SIZE - 1)
	player.position.y = clamp(player.position.y, 0, WORLD_SIZE - 1)
}


// -------------------------------- !END PLAYER! -------------------------------