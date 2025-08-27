package game


import rl "vendor:raylib"


Characters :: enum {
	Fighter,
}


Player_Character :: struct {
	name: string,
	description: string,
	stats: Stat_Block,
	icon: rl.Texture,
	animator: Animator,
	// TODO: Animations and abilities.
}


// Loads the characters for the game.
load_characters :: proc() -> [Characters]Player_Character {
	return { 
		.Fighter = {
			name = "Fighter",
			description = "A great warrior.",
			stats = {
				.Speed     = 10,
				.Strength  = 12,
				.Magic     = 0,
				.Agility   = 8,
				.Toughness = 12,
			},
			icon = rl.LoadTexture("res/images/fighter_icon.png"),
		},
	}
}