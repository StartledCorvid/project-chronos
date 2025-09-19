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


load_abilities :: proc() -> [Ability_Name]Ability_Info {
    return {
        .None = {},
        .Bash = {
            name = "Bash",
            description = "Move in a straight line and deal damage to the enemy hit.",

            cooldown = 2,
            type = Ability_Bash{
                damage = 1,
                distance = -1,
                pass_through = false,
            },  

            on_use = proc(self: ^Ability, user: Entity_Handle) {
                entity, _, ability := get_ability_info(self, user, Ability_Bash)

                bash_distance := ability.distance < 0 ? int(game.current_world.world_size) : ability.distance
                
                end_pos := entity.position
                for _ in 0..<bash_distance {
                    new_pos := end_pos + DIRECTIONS[ability.direction]

                    world_size := i32(game.current_world.world_size)
                    if new_pos.x >= world_size || new_pos.y >= world_size {
                        break
                    }

                    if !ability.pass_through && !world_space_empty(&game.current_world, new_pos) {
                        break
                    }

                    end_pos = new_pos
                }

                timeline := &game.current_fight.timeline
                add_event(timeline, event_entity_move(user, ability.direction, 0.1))

                if target := world_get_entity_at(&game.current_world, end_pos); entity_handle_valid(target) {
                    add_event(timeline, event_lunge(user, ability.direction, 0.5, 0.05))
                    add_event(timeline, event_deal_damage(user, ability.damage, target))
                }

                self.cooldown_time = self.base.cooldown
            },

            draw_preview = proc(self: ^Ability, user: Entity_Handle) {
                entity, _, ability := get_ability_info(self, user, Ability_Bash)

                bash_distance := ability.distance < 0 ? int(game.current_world.world_size) : ability.distance

                current_pos := entity.position 
                for _ in 0..<bash_distance {
                    new_pos := current_pos + DIRECTIONS[ability.direction]

                    world_size := i32(game.current_world.world_size)
                    if new_pos.x >= world_size || new_pos.y >= world_size {
                        break
                    }

                    screen_pos := world_to_screen(new_pos)
                    rl.DrawRectangleV(screen_pos, { WORLD_UNITS, WORLD_UNITS }, { 255, 0, 0, 125 })

                    if !ability.pass_through && !world_space_empty(&game.current_world, new_pos) {
                        break
                    }

                    current_pos = new_pos
                }
            },

            can_use = ability_cooled_down,
        },
    }
}


Ability_Info :: struct {
    name: string,
    description: string,

    cooldown: int,
    type: Ability_Type,

    on_use:       proc(self: ^Ability, user: Entity_Handle),
    can_use:      proc(self: ^Ability, user: Entity_Handle) -> bool,
    draw_preview: proc(self: ^Ability, user: Entity_Handle),
}


Ability :: struct {
    base: ^Ability_Info,
    cooldown_time: int,
}


Ability_Type :: union {
    Ability_Bash,
}


Ability_Bash :: struct {
    direction: Direction, // The direction of the bash attack.
    damage: int,          // The damage done when it hits an Entity.
    distance: int,        // -1 is as far as possible.
    pass_through: bool,   // If true, will not stop once it hits a solid Entity.

    move_speed: f32,
}


ability_valid :: proc(ability: Ability) -> bool {
    return ability.base != nil && ability.base != &game.abilities[.None]
}


// Creates a new instance of an Ability.
new_ability :: proc(ability_name: Ability_Name) -> Ability {
    return {
        base = &game.abilities[ability_name],
        cooldown_time = 0,
    }
}


@(private="file")
ability_cooled_down :: proc(self: ^Ability, _: Entity_Handle) -> bool {
    return self.cooldown_time <= 0
}


// Gets the information needed for an Ability.
@(private="file")
get_ability_info :: proc(ability: ^Ability, user_handle: Entity_Handle, $T: typeid) -> (^Entity, Character, T) {
    entity := get_entity(user_handle)
    if entity == nil {
        panic("Trying to use an Ability using an Entity that is not valid.")
    }

    ability, ability_ok := ability.base.type.(T)
    if !ability_ok {
        panic("Ability is not of right type.")
    }

    character, char_ok := entity.type.(Character)
    if !char_ok {
        panic("Entity is not of type Character.")
    }

    return entity, character, ability
}