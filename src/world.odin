package game
/*
# Overview
Basic world procedures and data.
*/

import sa "core:container/small_array"
import "core:math/rand"
import rl "vendor:raylib"
import "core:strings"


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


// Serializable World data.
World_Data :: struct {
	tile_texture_path: string,
	world_size: u32,
}


// Data for a game level world.
World :: struct {
	tile_texture: rl.Texture,
	world_size: u32,

	entities: [MAX_ENTITIES]Entity,
	_active_entities: sa.Small_Array(MAX_ENTITIES, int),
	_inactive_entities: sa.Small_Array(MAX_ENTITIES, int),
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

Object_Data :: struct {

}


// -------------------------------- !END TYPES! --------------------------------


// +---------------------------------------------------------------------------+
// |                                  !GENERAL!                                |
// +---------------------------------------------------------------------------+


// Creates a new World.
new_world :: proc(world_data: World_Data, allocator := context.allocator, loc := #caller_location) -> ^World {
	world := new(World, allocator, loc)

	tile_path_cstring := strings.clone_to_cstring(world_data.tile_texture_path)
	defer delete(tile_path_cstring)

	world.tile_texture = rl.LoadTexture(tile_path_cstring)
	world.world_size = world_data.world_size

	for id in 0..<MAX_ENTITIES {
		sa.append(&world._inactive_entities, id)
	}

	return world
}


free_world :: proc(world: ^World, allocator := context.allocator, loc := #caller_location) {
	assert(world != nil, "Nil World pointer.", loc)

	rl.UnloadTexture(world.tile_texture)

	free(world, allocator, loc)
}


// Gets a random point in the World.
random_world_point :: proc(world: World) -> World_Coords {
	return {
		rand.int31() % i32(world.world_size),
		rand.int31() % i32(world.world_size),
	}
}


// Converts world coordinates to screen coordinates.
world_to_screen :: proc(grid_position: World_Coords) -> rl.Vector2 {
	return {
		f32(grid_position.x) * WORLD_UNITS,
		f32(grid_position.y) * WORLD_UNITS,
	}
}


// Checks if the given coordinates are free, or if a solid Entity is already there.
world_space_empty :: proc(world: ^World, coords: World_Coords, loc := #caller_location) -> bool {
	if coords.x >= i32(world.world_size) ||
	   coords.y >= i32(world.world_size) ||
	   coords.x < 0 ||
	   coords.y < 0 {
	   	return false
   }

	for entity_id in sa.slice(&world._active_entities) {
		entity := world.entities[entity_id]

		assert(.Valid in entity.flags, "An invalid Entity somehow got in the active list.", loc)

		if entity.position == coords && .Solid in entity.flags {
			return false
		}
	}

	return true
}


// Returns a bit_set populated with the directions that are available to move
// from the origin.
get_free_directions :: proc(origin: World_Coords) -> bit_set[Direction] {
    free_directions: bit_set[Direction]
    for direction in Direction {
        potential_position := origin + directions[direction]
        is_free := world_space_empty(game.current_world, potential_position)

        if is_free do free_directions += { direction }
    }
    return free_directions
}


// -------------------------------- !END GENERAL! ------------------------------


// +-------------------------------------------------------------------------------------+
// |                                  !PROCESSING!                                       |
// +-------------------------------------------------------------------------------------+


// Calls a processing tick on all the Entities in the World.
world_tick :: proc(world: ^World, delta_time: f32, loc := #caller_location) {
	
}


// Draws the contents of the World.
world_draw :: proc(world: ^World) {
	// Draw background.
	for x in 0..<world.world_size {
		for y in 0..<world.world_size {
			position := world_to_screen({ i32(x), i32(y) })
			rl.DrawTextureV(world.tile_texture, position, rl.WHITE)
		}
	}

	// Draw entities.
	for entity_id in sa.slice(&world._active_entities) {
		entity_handle := new_entity_handle(world, entity_id)
		entity_draw(entity_handle)
	}
}


// ----------------------------------- !END PROCESSING! ----------------------------------
