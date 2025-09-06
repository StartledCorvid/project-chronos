package game
/*
# Overview
Handling of a participant in combat. This includes different prefabs for enemies
(stored in Character_Data).

# Creating a New Character Type
1. Add an entry to the Character_Type enum.
2. Add an entry in the load_character_types procedure below.

# Adding a New Stat Type
1. Add a new entry to the Stat enum.
*/

// import rl "vendor:raylib"


// +-------------------------------------------------------------------------------------+
// |                                    !DEFINITIONS!                                    |
// +-------------------------------------------------------------------------------------+


// A list of the different stats and their values.
Stat_Block :: [Stat]i32


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


// Different types of Characters by name.
Character_Type :: enum {
	Goblin,
	Fighter,
}


// A definition of a specific Character type.
Character_Data :: struct {
	display_name: string,
	description: string,

	stats: Stat_Block,

	animator: Animator,

	on_turn: proc(self: ^Entity, timeline: ^Timeline) -> bool,
}


// Represents an Entity that can move around and can participate in Combat.
Character :: struct {
	hit_points: i32,
	// TODO: Modifiers.
	// TODO: Conditions.
	base: ^Character_Data,
}


// ------------------------------------- !END TYPES! -------------------------------------


// +-------------------------------------------------------------------------------------+
// |                                       !ADMIN!                                       |
// +-------------------------------------------------------------------------------------+


// Loads the different character types into an array.
load_character_types :: proc() -> [Character_Type]Character_Data {
	return {
		.Fighter = {
			display_name = "Fighter",
			description = "A fighter, not a lover.",
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
			on_turn = player_turn,
		},

		.Goblin = {
			display_name = "Goblin",
			description = "A lover, not a fighter.",
			stats = {
				.Speed     = 4,
				.Strength  = 4,
				.Magic     = 0,
				.Agility   = 6,
				.Toughness = 1,
			},
			// animator = setup_character_animator(.Goblin, { 1, 1 }),
			animator = basic_character_animator({
				atlas = new_texture_atlas(.Goblin, { 1, 1 }),
				starting_frame = 0,
				ending_frame = 0,
				fps = 1,
				loop_count = -1,
			}),
			on_turn = turn_aggressive,
		},
	}
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

	return handle
}


// ---------------------------------- !END OPERATIONS! -----------------------------------


// +-------------------------------------------------------------------------------------+
// |                                    !ACTIONS!                                        |
// +-------------------------------------------------------------------------------------+


// Gets the maximum amount of HP that a Stat_Block allows for.
get_max_hp :: proc(stats: Stat_Block) -> i32 {
	return max(1, stats[.Toughness])
}


// Damages the given Character, killing it if its health reaches 0.
damage_character :: proc(handle: Entity_Handle, damage: i32, loc := #caller_location) {
	entity := get_entity(handle, loc)
	character, ok := &entity.type.(Character)
	if !ok {
		return
	}
	character.hit_points = max(0, character.hit_points - damage)

	if character.hit_points <= 0 {
		kill_combatant(handle)
	}
}


kill_combatant :: proc(handle: Entity_Handle, loc := #caller_location) {
	free_entity(handle, loc)
}


// ------------------------------------ !END ACTIONS! ------------------------------------
