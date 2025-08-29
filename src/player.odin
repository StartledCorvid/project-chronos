package game
/*
# Overview
Handles Player Entities.
*/


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

	// Always executed.
	timeline_tick(&player.timeline, delta_time)
	blocked := player.timeline.current_event != nil ? .Blocks in player.timeline.current_event.flags : false

	// Only executed on turn.
	if game.turn_manager.current_phase != .Player_Turn || blocked {
		return
	}

	action := player_turn(entity_handle)
	if valid_event(action) {
		add_event(&player.timeline, action)
		next_turn(&game.turn_manager)
	}
}



player_turn :: proc(player_handle: Entity_Handle) -> Event {
	if move_action := query_player_move(player_handle); valid_event(move_action) {
		return move_action
	}

	return INVALID_EVENT
}


query_player_move :: proc(player_handle: Entity_Handle) -> Event {
	valid := false
	event := create_event(player_handle)
	event.action = Action_Move{
		direction = .Down,
		distance = 1,
		time = 0.25,
	}
	action := &event.action.(Action_Move)
	event.flags += { .Blocks }
	event.on_tick = move_action

	if is_action_pressed(.Move_Down) {
		valid = true
		action.direction = .Down
	} else if is_action_pressed(.Move_Up) {
		valid = true
		action.direction = .Up
	} else if is_action_pressed(.Move_Right) {
		valid = true
		action.direction = .Right
	} else if is_action_pressed(.Move_Left) {
		valid = true
		action.direction = .Left
	}

	if valid do return event
	else do return INVALID_EVENT
}


move_action :: proc(e: ^Event, delta_time: f32) {
	move_action := e.action.(Action_Move)
	entity := get_entity(e.owner)
	move_direction := directions[move_action.direction] * i32(move_action.distance)

	if !world_space_empty(e.owner.world, entity.position + move_direction) {
		e.flags -= { . Playing }
		return
	}

	t := e.duration / move_action.time
	target_pos := world_to_screen(move_direction)
	new_pos := lerp(Vector2{ 0, 0 },
		            target_pos,
		            t)

	entity.offset = new_pos
	if e.duration >= move_action.time {
		e.flags -= { .Playing }
		entity.offset = { 0, 0 }
		entity_move(e.owner, move_action.direction, move_action.distance)
	}
}


// ------------------------------------- !END PLAYER! ------------------------------------
