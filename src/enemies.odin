package game
/*
# Overview
For maanging the different enemy types that are possible in the game.

# Adding New Enemy Types
1. Add the new enemy type's name to the Enemy_Type enum.
2. Add a definition in the array returned by load_enemies.
*/

import rl "vendor:raylib"


// The names of the different enemy types.
Enemy_Type :: enum {
	Goblin,
}


// The data that defines a new enemy type.
Enemy_Type_Data :: struct {
	name: string,
	description: string,
	stats: Stat_Block,
	icon: rl.Texture,
	animator: Animator,
	turn: proc(^World, ^Combatant),
}


// Loads the enemy types for the game.
load_enemies :: proc() -> [Enemy_Type]Enemy_Type_Data {
	return {
		.Goblin = {
			name = "Goblin",
			description = "A not so great warrior.",
			stats = {
				.Speed     = 4,
				.Strength  = 5,
				.Magic     = 0,
				.Agility   = 8,
				.Toughness = 1,
			},
			icon = rl.LoadTexture("res/images/goblin.png"),
			turn = turn_basic_enemy,
		},
	}
}


// The basic process for an enemy taking their turn.
@(private="file")
turn_basic_enemy :: proc(world: ^World, enemy: ^Combatant) {
	
}