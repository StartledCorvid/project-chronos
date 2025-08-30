package game
/*
# Overview
Defines difference behavior procs for NPCs Characters.
*/

import "core:math/rand"


// Bare basic, mostly random enemy behavior.
turn_random_move :: proc(self: ^Entity, timeline: ^Timeline) -> bool {
	direction := rand.choice_enum(Direction)

	handle := new_entity_handle(game.current_world, self^)
	add_event(timeline, event_entity_move(handle, direction))
	return true
}
