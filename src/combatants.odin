package game
/*
import "core:log"
import "core:math/rand"
# Overview
Structure to represent the Combatants in the game. This means the Player and the
enemies.
*/

// import "core:math/rand"
import sa "core:container/small_array"
import "core:log"
import rl "vendor:raylib"


// +---------------------------------------------------------------------------+
// |                               !DEFINITIONS!                               |
// +---------------------------------------------------------------------------+


// The maximum amount of Combatants allowed in the game at one time.
MAX_COMBATANTS :: 5


// A list of the different stats and their values.
Stat_Block :: [Stat]i32


// A handle that references a Combatant instance.
Combatant_Handle :: distinct Handle


// ----------------------------- !END DEFINITIONS! -----------------------------


// +---------------------------------------------------------------------------+
// |                                  !TYPES!                                  |
// +---------------------------------------------------------------------------+


// The different stats of a Combatant.
Stat :: enum {
	Speed,
	Strength,
	Magic,
	Agility,
	Toughness,
}


// The different state flags of a Combatant.
Combatant_Flag :: enum {
	Valid,
	Hittable,
	Solid,
}


// Represents an entity that can move and fight in the world.
Combatant :: struct {
	name: string,
	id: int,
	flags: bit_set[Combatant_Flag],

	animator: Animator,
	type: Combatant_Type,

	// TODO: Stat modifiers.

	hit_points: u32,

	position: World_Coords,

	_active_id: int,
	_generation: int,
}


// A union for the different types of Combatants present in the game.
Combatant_Type :: union {
	Player,
	Enemy,
}


// A foe Combatant for the player to play against.
Enemy :: struct {
	enemy_type: Enemy_Type_Data,
}


Handle :: struct {
	id: int,
	generation: int,

	world: ^World,
}





// -------------------------------- !END TYPES! --------------------------------


// +---------------------------------------------------------------------------+
// |                                   !HANDLE!                                |
// +---------------------------------------------------------------------------+


// Checks if the given handle is valid.
is_combatant_handle_valid :: proc(handle: Combatant_Handle, loc := #caller_location) -> bool {
	if handle.world == nil || handle.id >= MAX_COMBATANTS {
		return false
	}

	combatant := handle.world.combatants[handle.id]
	return combatant._generation == handle.generation && .Valid in combatant.flags
}


// Gets a pointer to the Combatant the handle points to. Returns nil if it does
// not point to a valid Combatant.
get_combatant :: proc(handle: Combatant_Handle, loc := #caller_location) -> ^Combatant {
	is_valid := is_combatant_handle_valid(handle)
	if !is_valid do return nil

	return &handle.world.combatants[handle.id]
}


// Creates a new Combatant_Handle from an instance of a Combatant.
new_combatant_handle :: proc(world: ^World, combatant: Combatant, loc := #caller_location) -> Combatant_Handle {
	assert(world != nil, "Nil World pointer.", loc)
	assert(combatant.id < MAX_COMBATANTS, "Invalid Combatant ID.", loc)

	return {
		id = combatant.id,
		generation = combatant._generation,

		world = world,
	}
}


// -------------------------------- !END HANDLE! -------------------------------


// +---------------------------------------------------------------------------+
// |                                 !COMBATANT!                               |
// +---------------------------------------------------------------------------+


// Gets a new instance of a Combatant.
new_combatant :: proc(world: ^World, loc := #caller_location) -> Combatant_Handle {
	assert(world != nil, "Nil World pointer.", loc)
	
	combatant: ^Combatant = nil
	for &slot, id in world.combatants {
		if .Valid not_in slot.flags {
			combatant = &slot
			combatant.id = id
			break
		}
	}
	assert(combatant != nil, "Couldn't find open slot for new Combatant.", loc)

	combatant.flags = { .Valid, .Solid }

	handle := new_combatant_handle(world, combatant^, loc)

	combatant._active_id = sa.len(world.active_combatants)
	sa.append(&world.active_combatants, handle)

	return handle
}


// Removes the given Combatant from the world.
free_combatant :: proc(handle: Combatant_Handle, loc := #caller_location) {
	combatant := get_combatant(handle, loc)
	assert(combatant != nil, "Got a nil Combatant from Handle.", loc)

	combatant._generation += 1
	combatant.flags -= { .Valid }
	sa.unordered_remove(&handle.world.active_combatants, combatant._active_id)

	if sa.len(handle.world.active_combatants) > 0 {
		moved_handle := sa.get(handle.world.active_combatants, combatant._active_id)
		moved_combatant := get_combatant(moved_handle)
		moved_combatant._active_id = combatant._active_id
	}
}


// ------------------------------- !END COMBATANT! -----------------------------


// +---------------------------------------------------------------------------+
// |                                   !GENERAL!                               |
// +---------------------------------------------------------------------------+


// Gets the maximum amount of HP that a Stat_Block allows for.
get_max_hp :: proc(stats: Stat_Block) -> u32 {
	return u32(max(1, stats[.Toughness]))
}


damage_combatant :: proc(target: Combatant_Handle, damage: u32, loc := #caller_location) {
	combatant := get_combatant(target, loc)
	assert(combatant != nil, "Nil Combatant pointer.", loc)

	combatant.hit_points = max(0, combatant.hit_points - damage)

	if combatant.hit_points <= 0 {
		kill_combatant(target, loc)
	}
}


kill_combatant :: proc(handle: Combatant_Handle, loc := #caller_location) {
	combatant := get_combatant(handle, loc)
	assert(combatant != nil, "Nil Combatant pointer.", loc)

	// TODO: Play animation and spawn a body Object.

	combatant.flags -= { .Solid }

	log.infof("%v has died.", combatant.name)
}


// ------------------------------- !END GENERAL! -------------------------------


// +---------------------------------------------------------------------------+
// |                                    !ENEMY!                                |
// +---------------------------------------------------------------------------+


// Creates a new enemy in the arena.
new_enemy :: proc(world: ^World, enemy_type: Enemy_Type_Data, loc := #caller_location) -> ^Combatant {
	assert(world != nil, "Nil World pointer.", loc)

	enemy_handle := new_combatant(world, loc)
	enemy := get_combatant(enemy_handle)

	enemy.flags = { .Valid, .Solid }
	enemy.hit_points = get_max_hp(enemy_type.stats)
	enemy.type = Enemy{
		enemy_type = enemy_type,
	}

	// TODO: Temporary. Remove this.
	enemy.animator.texture = enemy_type.icon

	return enemy
}


update_enemy :: proc(handle: Combatant_Handle, delta_time: f32) {

}


do_enemy_turn :: proc(handle: Combatant_Handle) -> Event {
	// action := create_action(handle)
	// action.type = Move_Action{
	// 	direction = rand.choice_enum(Direction),
	// 	distance = 1,
	// }

	return INVALID_EVENT
}


// --------------------------------- !END ENEMY! -------------------------------


// +---------------------------------------------------------------------------+
// |                                   !ENGINE!                                |
// +---------------------------------------------------------------------------+


// Draws a specific Combatant.
draw_combatant :: proc(combatant: ^Combatant) {
	world_position := world_to_screen(combatant.position)
	rl.DrawTextureV(combatant.animator.texture, world_position, rl.WHITE)
}


// Draws all of the Combatants in the given world.
draw_combatants :: proc(world: ^World) {
	for &combatant in world.combatants {
		if .Valid not_in combatant.flags {
			continue
		}

		draw_combatant(&combatant)
	}
}


// -------------------------------- !END ENGINE! -------------------------------

