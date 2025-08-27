package game
/*
# Overview
Handles the data and procedures done to manage items.
*/

import rl "vendor:raylib"


// The different types of items in the game.
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