package game
/*
# Overview
Handles Player Entities.
*/

import "core:log"


// +-------------------------------------------------------------------------------------+
// |                                      !TYPES!                                        |
// +-------------------------------------------------------------------------------------+


// The player's Entity.
Player :: struct {
	character: Player_Character,
	timeline: Timeline,
}


// ------------------------------------- !END TYPES! -------------------------------------


// +-------------------------------------------------------------------------------------+
// |                                     !PLAYER!                                        |
// +-------------------------------------------------------------------------------------+


// Creates a new player `Entity` in the `World`. Use `free_entity` to free it.
new_player :: proc(world: ^World, character: Player_Character, loc := #caller_location) -> Entity_Handle {
	assert(world != nil, "Nil World pointer.", loc)

	entity_handle := new_entity(world, loc)
	entity := get_entity(entity_handle)

	entity.flags += { .Hittable, .Solid }
	entity.hit_points = get_max_hp(character.stats)

	entity.type = Player{
		character = character,
	}

	// TODO: Temporary. Remove this.
	entity.animator.texture = character.icon

	return entity_handle
}


// Called when a processing tick passes.
player_tick :: proc(entity_handle: Entity_Handle, delta_time: f32) {
	entity := get_entity(entity_handle)
	player := &entity.type.(Player)

	// TODO: Testing only. Remove -->
	if is_action_pressed(.Attack_Right) {
		event := Event{
			owner = entity_handle,
			flags = { .Blocks },
			on_tick = proc(event: ^Event, delta_time: f32) {
				if event.time > 10 {
					entity_move(event.owner, .Right)
					event.flags -= { .Playing }
				}
			},
		}

		append(&player.timeline.events, event)
	}
	// <--

	// Always executed.
	timeline_tick(&player.timeline, delta_time)
	blocked := player.timeline.current_event != nil ? .Blocks in player.timeline.current_event.flags : false

	// Only executed on turn.
	// if game.turn_manager.current_phase != .Player_Turn || blocked {
	if blocked {
		return
	}

	action := player_turn(entity_handle)
	if is_action_valid(action) {
		do_action(action)
	}
}



player_turn :: proc(player_handle: Entity_Handle) -> Action {
	if move_action := query_player_move(player_handle); is_action_valid(move_action) {
		return move_action
	}

	return create_empty_action()
}


query_player_move :: proc(player_handle: Entity_Handle) -> Action {
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


// ------------------------------------- !END PLAYER! ------------------------------------
