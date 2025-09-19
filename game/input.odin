package game
/*
# Overview
Handles player input. Essentially a wrapper for Raylib input to map to
game Action_Codes instead.

# Adding Input Actions
1. Add the Action's code to Action_Code.
2. Add an entry to Input_Map that lines up with the action.
3. Add to the switch in action_code_to_map_keys.
*/

import rl "vendor:raylib"
import "core:encoding/json"
import "core:log"
import "core:os"
import "vfiles"


// +-------------------------------------------------------------------------------------+
// |                                   !DEFINITIONS!                                     |
// +-------------------------------------------------------------------------------------+


// Global input map.
input_map := Input_Map{
	move_up    = { .W, .KEY_NULL },
	move_down  = { .S, .KEY_NULL },
	move_right = { .D, .KEY_NULL },
	move_left  = { .A, .KEY_NULL },

	attack_up    = { .UP,    .KEY_NULL },
	attack_down  = { .DOWN,  .KEY_NULL },
	attack_right = { .RIGHT, .KEY_NULL },
	attack_left  = { .LEFT,  .KEY_NULL },

	ability_a    = { .Q, .KEY_NULL },
	ability_b    = { .E, .KEY_NULL },
}


// ---------------------------------- !END DEFINITIONS! ----------------------------------


// +-------------------------------------------------------------------------------------+
// |                                      !TYPES!                                        |
// +-------------------------------------------------------------------------------------+


// The different actions that have a key associated with them.
Action_Code :: enum {
	Move_Up,
	Move_Down,
	Move_Right,
	Move_Left,

	Attack_Up,
	Attack_Down,
	Attack_Right,
	Attack_Left,

	Ability_A,
	Ability_B,
}


// Maps input keys to game actions.
// :<action_code>: [2]rl.KeyboardKey,
Input_Map :: struct {
	move_up:    [2]rl.KeyboardKey,
	move_down:  [2]rl.KeyboardKey,
	move_right: [2]rl.KeyboardKey,
	move_left:  [2]rl.KeyboardKey,

	attack_up:    [2]rl.KeyboardKey,
	attack_down:  [2]rl.KeyboardKey,
	attack_right: [2]rl.KeyboardKey,
	attack_left:  [2]rl.KeyboardKey,

	ability_a: [2]rl.KeyboardKey,
	ability_b: [2]rl.KeyboardKey,
}


// ------------------------------------- !END TYPES! -------------------------------------


// +-------------------------------------------------------------------------------------+
// |                                     !KEY MAP!                                       |
// +-------------------------------------------------------------------------------------+


// Creates a default Input_Map.
default_input_map :: proc() {
	input_map = {
		move_up    = { .W, .KEY_NULL },
		move_down  = { .S, .KEY_NULL },
		move_right = { .D, .KEY_NULL },
		move_left  = { .A, .KEY_NULL },

		attack_up    = { .UP,    .KEY_NULL },
		attack_down  = { .DOWN,  .KEY_NULL },
		attack_right = { .RIGHT, .KEY_NULL },
		attack_left  = { .LEFT,  .KEY_NULL },

		ability_a    = { .Q, .KEY_NULL },
		ability_b    = { .E, .KEY_NULL },
	}
}


// Loads keymap data from a JSON file.
load_input_map :: proc(file: string) {
	res_path := vfiles.get_path(file)
	defer delete(res_path)

	data, ok := os.read_entire_file_from_filename(res_path)
	if !ok {
		log.errorf("Could not load Input Map file '%v'.", file)
		return
	}
	defer delete(data)

	loaded_input_map: Input_Map

	unmarshal_err := json.unmarshal(data, &loaded_input_map)
	if unmarshal_err != nil {
		log.errorf("Problem unmarshalling Input Map file '%v'.", file)
		return
	}

	input_map = loaded_input_map
	log.infof("Successfully loaded Input Map from '%v'.", file)
}


// Saves the given keymap to a JSON file.
save_input_map :: proc(file: string) -> bool {
	res_path := vfiles.get_path(file)
	defer delete(res_path)

	data, marshal_err := json.marshal(input_map, { pretty = true, use_enum_names = true } )
	if marshal_err != nil {
		log.errorf("Problem marshalling Input Map to file '%v'.", file)
		return false
	}
	defer delete(data)

	ok := os.write_entire_file(res_path, data)
	if !ok {
		log.errorf("Problem writing Input Map to file '%v'.", file)
		return false
	}

	log.infof("Successfully saved Input Map to '%v'.", file)
	return true
}


// ------------------------------------ !END KEY MAP! ------------------------------------


// +-------------------------------------------------------------------------------------+
// |                                      !CHECKS!                                       |
// +-------------------------------------------------------------------------------------+


// Checks if the action is being pressed.
is_action_down :: proc(action_code: Action_Code) -> bool {
	keys := action_code_to_map_keys(action_code)
	return rl.IsKeyDown(keys[0]) || rl.IsKeyDown(keys[1])
}


// Checks if the action is NOT being pressed.
is_action_up :: proc(action_code: Action_Code) -> bool {
	keys := action_code_to_map_keys(action_code)
	return rl.IsKeyUp(keys[0]) || rl.IsKeyUp(keys[1])
}


// Checks if the action has been pressed once.
is_action_pressed :: proc(action_code: Action_Code) -> bool {
	keys := action_code_to_map_keys(action_code)
	return rl.IsKeyPressed(keys[0]) || rl.IsKeyPressed(keys[1])
}


// Checks if the action has been pressed again.
is_action_pressed_repeat :: proc(action_code: Action_Code) -> bool {
	keys := action_code_to_map_keys(action_code)
	return rl.IsKeyPressedRepeat(keys[0]) || rl.IsKeyPressedRepeat(keys[1])
}


// Checks if the action has been released once.
is_action_released :: proc(action_code: Action_Code) -> bool {
	keys := action_code_to_map_keys(action_code)
	return rl.IsKeyReleased(keys[0]) || rl.IsKeyReleased(keys[1])
}


// Maps the given Action_Code to the action it represents in the Input_Map.
@(private="file")
action_code_to_map_keys :: proc(action_code: Action_Code) -> [2]rl.KeyboardKey {
	switch action_code {
	case .Move_Up:    return input_map.move_up
	case .Move_Down:  return input_map.move_down
	case .Move_Right: return input_map.move_right 
	case .Move_Left:  return input_map.move_left

	case .Attack_Up:    return input_map.attack_up
	case .Attack_Down:  return input_map.attack_down
	case .Attack_Right: return input_map.attack_right
	case .Attack_Left:  return input_map.attack_left

	case .Ability_A: return input_map.ability_a
	case .Ability_B: return input_map.ability_b
	}

	return { .KEY_NULL, .KEY_NULL }
}


// ------------------------------------ !END CHECKS! -------------------------------------
