package game
/*
# Overview
Defines difference behavior procs for NPCs Characters.
*/

import "core:math/rand"


// Bare basic, mostly random enemy behavior.
turn_random_move :: proc(self: ^Entity, timeline: ^Timeline) -> bool {
	free_directions := get_free_directions(self.position)

	if move_direction, not_empty := rand.choice_bit_set(free_directions); not_empty {
		handle := new_entity_handle(game.current_world, self^)
		add_event(timeline, event_entity_move(handle, move_direction))
	} else if !not_empty {
		handle := new_entity_handle(game.current_world, self^)
		add_event(timeline, event_lunge(handle, move_direction, 0.1, 0.1))
	}

	return true
}
