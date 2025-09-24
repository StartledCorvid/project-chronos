package game

import "core:fmt"
import rl "vendor:raylib"

/*
# Overview
Defines an interface for abilities.

# Creating a New Ability
1. Add the Ability name to the Ability_Name enum.
2. Add a definition of the new Ability to the load_abilities proc.
3. If unique information is needed, create a new Ability_Type entry struct with
   the needed information, a proc thats sets up the actions, and call it in the
   switch statement in use_ability. Will also need to add a preview call to
   draw_ability_preview.
*/


Ability_Name :: enum {
    None,
    Bash,
    Push_Burst,
    Fireball,
}


Ability_Type :: union {
    Ability_Bash,
    Ability_Push_Burst,
    Ability_Projectile,
}


load_abilities :: proc() -> [Ability_Name]Ability_Info {
    return {
        .None = {},
        .Bash = {
            name = "Bash",
            description = "Move in a straight line and deal damage to the enemy hit.",
            icon = .Icon_Bash,

            cooldown = 2,
            confirmation_type = Direction,
            type = Ability_Bash{
                damage = 1,
                damage_modifier = {
                    stat = .Strength,
                    multiplier = 0.5,
                },

                distance = 0,
                pass_through = false,

                move_speed = 0.1,
            },

            ai_can_use = ai_only_use_if_no_melee,
        },

        .Push_Burst = {
            name = "Push Burst",
            description = "Pushes away adjacent enemies, dealing damage on collisions.",
            icon = .Icon_Bash,

            cooldown = 5,
            confirmation_type = bool,
            type = Ability_Push_Burst{
                push_distance = 1,
                damage = 0,
                damage_on_collide = 1,
            },

            ai_can_use = ai_only_use_if_no_melee,
        },

        .Fireball = {
            name = "Fireball",
            description = "Did I ask how big the room was?",
            icon = .Icon_Fireball,

            cooldown = 1,
            confirmation_type = Direction,
            type = Ability_Projectile{
                damage = 1,
                damage_modifier = {
                    stat = .Magic,
                    multiplier = 0.5,
                },

                range = 0,
                pass_through = false,
                projectile_speed = 0.1,

                projectile_particle = .Fireball,
                hit_particle = .Fire_Explode,
            },

            ai_can_use = ai_only_use_if_no_melee,
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
    icon: Texture_Name,

    cooldown: int,
    confirmation_type: typeid,
    type: Ability_Type,

    ai_can_use:   proc(self: Ability_Slot, user: Entity) -> bool, // TODO: Return weight.
}


Ability_Slot :: struct {
    ability: Ability_Name,
    cooldown: int,
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

    switch type in ability_info.type {
    case Ability_Bash:       ability_bash(ability_slot^, confirmation, user)
    case Ability_Push_Burst: ability_push_burst(ability_slot^, confirmation, user)
    case Ability_Projectile: ability_projectile(ability_slot^, confirmation, user)
    }

    ability_slot.cooldown = ability_info.cooldown + 1
}


// Draws the preview for the given ability.
draw_ability_preview :: proc(self: Entity, ability_info: Ability_Info) {
    switch ability in ability_info.type {
    case Ability_Bash:
        draw_directional_ability_preview(self, ability.distance, ability.pass_through)
    case Ability_Push_Burst:
        draw_directional_ability_preview(self, 1, false) // TODO: Project push movement.
    case Ability_Projectile:
        draw_directional_ability_preview(self, ability.range, ability.pass_through)
    }
}


// Draws the icon for an Ability_Slot at the given location on the screen.
ui_draw_ability_slot :: proc(ability_slot: Ability_Slot, position: Vector2) {
    rl.DrawRectangleV(position, 18, rl.BLACK)

    ability_cooled := ability_slot.cooldown <= 0

    tint := rl.WHITE
    if !ability_cooled {
        tint = rl.GRAY
    }

    ability_info := game.abilities[ability_slot.ability]
    icon := get_texture(ability_info.icon)

    icon_position := Vector2{
        (16 - f32(icon.width)) / 2,
        (16 - f32(icon.height)) / 2,
    }
    rl.DrawTextureV(icon, position + icon_position, tint)

    if !ability_cooled {
        cooldown_text := fmt.ctprintf("%v", ability_slot.cooldown)
        // TODO: Center text.
        rl.DrawText(cooldown_text, i32(position.x), i32(position.y), 8, rl.WHITE)
    }
}


// Gets the information needed for an Ability.
@(private="file")
unwrap_ability_slot :: proc(ability_slot: Ability_Slot, $T: typeid) -> T {
    ability_info := get_ability_info(ability_slot.ability)
    return ability_info.type.(T)
}


draw_directional_ability_preview :: proc(user: Entity, distance: int, pass_through: bool) {
    world_size := int(game.current_world.world_size)
    actual_distance := distance <= 0 ? world_size : distance

    for direction in DIRECTIONS {
        current_pos := user.position

        for _ in 0..<actual_distance {
            new_pos := current_pos + direction

            if new_pos.x >= i32(world_size) || new_pos.y >= i32(world_size) || new_pos.x < 0 || new_pos.y < 0 {
                break
            }

            screen_pos := grid_to_world_point(new_pos)

            if !pass_through && !world_space_empty(&game.current_world, new_pos) {
                rl.DrawRectangleV(to_vector2(screen_pos), { WORLD_UNITS, WORLD_UNITS }, { 255, 0, 0, 125 })
                break
            }

            rl.DrawRectangleV(to_vector2(screen_pos), { WORLD_UNITS, WORLD_UNITS }, { 0, 255, 0, 125 })

            current_pos = new_pos
        }
    }
}


// +-------------------------------------------------------------------------------------+
// |                                       !BASH!                                        |
// +-------------------------------------------------------------------------------------+


// Data for an ability that moves the user in a straight line,
// doing damage to enemies.
Ability_Bash :: struct {
    damage: int,        // The damage done when it hits an Entity.
    damage_modifier: Modifier,

    distance: int,      // -1 is as far as possible.
    pass_through: bool, // If true, will not stop once it hits a solid Entity.

    move_speed: f32,
}


// Schedules the events needed to use an Ability_Bash.
ability_bash :: proc(self: Ability_Slot, confirmation: Ability_Confirmation, user: ^Entity) {
    ability := unwrap_ability_slot(self, Ability_Bash)
    direction := confirmation.(Direction)
    world_size := int(game.current_world.world_size)

    bash_distance := ability.distance <= 0 ? world_size : ability.distance

    user_handle := new_entity_handle(&game.current_world, user^)
    timeline := &game.current_fight.timeline

    character := user.type.(Character)
    actual_damage := ability.damage + int(modifier_value(character.base.stats, ability.damage_modifier))

    OVERSTEP_TIME :: 0.1
    end_pos := user.position

    for _ in 0..<bash_distance {
        new_pos := end_pos + DIRECTIONS[direction]

        if new_pos.x >= i32(world_size) || new_pos.y >= i32(world_size) || new_pos.x < 0 || new_pos.y < 0 {
            add_event(timeline, event_lunge(user_handle, direction, 0.5, OVERSTEP_TIME))
            break
        }

        if !ability.pass_through && !world_space_empty(&game.current_world, new_pos) {
            break
        }

        end_pos = new_pos
        add_event(timeline, event_entity_move(user_handle, direction, ability.move_speed))
    }

    if target := world_get_entity_at(&game.current_world, end_pos + DIRECTIONS[direction]); entity_handle_valid(target) {
        add_event(timeline, event_lunge(user_handle, direction, 0.5, OVERSTEP_TIME))
        add_event(timeline, event_deal_damage(user_handle, actual_damage, target))
    }
}


// ------------------------------------- !END BASH! --------------------------------------


// +-------------------------------------------------------------------------------------+
// |                                    !PROJECTILE!                                     |
// +-------------------------------------------------------------------------------------+


// Data for an Ability that shoots a projectile in a straight line.
Ability_Projectile :: struct {
    damage: int,
    damage_modifier: Modifier,

    range: int,
    pass_through: bool,
    projectile_speed: f32,

    projectile_particle: Particle_Name,
    hit_particle: Maybe(Particle_Name),
}


// Schedules the events needed to use an Ability_Projectile.
ability_projectile :: proc(self: Ability_Slot, confirmation: Ability_Confirmation, user: ^Entity) {
    ability := unwrap_ability_slot(self, Ability_Projectile)
    direction := confirmation.(Direction)
    world_size := int(game.current_world.world_size)
    user_handle := new_entity_handle(&game.current_world, user^)

    projectile_distance := ability.range <= 0 ? world_size : ability.range

    timeline := &game.current_fight.timeline

    character := user.type.(Character)
    actual_damage := ability.damage + int(modifier_value(character.base.stats, ability.damage_modifier))

    projectile_handle := new_particle(user.position, ability.projectile_particle)

    current_pos := user.position
    for _ in 0..<projectile_distance {
        new_pos := current_pos + DIRECTIONS[direction]

        if new_pos.x >= i32(world_size) || new_pos.y >= i32(world_size) || new_pos.x < 0 || new_pos.y < 0 {
            add_event(timeline, event_destroy_entity(user_handle, projectile_handle))
            if ability.hit_particle != nil {
                add_event(timeline, event_create_particle(user_handle, ability.hit_particle.?, current_pos))
            }
            break
        }

        add_event(timeline, event_entity_move(projectile_handle, direction, ability.projectile_speed))

        if target := world_get_entity_at(&game.current_world, new_pos); entity_handle_valid(target) {
            add_event(timeline, event_deal_damage(user_handle, actual_damage, target))

            if !ability.pass_through {
                add_event(timeline, event_destroy_entity(user_handle, projectile_handle))
                if ability.hit_particle != nil {
                    add_event(timeline, event_create_particle(user_handle, ability.hit_particle.?, new_pos))
                }
                break
            }
        }

        current_pos = new_pos
    }
}


// ---------------------------------- !END PROJECTILE! -----------------------------------


// +-------------------------------------------------------------------------------------+
// |                                    !PUSH BURST!                                     |
// +-------------------------------------------------------------------------------------+


// Data for an Ability that shoots a projectile in a straight line.
Ability_Push_Burst :: struct {
    push_distance: i32,
    damage_on_collide: int,

    damage: int,

}


// Schedules the events needed to use an Ability_Projectile.
ability_push_burst :: proc(self: Ability_Slot, confirmation: Ability_Confirmation, user: ^Entity) {
    ability := unwrap_ability_slot(self, Ability_Push_Burst)
    direction := confirmation.(Direction)
    world_size := int(game.current_world.world_size)
    user_handle := new_entity_handle(&game.current_world, user^)

    timeline := &game.current_fight.timeline

    character := user.type.(Character)
    
    
}


// ---------------------------------- !END PUSH BURST! -----------------------------------