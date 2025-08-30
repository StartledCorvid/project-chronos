package game
/*
# Overview
Handles the creation of fights using different algorithms.
*/

// import "core:math/rand"


// Fight_Type :: enum {
//     Swarm,
//     Balanced,
//     Boss,
// }



// create_fight :: proc(pool: [Enemy_Type]Enemy_Type_Data, difficulty: u32, type: Fight_Type) -> [Enemy_Type]int {
//     enemy_counts: [Enemy_Type]int



//     switch type {
//     case .Swarm:
//     case .Balanced:
//         enemy_counts = make_balanced_fight(pool, difficulty)
//     case .Boss:
//     }

//     return enemy_counts
// }


// make_balanced_fight :: proc(pool: [Enemy_Type]Enemy_Type_Data, difficulty: u32) -> [Enemy_Type]int {
//     enemy_counts: [Enemy_Type]int
//     count: u32 = 0
//     total_difficulty: u32 = 0

//     half_difficulty := difficulty / 2
//     hard, hard_difficulty := get_hardest_enemy(pool, half_difficulty)
//     enemy_counts[hard] += 1

//     count += 1
//     total_difficulty += hard_difficulty

//     last_difficulty := hard_difficulty

//     for count < MAX_COMBATANTS - 1 && total_difficulty < difficulty {
//         random_difficulty := rand.uint32() % last_difficulty
//         enemy, enemy_difficulty := get_closest_difficulty_enemy(pool, random_difficulty)

//         count += 1
//         total_difficulty += enemy_difficulty
//         last_difficulty = enemy_difficulty
//         enemy_counts[enemy] += 1
//     }

//     return enemy_counts
// }


// // Gets the Enemy_Type with a difficulty closest to the given difficulty.
// @(private="file")
// get_closest_difficulty_enemy :: proc(pool: [Enemy_Type]Enemy_Type_Data, difficulty: u32) -> (Enemy_Type, u32) {
//     closest_enemy: Enemy_Type
//     closest_difficulty: u32
//     closest_distance: u32

//     // TODO: Sort pool by difficulty to speed this up fron O(n).

//     for enemy, type in pool {
//         distance := abs(enemy.difficulty - difficulty)
//         if distance < closest_distance {
//             closest_enemy = type
//             closest_difficulty = enemy.difficulty
//             closest_distance = distance
//         }
//     }

//     return closest_enemy, closest_difficulty
// }


// @(private="file")
// get_hardest_enemy :: proc(pool: [Enemy_Type]Enemy_Type_Data, difficulty: u32) -> (Enemy_Type, u32) {
//     hardest_enemy: Enemy_Type
//     hardest_difficulty: u32

//     // TODO: Sort pool by difficulty to speed this up fron O(n).

//     for enemy, type in pool {
//         if enemy.difficulty <= difficulty && enemy.difficulty > hardest_difficulty {
//             hardest_enemy = type
//             hardest_difficulty = enemy.difficulty
//         }
//     }

//     return hardest_enemy, hardest_difficulty
// }


// @(private="file")
// get_easiest_enemy :: proc(pool: [Enemy_Type]Enemy_Type_Data, min_difficulty: u32 = 0) -> (Enemy_Type, u32) {
//     easiest_enemy: Enemy_Type
//     easiest_difficulty: u32 = 1 << 32 - 1 // Max u32

//     // TODO: Sort pool by difficulty to speed this up fron O(n).

//     for enemy, type in pool {
//         if enemy.difficulty >= min_difficulty && enemy.difficulty < easiest_difficulty {
//             easiest_enemy = type
//             easiest_difficulty = enemy.difficulty
//         }
//     }

//     return easiest_enemy, easiest_difficulty
// }