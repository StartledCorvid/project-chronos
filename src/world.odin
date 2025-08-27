package game
/*
# Overview
Basic world procedures and data.
*/

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


// ----------------------------- !END DEFINITIONS! -----------------------------


// +---------------------------------------------------------------------------+
// |                                  !TYPES!                                  |
// +---------------------------------------------------------------------------+


// Data for a game level world.
World :: struct {
	active_combatants: [MAX_COMBATANTS]int,
	active_objects: [MAX_OBJECTS]int,

	combatants: [MAX_COMBATANTS]Combatant,
	objects: [MAX_OBJECTS]Object,
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
// |                                  !CHECKS!                                 |
// +---------------------------------------------------------------------------+


// Converts world coordinates to screen coordinates.
world_to_screen :: proc(grid_position: World_Coords) -> rl.Vector2 {
	return rl.Vector2{
		f32(grid_position.x) * WORLD_UNITS,
		f32(grid_position.y) * WORLD_UNITS,
	}
}


// Checks if the given coordinates are free, or if an Object or Combatant is already there.
space_empty :: proc(world: World, coords: World_Coords) -> bool {
	// TODO: Probably a better way to do this. But we aren't expecting a lot
	//       of Objects and Combatants, so it'll do for now.
	for id in world.active_combatants {
		combatant := world.combatants[id]
		if .Solid not_in combatant.flags || .Dead in combatant.flags do continue

		if coords == combatant.position {
			return false
		}
	}

	for id in world.active_objects {
		object := world.objects[id]
		if .Solid not_in object.flags do continue

		if coords == object.position {
			return false
		}
	}

	return true
}


// -------------------------------- !END CHECKS! -------------------------------


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
