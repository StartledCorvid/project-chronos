package game

/*
# Overview
Content definition for the different types of fights that can be generated.

# Adding a New Fight
1. Add an entry to the FIGHTS array.
*/


Fight_Info :: struct {
	rating: i32, // The difficulty rating of the fight.
	composition: []Character_Type, // The Character_Types of the enemies in the fight.
}


@(rodata)
FIGHTS := [?]Fight_Info{
	{
		rating = 1,
		composition = {
			.Goblin,
		},
	},
	{
		rating = 3,
		composition = {
			.Goblin,
			.Goblin,
		},
	},
}
