package game

import "core:math/rand"

/*
# Overview
Defines difference behavior procs for NPCs Characters.
*/


// Bare basic, mostly random enemy behavior.
turn_random_move :: proc(self: ^Entity, timeline: ^Timeline) -> bool {
	free_directions := get_free_directions(self.position)

	if move_direction, not_empty := rand.choice_bit_set(free_directions); not_empty {
		handle := new_entity_handle(&game.current_world, self^)
		add_event(timeline, event_entity_move(handle, move_direction))
	} else if !not_empty {
		handle := new_entity_handle(&game.current_world, self^)
		add_event(timeline, event_lunge(handle, move_direction, 0.1, 0.1))
	}

	return true
}


// Chases down the Player and attacks if in range.
turn_aggressive :: proc(self: ^Entity, timeline: ^Timeline) -> bool {
	// If no player, do mothing.
	if !entity_handle_valid(game.player) {
		return true
	}

	self_handle := new_entity_handle(&game.current_world, self^)

	// Attack if Player is in adjacent.
	player := get_entity(game.player)
	if dir, adjacent := is_adjacent(self.position, player.position); adjacent {
		add_event(timeline, event_lunge(self_handle, dir, 0.5, 0.15))
		add_event(timeline, event_basic_attack(self_handle, dir, 1)) // TODO: Calculate damage better.
		return true
	}

	// Move towards player.
	free_directions := get_free_directions(self.position)
	if free_directions != {} {
		move_direction := get_closest_direction_to_target(self.position, player.position, free_directions)
		add_event(timeline, event_entity_move(self_handle, move_direction))
		return true
	} else { // Cannot move. Do a little stuck animation.
		add_event(timeline, event_lunge(self_handle, rand.choice_enum(Direction), 0.1, 0.1))
		return true
	}

	// Skip turn if nothing else can be done.
	return true
}


is_adjacent :: proc(origin, target: World_Coords) -> (Direction, bool) #optional_ok {
	for direction in Direction {
		direction_pos := origin + DIRECTIONS[direction]
		if direction_pos == target {
			return direction, true
		}
	}
	return .Up, false
}


// Gets which direction to move from the possible directions that will get you closest
// to the target.
get_closest_direction_to_target :: proc(start, target: World_Coords, directions: bit_set[Direction]) -> Direction {
	closest_direction: Direction
	closest_sqr_dist := max(f32)

	for direction in directions {
		direction_pos := start + DIRECTIONS[direction]
		sqr_dist := square_distance(direction_pos, target)

		if sqr_dist < closest_sqr_dist {
			closest_direction = direction
			closest_sqr_dist = sqr_dist
		}
	}

	return closest_direction
}


square_distance :: proc(a, b: World_Coords) -> f32 {
	x := f32(a.x - b.x)
	y := f32(a.y - b.y)
	return (x * x) + (y * y)
}