package game
/*
# Overview
Structure to represent the Combatants in the game. This means the Player and the enemies.

*/

import rl "vendor:raylib"


MAX_COMBATANTS :: 5

Stat_Block :: [Stat]i32

// TODO: Characters.






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

	base_stats: Stat_Block,
	stat_modifiers: Stat_Block,

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
	
}


Combat_Arena :: struct {
	combatants: [MAX_COMBATANTS]Combatant,

	current_tick: u32,
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
	player.base_stats = character.stats
	player.hit_points = get_max_hp(player.base_stats)
	player.type = Player{
		character = character,
	}

	// TODO: Temp
	player.animator.texture = character.icon

	return player
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

}


update_enemy :: proc(arena: ^Combat_Arena, player: ^Combatant, delta_time: f32) {

}


draw_combatant :: proc(combatant: ^Combatant) {
	world_position := to_world_units(combatant.position)
	rl.DrawTextureV(combatant.animator.texture, world_position, rl.WHITE)
}