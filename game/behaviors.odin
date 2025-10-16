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
		timeline_add(timeline, event_entity_move(handle, move_direction, MOVE_TIME, handle))
	} else if !not_empty {
		handle := new_entity_handle(&game.current_world, self^)
		sequence_lunge(timeline, handle, move_direction, LUNGE_TIME)
	}

	return true
}


// Chases down the Player and attacks if in range.
turn_aggressive :: proc(self: ^Entity, timeline: ^Timeline) -> bool {
	character, ok := to_character(self)
	assert(ok, "Not a Character.")

	// If no player, do mothing.
	if !entity_handle_valid(game.player_data.entity) {
		return true
	}

	self_handle := new_entity_handle(&game.current_world, self^)

	// Attack if Player is in adjacent.
	player := get_entity(game.player_data.entity)
	if dir, adjacent := is_adjacent(self.position, player.position); adjacent {
		damage := get_melee_damage(character.base.stats)
		sequence_melee(timeline, self_handle, dir, damage, character.base.base_damage_type, LUNGE_TIME)
		return true
	}

	// Move towards player.
	free_directions := get_free_directions(self.position)
	if free_directions != {} {
		move_direction := get_closest_direction_to_target(self.position, player.position, free_directions)
		timeline_add(timeline, event_entity_move(self_handle, move_direction, MOVE_TIME, self_handle))
		return true
	} else { // Cannot move. Do a little stuck animation.
		sequence_lunge(timeline, self_handle, rand.choice_enum(Direction), LUNGE_TIME)
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


ai_only_use_if_no_melee :: proc(self: Ability_Slot, user: Entity) -> bool {
    // Don't use if not cooled down.
    if !ability_slot_cooled(self) {
        return false
    }

    // Don't use if a melee is available.
    player :=  get_entity(game.player_data.entity)
    for direction in DIRECTIONS {
        test_position := user.position + direction
        if player.position == test_position {
            return false
        }
    }

    return true
}


square_distance :: proc(a, b: World_Coords) -> f32 {
	x := f32(a.x - b.x)
	y := f32(a.y - b.y)
	return (x * x) + (y * y)
}