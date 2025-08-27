package game
/*
import "core:math/rand"
# Overview
Structure to represent the Combatants in the game. This means the Player and the
enemies.
*/

// import "core:math/rand"
import rl "vendor:raylib"


// +---------------------------------------------------------------------------+
// |                               !DEFINITIONS!                               |
// +---------------------------------------------------------------------------+


// The maximum amount of Combatants allowed in the game at one time.
MAX_COMBATANTS :: 5


// A list of the different stats and their values.
Stat_Block :: [Stat]i32


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
	Dead,
	Solid,
}


// Represents an entity that can move and fight in the world.
Combatant :: struct {
	name: string,
	flags: bit_set[Combatant_Flag],

	animator: Animator,
	type: Combatant_Type,

	// TODO: Stat modifiers.

	action_points: u32,
	hit_points: u32,

	position: World_Coords,
}


// A union for the different types of Combatants present in the game.
Combatant_Type :: union {
	Player,
	Enemy,
}


// The player's Combatant.
Player :: struct {
	character: Player_Character,
}


// A foe Combatant for the player to play against.
Enemy :: struct {
	enemy_type: Enemy_Type_Data,
}


// -------------------------------- !END TYPES! --------------------------------


// +---------------------------------------------------------------------------+
// |                                   !PLAYER!                                |
// +---------------------------------------------------------------------------+


// Creates a new player in the arena.
new_player :: proc(world: ^World, character: Player_Character, loc := #caller_location) -> ^Combatant {
	assert(world != nil, "Nil World pointer.", loc)

	player: ^Combatant = nil
	for &slot in world.combatants {
		if .Valid not_in slot.flags {
			player = &slot
			break
		}
	}
	assert(player != nil, "Couldn't find open slot for Player.", loc)

	player.flags = { .Valid, .Solid }
	player.action_points = 0
	player.hit_points = get_max_hp(character.stats)
	player.type = Player{
		character = character,
	}

	// TODO: Temporary. Remove this.
	player.animator.texture = character.icon

	return player
}


// Does the frame-by-frame processing for the player.
update_player :: proc(world: ^World, player: ^Combatant, delta_time: f32) {
	// TODO: Proper input system with action mapping.
	if rl.IsKeyPressed(.S) {
		player.position.y += 1
	}
	if rl.IsKeyPressed(.W) {
		player.position.y -= 1
	}
	if rl.IsKeyPressed(.D) {
		player.position.x += 1
	}
	if rl.IsKeyPressed(.A) {
		player.position.x -= 1
	}

	player.position.x = clamp(player.position.x, 0, WORLD_SIZE - 1)
	player.position.y = clamp(player.position.y, 0, WORLD_SIZE - 1)
}


// -------------------------------- !END PLAYER! -------------------------------


// +---------------------------------------------------------------------------+
// |                                    !ENEMY!                                |
// +---------------------------------------------------------------------------+


// Creates a new enemy in the arena.
new_enemy :: proc(world: ^World, enemy_type: Enemy_Type_Data, loc := #caller_location) -> ^Combatant {
	assert(world != nil, "Nil World pointer.", loc)

	enemy: ^Combatant = nil
	for &slot in world.combatants {
		if .Valid not_in slot.flags {
			enemy = &slot
			break
		}
	}
	assert(enemy != nil, "Couldn't find open slot for new Enemy.", loc)

	enemy.flags = { .Valid, .Solid }
	enemy.action_points = 0
	enemy.hit_points = get_max_hp(enemy_type.stats)
	enemy.type = Enemy{
		enemy_type = enemy_type,
	}

	// TODO: Temporary. Remove this.
	enemy.animator.texture = enemy_type.icon

	return enemy
}


update_enemy :: proc(world: ^World, enemy: ^Combatant, delta_time: f32) {
	// random_dir := rand.uint32() % 4

	// UP :: 0
	// DOWN :: 1
	// LEFT :: 2
	// RIGHT :: 3

	// switch random_dir {
	// case UP:
	// 	enemy.position.y -= 1
	// case DOWN:
	// 	enemy.position.y += 1
	// case RIGHT:
	// 	enemy.position.x += 1
	// case LEFT:
	// 	enemy.position.x -= 1
	// }

	// enemy.position.x = clamp(enemy.position.x, 0, WORLD_SIZE - 1)
	// enemy.position.y = clamp(enemy.position.y, 0, WORLD_SIZE - 1)
}


// --------------------------------- !END ENEMY! -------------------------------



get_max_hp :: proc(stats: Stat_Block) -> u32 {
	return u32(max(1, stats[.Toughness]))
}


// +---------------------------------------------------------------------------+
// |                                   !ENGINE!                                |
// +---------------------------------------------------------------------------+


// Does frame processing for all of the Combatants in the given world.
update_combatants :: proc(world: ^World, delta_time: f32) {
	for &combatant in world.combatants {
		if .Valid not_in combatant.flags {
			continue
		}

		switch type in combatant.type {
		case Player:
			update_player(world, &combatant, delta_time)
		case Enemy:
			update_enemy(world, &combatant, delta_time)
		}
	}
}


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

