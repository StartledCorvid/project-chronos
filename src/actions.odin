package game
/*
# Overview
Handles Combatant Actions.

# Adding New Action Types
1. Create a struct type for the Action's data.
2. Add the struct to the Action_Type union.
3. Add a handler to the do_action proc. This will usually call a different proc.
*/


Action_Type :: union {
	Move_Action,	
}



Move_Action :: struct {
	direction: Direction,
	distance: u32,
}


Action :: struct {
	target: Combatant_Handle,
	type: Action_Type,
}



// Manages keeping track of turns.
Turn_Manager :: struct {
	player_turn: bool,
	turn_time: f32,

	actions: [dynamic]Action,
}


create_action :: proc(handle: Combatant_Handle, loc := #caller_location) -> Action {
	assert(is_combatant_handle_valid(handle), "Invalid Combatant_Handle.", loc)
	return {
		target = handle,
	}
}


create_empty_action :: proc() -> Action {
	return {}
}


is_action_valid :: proc(action: Action) -> bool {
	return action.type != nil && is_combatant_handle_valid(action.target)
}


do_action :: proc(manager: ^Turn_Manager, action: Action) {
	// TODO: Combatants have queues for future turns?

	switch type in action.type {
	case Move_Action:
		data := action.type.(Move_Action)
		move_combatant(action.target, data.direction, data.distance)
	}

	append(&manager.actions, action)
}