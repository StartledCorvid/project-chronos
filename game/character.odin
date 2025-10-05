package game

import "core:log"
import rl "vendor:raylib"


/*
# Overview
Handling of a participant in combat. This includes different prefabs for enemies
(stored in Character_Data).

# Creating a New Character Type
1. Add an entry to the Character_Type enum.
2. Add an entry in the load_character_types procedure below.


# Creating a New Player Character Type
1. Do that above to create a new character type.
2. Add the type's Character_Type enum entry to the PLAYER_CHARACTERS array.

# Adding a New Stat Type
1. Add a new entry to the Stat enum.
*/


// +-------------------------------------------------------------------------------------+
// |                                    !DEFINITIONS!                                    |
// +-------------------------------------------------------------------------------------+


// A list of the different stats and their values.
Stat_Block :: [Stat]int


MOVE_TIME  :: 0.25
LUNGE_TIME :: 0.25
LUNGE_DISTANCE :: 0.5


// ---------------------------------- !END DEFINITIONS! ----------------------------------


// +-------------------------------------------------------------------------------------+
// |                                      !TYPES!                                        |
// +-------------------------------------------------------------------------------------+


// The different stats of a Combatant.
Stat :: enum {
	Speed,
	Strength,
	Magic,
	Agility,
	Toughness,
}


// A modifier to a value using a Stat.
Modifier :: struct {
	stat: Stat,
	multiplier: f32,
}


// Different types of Characters by name.
Character_Type :: enum {
	Fighter,
	Wizard,

	Goblin,
	Spider,
	Minotaur,
}


// A list of Character_Types that the player can play as.
@(rodata)
PLAYER_CHARACTERS := [?]Character_Type{
	.Fighter,
	.Wizard,
}


// A definition of a specific Character type.
Character_Data :: struct {
	display_name: string,
	description: string,
	icon: Texture_Name,

	stats: Stat_Block,

	animator: Animator,

	on_turn: proc(self: ^Entity, timeline: ^Timeline) -> bool,

	abilities: [2]Ability_Name,
	default_items: []Item_Name,
}


// Represents an Entity that can move around and can participate in Combat.
Character :: struct {
	hit_points: int,
	base: ^Character_Data,

	ability_slots: [2]Ability_Slot,
	queued_ability_slot: ^Ability_Slot,
	// TODO: Modifiers.
	// TODO: Conditions.

	inventory: Inventory, 
}


// ------------------------------------- !END TYPES! -------------------------------------


// Takes a Stat_Block and gets a value from a modifier of it.
modifier_value :: proc(stat_block: Stat_Block, modifier: Modifier) -> f32 {
	return f32(stat_block[modifier.stat]) * modifier.multiplier
}


// +-------------------------------------------------------------------------------------+
// |                                       !ADMIN!                                       |
// +-------------------------------------------------------------------------------------+


// Loads the different character types into an array.
load_character_types :: proc() -> [Character_Type]Character_Data {
	defer log.infof("Loaded %v Character Types.", len(Character_Type))
	return {
		.Fighter = {
			display_name = "Fighter",
			description = "A fighter, not a lover.",
			icon = .Icon_Fighter,
			stats = {
				.Speed     = 10,
				.Strength  = 12,
				.Magic     = 0,
				.Agility   = 8,
				.Toughness = 12,
			},
			animator = basic_character_animator({
				atlas = new_texture_atlas(.Fighter, { 1, 1 }),
				starting_frame = 0,
				ending_frame = 0,
				fps = 1,
				loop_count = -1,
			}),
			on_turn = turn_tick_player,

			abilities = { .Bash, .Push_Burst },

			default_items = { .Mighty_Shield },
		},

		.Wizard = {
			display_name = "Wizard",
			description = "Fireball.",
			icon = .Icon_Wizard,
			stats = {
				.Speed     = 6,
				.Strength  = 2,
				.Magic     = 10,
				.Agility   = 5,
				.Toughness = 4,
			},
			animator = basic_character_animator({
				atlas = new_texture_atlas(.Wizard, { 1, 1 }),
				starting_frame = 0,
				ending_frame = 0,
				fps = 1,
				loop_count = -1,
			}),
			on_turn = turn_tick_player,

			abilities = { .Fireball, .None },
			default_items = { .Wizards_Orb },
		},

		.Goblin = {
			display_name = "Goblin",
			description = "A lover, not a fighter.",
			icon = .Icon_Goblin,
			stats = {
				.Speed     = 1,
				.Strength  = 1,
				.Magic     = 0,
				.Agility   = 6,
				.Toughness = 1,
			},
			animator = basic_character_animator({
				atlas = new_texture_atlas(.Goblin, { 1, 1 }),
				starting_frame = 0,
				ending_frame = 0,
				fps = 1,
				loop_count = -1,
			}),
			on_turn = turn_aggressive,
		},

		.Spider = {
			display_name = "Spider",
			description = "Creppy.",
			icon = .Icon_Spider,
			stats = {
				.Speed     = 8,
				.Strength  = 2,
				.Magic     = 0,
				.Agility   = 8,
				.Toughness = 2,
			},
			animator = basic_character_animator({
				atlas = new_texture_atlas(.Spider, { 1, 1 }),
				starting_frame = 0,
				ending_frame = 0,
				fps = 1,
				loop_count = -1,
			}),
			on_turn = turn_aggressive,
		},

		.Minotaur = {
			display_name = "Minotaur",
			description = "Bull.",
			icon = .Icon_Minotaur,
			stats = {
				.Speed     = 7,
				.Strength  = 10,
				.Magic     = 0,
				.Agility   = 4,
				.Toughness = 8,
			},
			animator = basic_character_animator({
				atlas = new_texture_atlas(.Minotaur, { 1, 1 }),
				starting_frame = 0,
				ending_frame = 0,
				fps = 1,
				loop_count = -1,
			}),
			on_turn = turn_aggressive,

			abilities = { .Bash, .None },
		},
	}
}


character_deinit :: proc(character: ^Character, loc := #caller_location) {
	assert(character != nil, "Nil Character pointer.", loc)
	inventory_deinit(&character.inventory)
}


// ------------------------------------- !END ADMIN! -------------------------------------


// +-------------------------------------------------------------------------------------+
// |                                    !OPERATIONS!                                     |
// +-------------------------------------------------------------------------------------+


// Creates an `Animator` instance for a generic Character Entity.
basic_character_animator :: proc(idle_animation: Animation) -> Animator {
	return Animator{
		current_animation = idle_animation,
		play = true,

		_t = 0,
	}
}


// Creates a new enemy `Entity` Character of the given type in the `World`.
// Use `free_entity` to free it.
new_character :: proc(world: ^World, character_type: Character_Type, allocator := context.allocator, loc := #caller_location) -> Entity_Handle {
	assert(world != nil, "Nil World pointer.", loc)

	base := &game.character_types[character_type]

	handle := new_entity(world, loc)
	entity := get_entity(handle)

	entity.flags += { .Solid, .Hittable }
	entity.type = Character{
		base = base,
		hit_points = get_max_hp(base.stats),
	}
	entity.animator = base.animator

	character, ok := to_character(entity)
	assert(ok, "Not a Character.", loc)
	
	for ability_name, index in base.abilities {
		character.ability_slots[index] = {
			ability = ability_name,
			cooldown = 0,
		}
	}

	return handle
}


// Checks if the given Entity is a Character.
is_character :: proc{
	is_entity_character,
	is_handle_character,
}


// Returns true if the given Entity pointer is a Character Entity.
is_entity_character :: proc(entity: ^Entity, loc := #caller_location) -> bool {
	assert(entity != nil, "Nil Entity pointer.", loc)

	_, ok := entity.type.(Character)
	return ok
}


// Returns true if the given Entity_Handle points to a Character Entity.
is_handle_character :: proc(handle: Entity_Handle) -> bool {
	entity := get_entity(handle)
	return is_entity_character(entity)
}


// Safely gets a Character pointer from Entities.
to_character :: proc{
	get_character_from_entity,
	get_character_from_handle,
}


// Gets a Character pointer from an Entity pointer. Handles the safe conversion. Returns
// nil and false if the conversion was not successful.
get_character_from_entity :: proc(entity: ^Entity, loc := #caller_location) -> (^Character, bool) #optional_ok {
	assert(entity != nil, "Nil Entity pointer.", loc)

	character, ok := &entity.type.(Character)
	if !ok {
		return nil, false
	}

	return character, true
}


// Gets a Character pointer from an Entity_Handle. Handles the safe conversion. Returns
// nil and false if the conversion was not successful.
get_character_from_handle :: proc(entity_handle: Entity_Handle, loc := #caller_location) -> (^Character, bool) #optional_ok {
	entity, ok := get_entity(entity_handle)
	if !ok {
		return nil, false
	}

	return get_character_from_entity(entity, loc)
}


// Converts a Character pointer to a pointer to the Entity it is a part of. If the Character
// is not part of an Entity, bad things will happen.
character_to_entity :: proc(character: ^Character, loc := #caller_location) -> ^Entity {
	assert(character != nil, "Nil Character pointer.", loc)

	offset := offset_of(Entity, type)
	entity := (^Entity)(uintptr(character) - uintptr(offset))
	return entity
}


// ---------------------------------- !END OPERATIONS! -----------------------------------


// +-------------------------------------------------------------------------------------+
// |                                     !ENGINE!                                        |
// +-------------------------------------------------------------------------------------+


// Handle special ticks for a Character Entity.
tick_character :: proc(self: ^Entity, character: ^Character) {

}


// Handles special drawing calls for a Character Entity.
draw_character :: proc(self: ^Entity) {
	character := self.type.(Character)

	// Draw the healthbar if the mouse is over the character.
	world_pos := to_vector2(grid_to_world_point(self.position))

    mouse_pos := to_vector2(screen_to_world_point(rl.GetMousePosition()))
    character_box := rl.Rectangle{
        width = WORLD_UNITS,
        height = WORLD_UNITS,
        x = f32(world_pos.x),
        y = f32(world_pos.y),
    }

    if rl.CheckCollisionPointRec(mouse_pos, character_box) {
        start_pos := world_pos
        health_percentage := f32(character.hit_points) / f32(get_max_hp(character.base.stats)) 
        ui_draw_bar(start_pos, { 16, 1 }, health_percentage, rl.RED, rl.BLACK)
    }

    // Draw Ability preview, if selected.
    if character.queued_ability_slot != nil {
    	ability_info := get_ability_info(character.queued_ability_slot.ability)
    	draw_ability_preview(self^, ability_info)
    }
}


// ----------------------------------- !END ENGINE! --------------------------------------


// +-------------------------------------------------------------------------------------+
// |                                    !ACTIONS!                                        |
// +-------------------------------------------------------------------------------------+


// Gets the maximum amount of HP that a Stat_Block allows for.
get_max_hp :: proc(stats: Stat_Block) -> int {
	return max(1, stats[.Toughness])
}


get_melee_damage :: proc(stats: Stat_Block) -> int {
	return max(1, stats[.Strength])
}


// Damages the given Character, killing it if its health reaches 0.
damage_character :: proc(attacker: Maybe(Entity_Handle), target: Entity_Handle, damage: int, loc := #caller_location) {
	entity    := get_entity(target, loc)
	character := to_character(entity)

	attacker_handle := attacker != nil ? attacker.? : Entity_Handle{}

	if attacker_entity, attacker_ok := get_entity(attacker_handle); attacker_ok {
		trigger(&attacker_entity.trigger_hub, {
			trigger	= .On_Hit,
			target = attacker_handle,
			catalyst = attacker_handle,
			timeline = &game.current_fight.timeline,		
		})
	}

	trigger(&entity.trigger_hub, {
		trigger	= .When_Hit,
		target = target,
		catalyst = attacker_handle,
		timeline = &game.current_fight.timeline,
	})

	character.hit_points = max(0, character.hit_points - damage)

	if character.hit_points <= 0 {
		kill_combatant(target)
	}
}


kill_combatant :: proc(handle: Entity_Handle, loc := #caller_location) {
	free_entity(handle, loc)
}


// ------------------------------------ !END ACTIONS! ------------------------------------
