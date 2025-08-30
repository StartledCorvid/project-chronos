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
	action := query_player_input(self)
	if valid_event(action) {
		add_event(timeline, action)
		return true
	}
	return false
}



query_player_input :: proc(self: ^Entity) -> Event {
	if move_action := query_player_move(self); valid_event(move_action) {
		return move_action
	}

	return INVALID_EVENT
}


query_player_move :: proc(self: ^Entity) -> Event {
	player_handle := new_entity_handle(game.current_world, self^)
	if is_action_pressed(.Move_Down) {
		return event_entity_move(player_handle, .Down)
	} else if is_action_pressed(.Move_Up) {
		return event_entity_move(player_handle, .Up)
	} else if is_action_pressed(.Move_Right) {
		return event_entity_move(player_handle, .Right)
	} else if is_action_pressed(.Move_Left) {
		return event_entity_move(player_handle, .Left)
	}

	return INVALID_EVENT
}


// ------------------------------------- !END PLAYER! ------------------------------------
