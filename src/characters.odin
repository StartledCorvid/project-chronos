package game
/*
# Overview
Definitions of different Player_Character types.

# Adding a New Character
1. Add the character's name to the Character_Type enum.
2. Add a definition in the array returned by load_characters.
*/

import rl "vendor:raylib"


// All of the different characters that the player can play as.
Character_Type :: enum {
	Fighter,
}


// The information contained in a player character.
Player_Character :: struct {
	name:        string,
	description: string,
	stats:       Stat_Block,
	icon:        rl.Texture,
	animator:    Animator,
	// TODO: Animations and abilities.
}


// Loads the characters for the game.
load_characters :: proc() -> [Character_Type]Player_Character {
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
			icon = rl.LoadTexture("res/images/fighter.png"),
		},
	}
}


// Determines if the given character is unlocked by the player.
is_character_unlocked :: proc(character: Character_Type) -> bool {
	// TOOD: Logic to determine if a Character_Type is unlocked.
	return true
}