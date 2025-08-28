package game
/*
# Overview
Basic world procedures and data.
*/

import sa "core:container/small_array"
import "core:math/rand"
import rl "vendor:raylib"


// +---------------------------------------------------------------------------+
// |                               !DEFINITIONS!                               |
// +---------------------------------------------------------------------------+


// The maximum amount of Objects that are allowed in a World.
MAX_OBJECTS :: 100


// The size of a single unit (in pixels) in the world.
WORLD_UNITS :: 16


// Represents a point on the world's grid.
World_Coords :: [2]i32


// A handle that references an Object instance.
Object_Handle :: distinct Handle


// ----------------------------- !END DEFINITIONS! -----------------------------


// +---------------------------------------------------------------------------+
// |                                  !TYPES!                                  |
// +---------------------------------------------------------------------------+


// Data for a game level world.
World :: struct {
	active_combatants: sa.Small_Array(MAX_COMBATANTS, Combatant_Handle),
	active_objects: sa.Small_Array(MAX_OBJECTS, int),

	combatants: [MAX_COMBATANTS]Combatant,
	objects: [MAX_OBJECTS]Object,

	turn_manager: Turn_Manager, // TODO: Handle another way?
}


// The different directions in the world.
Direction :: enum {
	Up, Down, Left, Right,
}

@(rodata)
directions := [Direction]World_Coords{
	.Up = { 0, -1 },
	.Down = { 0, 1 },
	.Left = { -1, 0 },
	.Right = { 1, 0 },
}


// Represents the state of an Object.
Object_Flag :: enum {
	Valid,
	Solid,
	Breakable,
}


// An object that can appear in the world.
Object :: struct {
	flags: bit_set[Object_Flag],
	position: World_Coords,
}


// -------------------------------- !END TYPES! --------------------------------


// +---------------------------------------------------------------------------+
// |                                  !GENERAL!                                |
// +---------------------------------------------------------------------------+


// Creates a new World.
new_world :: proc(size: int, allocator := context.allocator, loc := #caller_location) -> ^World {
	world := new(World, allocator, loc)
	world.turn_manager.player_turn = true
	return world
}


free_world :: proc(world: ^World, allocator := context.allocator, loc := #caller_location) {
	assert(world != nil, "Nil World pointer.", loc)
	free(world, allocator, loc)
}


// Gets a random point in the World.
random_world_point :: proc() -> World_Coords {
	return {
		rand.int31() % WORLD_SIZE,
		rand.int31() % WORLD_SIZE,
	}
}


// Converts world coordinates to screen coordinates.
world_to_screen :: proc(grid_position: World_Coords) -> rl.Vector2 {
	return rl.Vector2{
		f32(grid_position.x) * WORLD_UNITS,
		f32(grid_position.y) * WORLD_UNITS,
	}
}


// Gets the Object located at the given position. If there is not an Object
// there, returns nil.
get_object_at :: proc(world: ^World, position: World_Coords) -> ^Object {
	for i in 0..<sa.len(world.active_objects) {
		object_id := sa.get(world.active_objects, i)
		object := &world.objects[object_id]

		if object.position == position {
			return object
		}
	}

	return nil
}


// Gets a handle to the Combatant located at the given position. Second return is if it was found.
get_combatant_at :: proc(world: World, position: World_Coords) -> Combatant_Handle {
	for i in 0..<sa.len(world.active_combatants) {
		combatant_handle := sa.get(world.active_combatants, i)
		combatant := get_combatant(combatant_handle)

		if combatant.position == position {
			return combatant_handle
		}
	}

	return Combatant_Handle{}
}


// Checks if the given coordinates are free, or if an Object or Combatant is already there.
space_empty :: proc(world: ^World, coords: World_Coords) -> bool {
	combatant_handle := get_combatant_at(world^, coords)
	if is_combatant_handle_valid(combatant_handle) {
		return false
	}

	if get_object_at(world, coords) != nil do return false
	return true
}

break_object :: proc(object: ^Object) {

}


// -------------------------------- !END GENERAL! ------------------------------


// +---------------------------------------------------------------------------+
// |                                   !ENGINE!                                |
// +---------------------------------------------------------------------------+


// Draws the world grid and background.
draw_world :: proc(world: ^World, texture: rl.Texture) {
	// Draw background.
	for x in 0..<WORLD_SIZE {
		for y in 0..<WORLD_SIZE {
			position := world_to_screen({ i32(x), i32(y) })
			rl.DrawTextureV(texture, position, rl.WHITE)
		}
	}


	// Draw objects.


	// Draw combatants.
	draw_combatants(world)
}


// -------------------------------- !END ENGINE! -------------------------------
