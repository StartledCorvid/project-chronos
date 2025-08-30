package game
/*
# Overview
Mainly handles the management of the Player's turn.
*/


// +-------------------------------------------------------------------------------------+
// |                                     !PLAYER!                                        |
// +-------------------------------------------------------------------------------------+


// Called every tick that it is the Player's turn.
player_turn :: proc(self: ^Entity, timeline: ^Timeline) -> bool {
	handle := new_entity_handle(game.current_world, self^)

	// Movement.
	if move_action := query_player_move(handle); valid_event(move_action) {
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
query_player_move :: proc(handle: Entity_Handle) -> Event {
	if is_action_pressed(.Move_Down) {
		return event_entity_move(handle, .Down)
	} else if is_action_pressed(.Move_Up) {
		return event_entity_move(handle, .Up)
	} else if is_action_pressed(.Move_Right) {
		return event_entity_move(handle, .Right)
	} else if is_action_pressed(.Move_Left) {
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
