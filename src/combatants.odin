package game
/*
import "core:math/rand"
# Overview
Structure to represent the Combatants in the game. This means the Player and the
enemies.
*/

import "core:math/rand"
import rl "vendor:raylib"


MAX_COMBATANTS :: 5


Stat_Block :: [Stat]i32


Stat :: enum {
	Speed,
	Strength,
	Magic,
	Agility,
	Toughness,
}


Combatant_Flag :: enum {
	Valid,
	Dead,
}


Combatant :: struct {
	name: string,
	flags: bit_set[Combatant_Flag],

	animator: Animator,
	type: Combatant_Type,

	// TODO: Stat modifiers.

	action_points: u32,
	hit_points: u32,

	position: [2]i32,
}


Combatant_Type :: union {
	Player,
	Enemy,
}


Player :: struct {
	character: Player_Character,
}


Enemy :: struct {
	enemy_type: Enemy_Type_Data,
}


Combat_Arena :: struct {
	combatants: [MAX_COMBATANTS]Combatant,

	current_tick: u32,
	player_moved: bool,
}


Item_Type :: enum {
	Weapon,
	Utility,
	Ring,
	Necklace,
	Artifact,
	Consumable,
	Two_Handed,
}


Rarity :: enum {
	Common,
	Uncommon,
	Rare,
	Legendary,
}


Item :: struct {
	name: string,
	description: string,
	texture: rl.Texture,

	type: Item_Type,
	rarity: Rarity,

	cost: u32,
}


Item_Instance :: struct {
	stats: Item,
}


// Creates a new player in the arena.
new_player :: proc(arena: ^Combat_Arena, character: Player_Character, loc := #caller_location) -> ^Combatant {
	assert(arena != nil, "Nil Combat_Arena pointer.", loc)

	player: ^Combatant = nil
	for &slot in arena.combatants {
		if .Valid not_in slot.flags {
			player = &slot
			break
		}
	}
	assert(player != nil, "Couldn't find open slot for Player.", loc)

	player.flags = { .Valid }
	player.action_points = 0
	player.hit_points = get_max_hp(character.stats)
	player.type = Player{
		character = character,
	}

	// TODO: Temporary. Remove this.
	player.animator.texture = character.icon

	return player
}


// Creates a new enemy in the arena.
new_enemy :: proc(arena: ^Combat_Arena, enemy_type: Enemy_Type_Data, loc := #caller_location) -> ^Combatant {
	assert(arena != nil, "Nil Combat_Arena pointer.", loc)

	enemy: ^Combatant = nil
	for &slot in arena.combatants {
		if .Valid not_in slot.flags {
			enemy = &slot
			break
		}
	}
	assert(enemy != nil, "Couldn't find open slot for new Enemy.", loc)

	enemy.flags = { .Valid }
	enemy.action_points = 0
	enemy.hit_points = get_max_hp(enemy_type.stats)
	enemy.type = Enemy{
		enemy_type = enemy_type,
	}

	// TODO: Temporary. Remove this.
	enemy.animator.texture = enemy_type.icon

	return enemy
}


get_max_hp :: proc(stats: Stat_Block) -> u32 {
	return u32(max(1, stats[.Toughness]))
}


update_combatants :: proc(arena: ^Combat_Arena, delta_time: f32) {
	for &combatant in arena.combatants {
		if .Valid not_in combatant.flags {
			continue
		}

		switch type in combatant.type {
		case Player:
			update_player(arena, &combatant, delta_time)
		case Enemy:
			update_enemy(arena, &combatant, delta_time)
		}
	}

	arena.player_moved = false
}


draw_combatants :: proc(arena: ^Combat_Arena) {
	for &combatant in arena.combatants {
		if .Valid not_in combatant.flags {
			continue
		}

		draw_combatant(&combatant)
	}
}


update_player :: proc(arena: ^Combat_Arena, player: ^Combatant, delta_time: f32) {
	// TODO: Proper input system with action mapping.
	if rl.IsKeyPressed(.S) {
		player.position.y += 1
		arena.player_moved = true
	}
	if rl.IsKeyPressed(.W) {
		player.position.y -= 1
		arena.player_moved = true
	}
	if rl.IsKeyPressed(.D) {
		player.position.x += 1
		arena.player_moved = true
	}
	if rl.IsKeyPressed(.A) {
		player.position.x -= 1
		arena.player_moved = true
	}

	player.position.x = clamp(player.position.x, 0, WORLD_SIZE - 1)
	player.position.y = clamp(player.position.y, 0, WORLD_SIZE - 1)
}


update_enemy :: proc(arena: ^Combat_Arena, enemy: ^Combatant, delta_time: f32) {
	if arena.player_moved {
		random_dir := rand.uint32() % 4

		UP :: 0
		DOWN :: 1
		LEFT :: 2
		RIGHT :: 3


		switch random_dir {
		case UP:
			enemy.position.y -= 1
		case DOWN:
			enemy.position.y += 1
		case RIGHT:
			enemy.position.x += 1
		case LEFT:
			enemy.position.x -= 1
		}

		enemy.position.x = clamp(enemy.position.x, 0, WORLD_SIZE - 1)
		enemy.position.y = clamp(enemy.position.y, 0, WORLD_SIZE - 1)
	}
}


draw_combatant :: proc(combatant: ^Combatant) {
	world_position := to_world_units(combatant.position)
	rl.DrawTextureV(combatant.animator.texture, world_position, rl.WHITE)
}