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

	basic_attack: Attack,
	// TODO: Animations and abilities.
}

Attack_Flag :: enum {
	Pierce, // Goes through solid objects.
}

Attack :: struct {
	flags: bit_set[Attack_Flag],
	range: u32,
	damage: u32,
}

Attack_Action :: struct {
	attack: Attack,
	direction: Direction,
	world: ^World,
	attacker: ^Combatant,
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
			basic_attack = {
				flags = {},
				range = 1,
				damage = 1,
			},
		},
	}
}


// Determines if the given character is unlocked by the player.
is_character_unlocked :: proc(character: Character_Type) -> bool {
	// TOOD: Logic to determine if a Character_Type is unlocked.
	return true
}


do_attack :: proc(attack: Attack_Action) {
	direction := directions[attack.direction]

	for length in 1..=attack.attack.range {
		point := attack.attacker.position + (direction * i32(length))

		if object := get_object_at(attack.world, point); object != nil {
			// if .Breakable in object.flags do break_object(object)
			if .Pierce not_in attack.attack.flags && .Solid in object.flags do break
		}

		combatant_handle := get_combatant_at(attack.world^, point)
		if is_combatant_handle_valid(combatant_handle) {

		}

		// combatant != nil && .Dead not_in combatant.flags {
		// 	damage_combatant(combatant_handle, attack.attack.damage) // TODO: Damage modifier.
		// 	if .Pierce not_in attack.attack.flags && .Solid in combatant.flags do break
		// }
	}
}