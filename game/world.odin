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


// Serializable World data.
World_Data :: struct {
	tile_texture: Texture_Name,
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
DIRECTIONS := [Direction]World_Coords{
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
	animator: Animator,
}

Object_Data :: struct {

}


// -------------------------------- !END TYPES! --------------------------------


// +---------------------------------------------------------------------------+
// |                                  !GENERAL!                                |
// +---------------------------------------------------------------------------+


init_world :: proc(world: ^World, world_data: World_Data) {
	world.tile_texture = get_texture(world_data.tile_texture)
	world.world_size = world_data.world_size

	for id in 0..<MAX_ENTITIES {
		sa.append(&world._inactive_entities, id)
	}
}


deinit_world :: proc(world: ^World, loc := #caller_location) {
	for entity_id in sa.slice(&world._active_entities) {
		handle := new_entity_handle(world, entity_id)

		assert(entity_handle_valid(handle), "Invalid Entity ID in active Entitites.", loc)

		free_entity(handle, loc)
	}

	world.world_size = 0
}


// Gets a random point in the World.
random_world_point :: proc(world: World) -> World_Coords {
	return {
		rand.int31() % i32(world.world_size),
		rand.int31() % i32(world.world_size),
	}
}


world_get_entity_at :: proc(world: ^World, position: World_Coords, loc := #caller_location) -> Entity_Handle {
	for entity_id in sa.slice(&world._active_entities) {
		entity := world.entities[entity_id]

		assert(.Valid in entity.flags, "An invalid Entity somehow got in the active list.", loc)

		if entity.position == position {
			return new_entity_handle(world, entity)
		}
	}

	return Entity_Handle{}
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


world_get_entities_in_path :: proc(world: ^World, start: World_Coords, direction: Direction, distance: int) -> [dynamic]Entity_Handle {
	entities: [dynamic]Entity_Handle

	end_pos := start
	for _ in 0..<distance {
		new_pos := end_pos + DIRECTIONS[direction]

		world_size := i32(world.world_size)
		if new_pos.x >= world_size || new_pos.y >= world_size {
			break
		}

		handle_at_pos := world_get_entity_at(world, new_pos)
		if entity_handle_valid(handle_at_pos) {
			append(&entities, handle_at_pos)
		}

		end_pos = new_pos
	}

	return entities
}


// Checks the path in the direction of the given direction and returns the closest
// available point on that path that is not blocked.
// O ---> X --> Will return the point just before X.
world_path_free :: proc(world: ^World, start: World_Coords, direction: Direction, distance: int, pass_through: bool = false) -> World_Coords {
	end_pos := start
	for _ in 0..<distance {
		new_pos := end_pos + DIRECTIONS[direction]

		world_size := i32(world.world_size)
		if new_pos.x >= world_size || new_pos.y >= world_size {
			return end_pos
		}

		if !pass_through && !world_space_empty(world, new_pos) {
			return end_pos
		}

		end_pos = new_pos
	}
	return end_pos
}


// Returns a bit_set populated with the directions that are available to move
// from the origin.
get_free_directions :: proc(origin: World_Coords) -> bit_set[Direction] {
    free_directions: bit_set[Direction]
    for direction in Direction {
        potential_position := origin + DIRECTIONS[direction]
        is_free := world_space_empty(&game.current_world, potential_position)

        if is_free do free_directions += { direction }
    }
    return free_directions
}


// Converts a grid coordinate to its point in the world.
grid_to_world_point :: proc(grid_coordinates: World_Coords) -> World_Coords {
	return {
		grid_coordinates.x * WORLD_UNITS,
		grid_coordinates.y * WORLD_UNITS,
	}
}


// -------------------------------- !END GENERAL! ------------------------------


// +-------------------------------------------------------------------------------------+
// |                                  !PROCESSING!                                       |
// +-------------------------------------------------------------------------------------+


// Calls a processing tick on all the Entities in the World.
tick_world :: proc(world: ^World, delta_time: f32, loc := #caller_location) {
	for entity_id in sa.slice(&world._active_entities) {
		handle := new_entity_handle(world, entity_id)
		tick_entity(handle, delta_time)
	}
}


// Draws the contents of the World.
draw_world :: proc(world: ^World) {
	// Draw background.
	for x in 0..<world.world_size {
		for y in 0..<world.world_size {
			position := grid_to_world_point({ i32(x), i32(y) })
			rl.DrawTextureV(world.tile_texture, to_vector2(position), rl.WHITE)
		}
	}

	// Draw entities.
	for entity_id in sa.slice(&world._active_entities) {
		entity_handle := new_entity_handle(world, entity_id)
		draw_entity(entity_handle)
	}
}


// ----------------------------------- !END PROCESSING! ----------------------------------
