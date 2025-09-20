package game

import rl "vendor:raylib"

/*
# Overview
Defines an interface for abilities.

# Creating a New Ability
1. Add the Ability name to the Ability_Name enum.
2. Add a definition of the new Ability to the load_abilities proc.
3. If unique information is needed, create a new Ability_Type entry struct with
   the needed information.
*/


Ability_Name :: enum {
    None,
    Bash,
}


Ability_Type :: union {
    Ability_Bash,
}


load_abilities :: proc() -> [Ability_Name]Ability_Info {
    return {
        .None = {},
        .Bash = {
            name = "Bash",
            description = "Move in a straight line and deal damage to the enemy hit.",

            cooldown = 2,
            confirmation_type = Direction,
            type = Ability_Bash{
                damage = 1,
                distance = 0,
                pass_through = false,
            },  

            on_use = proc(self: Ability_Slot, confirmation: Ability_Confirmation, user: ^Entity) {
                ability := unwrap_ability_slot(self, Ability_Bash)
                direction := confirmation.(Direction)
                world_size := int(game.current_world.world_size)

                bash_distance := ability.distance <= 0 ? world_size : ability.distance

                user_handle := new_entity_handle(&game.current_world, user^)
                timeline := &game.current_fight.timeline

                MOVE_TIME     :: 0.08
                OVERSTEP_TIME :: 0.1
                end_pos := user.position

                for _ in 0..<bash_distance {
                    new_pos := end_pos + DIRECTIONS[direction]

                    if new_pos.x >= i32(world_size) || new_pos.y >= i32(world_size) {
                        add_event(timeline, event_lunge(user_handle, direction, 0.5, OVERSTEP_TIME))
                        break
                    }

                    if !ability.pass_through && !world_space_empty(&game.current_world, new_pos) {
                        break
                    }

                    end_pos = new_pos
                    add_event(timeline, event_entity_move(user_handle, direction, MOVE_TIME))
                }

                if target := world_get_entity_at(&game.current_world, end_pos + DIRECTIONS[direction]); entity_handle_valid(target) {
                    add_event(timeline, event_lunge(user_handle, direction, 0.5, OVERSTEP_TIME))
                    add_event(timeline, event_deal_damage(user_handle, ability.damage, target))
                }
            },

            draw_preview = proc(self: Ability_Slot, user: Entity) {
                ability := unwrap_ability_slot(self, Ability_Bash)

                world_size := int(game.current_world.world_size)
                bash_distance := ability.distance <= 0 ? world_size : ability.distance

                for direction in DIRECTIONS {
                    current_pos := user.position

                    for _ in 0..<bash_distance {
                        new_pos := current_pos + direction

                        if new_pos.x >= i32(world_size) || new_pos.y >= i32(world_size) || new_pos.x < 0 || new_pos.y < 0 {
                            break
                        }

                        screen_pos := grid_to_world_point(new_pos)

                        if !ability.pass_through && !world_space_empty(&game.current_world, new_pos) {
                            rl.DrawRectangleV(to_vector2(screen_pos), { WORLD_UNITS, WORLD_UNITS }, { 255, 0, 0, 125 })
                            break
                        }

                        rl.DrawRectangleV(to_vector2(screen_pos), { WORLD_UNITS, WORLD_UNITS }, { 0, 255, 0, 125 })

                        current_pos = new_pos
                    }
                }
            },

            ai_can_use = ability_slot_cooled,
        },
    }
}


Ability_Confirmation :: union {
    Direction,
    bool,
}


Ability_Info :: struct {
    name: string,
    description: string,

    cooldown: int,
    confirmation_type: typeid,
    type: Ability_Type,

    on_use:       proc(self: Ability_Slot, confirmation: Ability_Confirmation, user: ^Entity),
    ai_can_use:   proc(self: Ability_Slot, user: Entity) -> bool,
    draw_preview: proc(self: Ability_Slot, user: Entity),
}


Ability_Slot :: struct {
    ability: Ability_Name,
    cooldown: int,
}


Ability_Bash :: struct {
    damage: int,        // The damage done when it hits an Entity.
    distance: int,      // -1 is as far as possible.
    pass_through: bool, // If true, will not stop once it hits a solid Entity.

    move_speed: f32,
}


// Gets a copy of the Ability_Info with the given name.
get_ability_info :: proc(ability_name: Ability_Name) -> Ability_Info {
    return game.abilities[ability_name]
}


// Returns true if there is an Ability set in the given Ability_Slot.
ability_slot_valid :: proc(slot: Ability_Slot) -> bool {
    return slot.ability != .None
}


// Clears an Ability slot.
clear_ability_slot :: proc(slot: ^Ability_Slot, loc := #caller_location) {
    assert(slot != nil, "Nil Ability_Slot pointer.", loc)
    slot.ability = .None
}


// Returns true if the Ability within an Ability_Slot is cooled down.
ability_slot_cooled :: proc(slot: Ability_Slot, _: Entity = {}) -> bool {
    return ability_slot_valid(slot) && slot.cooldown <= 0
}


// Uses the ability in the given Ability_Slot, if it has one.
use_ability :: proc(ability_slot: ^Ability_Slot, user: ^Entity, confirmation: Ability_Confirmation) {
    if ability_slot.ability == .None {
        return
    }

    ability_info := get_ability_info(ability_slot.ability)

    ability_info.on_use(ability_slot^, confirmation, user)
    ability_slot.cooldown = ability_info.cooldown
}


// Gets the information needed for an Ability.
@(private="file")
unwrap_ability_slot :: proc(ability_slot: Ability_Slot, $T: typeid) -> T {
    ability_info := get_ability_info(ability_slot.ability)
    return ability_info.type.(T)
}