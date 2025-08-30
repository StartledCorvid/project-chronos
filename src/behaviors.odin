package game
/*
# Overview
Defines difference behavior procs for NPCs Characters.
*/

import "core:math/rand"


// Bare basic, mostly random enemy behavior.
turn_random_move :: proc(self: ^Entity, timeline: ^Timeline) -> bool {
	free_directions: bit_set[Direction]
	for direction in Direction {
		potential_position := self.position + directions[direction]
		is_free := world_space_empty(game.current_world, potential_position)

		if is_free do free_directions += { direction }
	}

	if move_direction, not_empty := rand.choice_bit_set(free_directions); not_empty {
		handle := new_entity_handle(game.current_world, self^)
		add_event(timeline, event_entity_move(handle, move_direction))
	}

	return true
}
