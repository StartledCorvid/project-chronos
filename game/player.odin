package game

import "core:log"
import rl "vendor:raylib"
import "core:fmt"


/*
# Overview
Mainly handles the management of the Player's turn.
*/



// Data for the player Character.
Player_Data :: struct {
	entity: Entity_Handle,
	character_type: Character_Type,
	inventory: Inventory,
}


// Initializes the given Player_Data object. Note that for a clean init, call
// `reset_player_data` first.
init_player_data :: proc(player_data: ^Player_Data, character_type: Character_Type, loc := #caller_location) {
	assert(player_data != nil, "Nil Player_Data pointer.", loc)
	player_data.character_type = character_type
}


// Resets the player data.
reset_player_data :: proc(player_data: ^Player_Data, loc := #caller_location) {
	assert(player_data != nil, "Nil Player_Data pointer.", loc)

	player_data.entity = INVALID_ENTITY_HANDLE

	inventory_deinit(&player_data.inventory, loc)
}


// Spawns an Entity in the game world using the Player_Data passed. If an existing
// player Character exists, gets rid of it first.
spawn_player :: proc(player_data: ^Player_Data, position: World_Coords = { 0, 0 }, loc := #caller_location) -> Entity_Handle {
	assert(player_data != nil, "Nil Player_Data pointer.", loc)

	existing_health := -1

	// Destroy existing player Character.
	if existing_entity, exists := get_entity(player_data.entity); exists {
		character := get_character_from_entity(existing_entity, loc)
		existing_health = character.hit_points

		free_entity(player_data.entity)
	}

	player_data.entity = new_character(&game.current_world, player_data.character_type)

	player_entity    := get_entity(player_data.entity)
	player_character := get_character_from_entity(player_entity)

	// Existing health should carry over.
	if existing_health <= 0 {
		player_character.hit_points = existing_health
	}

	player_entity.position = position

	return player_data.entity
}


// +-------------------------------------------------------------------------------------+
// |                                     !PLAYER!                                        |
// +-------------------------------------------------------------------------------------+


// Called every tick that it is the Player's turn.
turn_tick_player :: proc(self: ^Entity, timeline: ^Timeline) -> bool {
	handle := new_entity_handle(&game.current_world, self^)
	character, character_ok := to_character(self)
	assert(character_ok, "Not a Character.")

	// If there is a queued ability, focus on that.
	if character.queued_ability_slot != nil {
		return query_confirm_ability(character.queued_ability_slot, self)
	}

	// Movement.
	if move_action := query_player_move(self); move_action != nil {
		timeline_add(timeline, move_action.?)
		return true
	}

	// Attacks.
	if direction, pressed := query_player_attack(); pressed {
		damage := get_melee_damage(character.base.stats)
		sequence_melee(timeline, handle, direction, damage, character.base.base_damage_type, LUNGE_TIME)
		return true
	}

	// Abilities.
	query_player_ability(character)

	return false
}


// Checks if an Entity is the current player Entity.
is_player :: proc{
	is_player_handle,
	is_player_entity,
}


// Checks if the given Entity_Handle points to the player.
is_player_handle :: proc(entity_handle: Entity_Handle) -> bool {
	return entity_handle_valid(entity_handle) && entity_handle.id == game.player_data.entity.id && entity_handle.generation == game.player_data.entity.generation
}


// Checks if the given Entity is the player.
is_player_entity :: proc(entity: Entity) -> bool {
	return .Valid in entity.flags && entity.id == game.player_data.entity.id && entity._generation == game.player_data.entity.generation
}


@(private="file")
query_confirm_ability :: proc(ability_slot: ^Ability_Slot, entity: ^Entity) -> bool {
	character := to_character(entity)
	if ability_slot == nil || !ability_slot_valid(ability_slot^) || is_action_pressed(.Cancel_Ability) {
		// TODO: Display message or something.
		character.queued_ability_slot = nil
		return false
	}

	// Swap ability.
	if ability_slot == &character.ability_slots[0] && is_action_pressed(.Ability_B) {
		character.queued_ability_slot = &character.ability_slots[1]
		return false
	} else if ability_slot == &character.ability_slots[1] && is_action_pressed(.Ability_A) {
		character.queued_ability_slot = &character.ability_slots[0]
		return false
	}

	// Check for confirmation.
	confirmation: Ability_Confirmation

	ability_info := get_ability_info(ability_slot.ability)
	switch ability_info.confirmation_type {
	case Direction:
		if is_action_pressed(.Attack_Down) || is_action_pressed(.Move_Down) {
			confirmation = Direction.Down
		} else if is_action_pressed(.Attack_Up) || is_action_pressed(.Move_Up) {
			confirmation = Direction.Up
		} else if is_action_pressed(.Attack_Left) || is_action_pressed(.Move_Left) {
			confirmation = Direction.Left
		} else if is_action_pressed(.Attack_Right) || is_action_pressed(.Move_Right) {
			confirmation = Direction.Right
		}

	case bool:
		if ability_slot == &character.ability_slots[0] && is_action_pressed(.Ability_A) {
			confirmation = true
		} else if ability_slot == &character.ability_slots[1] && is_action_pressed(.Ability_B) {
			confirmation = true
		}

	case:
		panicf("Unrecognized Confirmation_Type '%v' given to Ability_Info '%v'",
			ability_info.confirmation_type, ability_info.name)
	}

	if confirmation != nil {
		log.infof("Confirmed ability '%v'.", ability_info.name)
		use_ability(ability_slot, entity, confirmation)
		character.queued_ability_slot = nil
		return true
	}

	return false
}


// Checks if the player is inputting a move action.
@(private="file")
query_player_move :: proc(self: ^Entity) -> Maybe(Event) {
	free_directions := get_free_directions(self.position)
	handle := new_entity_handle(&game.current_world, self^)

	if is_action_pressed(.Move_Down) && .Down in free_directions {
		return event_entity_move(handle, .Down, MOVE_TIME, handle)
	} else if is_action_pressed(.Move_Up) && .Up in free_directions {
		return event_entity_move(handle, .Up, MOVE_TIME, handle)
	} else if is_action_pressed(.Move_Right) && .Right in free_directions {
		return event_entity_move(handle, .Right, MOVE_TIME, handle)
	} else if is_action_pressed(.Move_Left) && .Left in free_directions {
		return event_entity_move(handle, .Left, MOVE_TIME, handle)
	}

	return nil
}


// Checks if the player is inputting an attack action.
@(private="file")
query_player_attack :: proc() -> (Direction, bool) {
	if is_action_pressed(.Attack_Down) {
		return .Down, true
	} else if is_action_pressed(.Attack_Up) {
		return .Up, true
	} else if is_action_pressed(.Attack_Right) {
		return .Right, true
	} else if is_action_pressed(.Attack_Left) {
		return .Left, true
	}

	return .Down, false
}


// Checks if the player is inputting an Ability.
@(private="file")
query_player_ability :: proc(character: ^Character) {
	if is_action_pressed(.Ability_A) && ability_slot_cooled(character.ability_slots[0]) {
		character.queued_ability_slot = &character.ability_slots[0]
		log.infof("Queued ability %v.", character.base.abilities[0])
	}

	if is_action_pressed(.Ability_B) && ability_slot_cooled(character.ability_slots[1]) {
		character.queued_ability_slot = &character.ability_slots[1]
		log.infof("Queued ability %v.", character.base.abilities[1])
	}
}


// ------------------------------------- !END PLAYER! ------------------------------------


// +-------------------------------------------------------------------------------------+
// |                                       !UI!                                          |
// +-------------------------------------------------------------------------------------+


// Draws the user interface for the player info.
ui_player :: proc(handle: Entity_Handle, loc := #caller_location) {
	character, ok := to_character(handle, loc)
	assert(ok, "Entity is not a Character.", loc)

	gear_offset: Vector2

	// Health bar.
	health_bar_pos := Vector2{ gear_offset.x + 4, 2 }
	health_bar_dim := Vector2{ 16, 8 }
	current_health := f32(character.hit_points)
	max_health := f32(get_max_hp(character.base.stats))

	ui_draw_bar(health_bar_pos, health_bar_dim, current_health / max_health, rl.RED, rl.BLACK)

	health_text := fmt.ctprintf("%v/%v", current_health, max_health)
	rl.DrawText(health_text, i32(health_bar_dim.x + health_bar_pos.x + 2), 2, 8, rl.RED)

	// Relics
	ui_item_list(character.inventory, { 2, 10 }, 5)

	// Ability slots.
	if character.ability_slots[0].ability != .None {
		prompt := input_cstring(.Ability_A)
		rl.DrawText(prompt, 2, RENDER_HEIGHT - 30, 8, rl.WHITE)
		ui_draw_ability_slot(character.ability_slots[0], { 2, RENDER_HEIGHT - 20 })
	}

	if character.ability_slots[1].ability != .None {
		prompt := input_cstring(.Ability_B)
		rl.DrawText(prompt, 22, RENDER_HEIGHT - 30, 8, rl.WHITE)
		ui_draw_ability_slot(character.ability_slots[1], { 22, RENDER_HEIGHT - 20 })
	}
}


// ------------------------------------- !END UI! ----------------------------------------


ui_draw_bar :: proc(position: Vector2, dimensions: Vector2, fill: f32, fill_color: rl.Color, background_color: rl.Color) {
	rl.DrawRectangleV(position, dimensions, background_color)

	fill_width := dimensions.x * fill
	rl.DrawRectangleV(position, { fill_width, dimensions.y }, fill_color)
}