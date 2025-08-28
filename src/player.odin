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

	if !player_handle.world.turn_manager.player_turn {
		return
	}

	action := player_turn(player_handle)
	if is_action_valid(action) {
		do_action(&player_handle.world.turn_manager, action)
		player_handle.world.turn_manager.player_turn = false
	}
}


player_turn :: proc(player_handle: Combatant_Handle) -> Action {
	if move_action := query_player_move(player_handle); is_action_valid(move_action) {
		return move_action
	}

	return create_empty_action()
}


query_player_move :: proc(player_handle: Combatant_Handle) -> Action {
	if is_action_pressed(.Move_Down) {
		action := create_action(player_handle)
		action.type = Move_Action{
			direction = .Down,
			distance = 1,
		}
		return action
	} else if is_action_pressed(.Move_Up) {
		action := create_action(player_handle)
		action.type = Move_Action{
			direction = .Up,
			distance = 1,
		}
		return action
	} else if is_action_pressed(.Move_Right) {
		action := create_action(player_handle)
		action.type = Move_Action{
			direction = .Right,
			distance = 1,
		}
		return action
	} else if is_action_pressed(.Move_Left) {
		action := create_action(player_handle)
		action.type = Move_Action{
			direction = .Left,
			distance = 1,
		}
		return action
	}

	return create_empty_action()
}


// -------------------------------- !END PLAYER! -------------------------------