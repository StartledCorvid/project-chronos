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
	// TOOD: Check if it is the player's turn. Maybe make wait_for_player_turn?

	// action := create_action(player_handle)

	if is_action_pressed(.Move_Down) do move_combatant(player_handle, .Down)
	else if is_action_pressed(.Move_Up) do move_combatant(player_handle, .Up)
	else if is_action_pressed(.Move_Right) do move_combatant(player_handle, .Right)
	else if is_action_pressed(.Move_Left) do move_combatant(player_handle, .Left)
}


// -------------------------------- !END PLAYER! -------------------------------