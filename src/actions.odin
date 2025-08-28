package game
/*
# Overview
Handles Combatant Actions.

# Adding New Action Types
1. Add to the Action_Type enum.
2. Optionally, create a new child struct of Action for unique action data.
3. Define the new action data in the ACTIONS list.
*/


Action_Type :: enum {
	Move,
}


// All of the Actions that can be done.
ACTIONS :: [Action_Type]Action {
	.Move = Move_Action{
		ap_cost = 5,
		direction = 1,
	},
}


// Manages keeping track of turns.
Turn_Manager :: struct {
	player_turn: bool,
	turn_time: f32,

	actions: [dynamic]Action,
}


// An Action that a Combatant can take.
Action :: struct {
	combatant: ^Combatant,
	ap_cost: u32,
}


Move_Action :: struct {
	using action: Action,
	direction: u8,
}


// Executes the given Action.
do_action :: proc(world: ^World, action: Action) {
	switch typeid_of(type_of(action)) {
	case Move_Action:
		
	}
}