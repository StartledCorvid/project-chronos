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
    Ability_Push,
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
                push_distance = 2,
                damage_on_collide = 1,
                collide_particle = .Puff,

                damage = 0,

                move_speed = 0.2,
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
                use_sound = .Hit_0,
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


ABILITY_PREVIEW_RED   :: rl.Color{ 255, 0, 0, 125 }
ABILITY_PREVIEW_GREEN :: rl.Color{ 0, 255, 0, 125 }


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
    timeline := &game.current_fight.timeline

    switch type in ability_info.type {
    case Ability_Bash:       ability_bash(type, confirmation, user, timeline)
    case Ability_Push:       ability_push(type, confirmation, user, timeline)
    case Ability_Push_Burst: ability_push_burst(type, confirmation, user, timeline)
    case Ability_Projectile: ability_projectile(type, confirmation, user, timeline)
    }

    ability_slot.cooldown = ability_info.cooldown + 1
}


// Draws the preview for the given ability.
draw_ability_preview :: proc(self: Entity, ability_info: Ability_Info) {
    switch ability in ability_info.type {
    case Ability_Bash:
        draw_directional_ability_preview(self, ability.distance, ability.pass_through)
    case Ability_Push:
        draw_preview_push(self, ability.push_distance)
    case Ability_Push_Burst:
        draw_preview_push(self, ability.push_distance)
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

            if outside_of_world(game.current_world, new_pos) {
                break
            }

            screen_pos := grid_to_world_point(new_pos)

            if !pass_through && !world_space_empty(&game.current_world, new_pos) {
                rl.DrawRectangleV(to_vector2(screen_pos), { WORLD_UNITS, WORLD_UNITS }, ABILITY_PREVIEW_RED)
                break
            }

            rl.DrawRectangleV(to_vector2(screen_pos), { WORLD_UNITS, WORLD_UNITS }, ABILITY_PREVIEW_GREEN)

            current_pos = new_pos
        }
    }
}


draw_preview_push :: proc(user: Entity, distance: int, collide_texture := Texture_Name.Icon_Collide) {
    world_size    := int(game.current_world.world_size)
    push_distance := distance <= 0 ? world_size : distance
    collide_icon  := get_texture(collide_texture)

    for direction in DIRECTIONS {
        target_location := user.position + direction
        if outside_of_world(game.current_world, target_location) {
            continue
        }

        // Draw target rectangle.
        target_screen_pos := to_vector2(grid_to_world_point(target_location))
        rl.DrawRectangleV(target_screen_pos, { WORLD_UNITS, WORLD_UNITS }, ABILITY_PREVIEW_RED)

        target_handle := world_get_entity_at(&game.current_world, target_location)
        if !entity_handle_valid(target_handle) {
            continue
        }

        push_pos := target_location

        // Draw push path.
        for _ in 0..<push_distance {
            next_pos := push_pos + direction
            target_screen_pos = to_vector2(grid_to_world_point(next_pos))

            // Hit world edge.
            if outside_of_world(game.current_world, next_pos) {
                collide_space := to_vector2(grid_to_world_point(push_pos))
                rl.DrawTextureV(collide_icon, collide_space, rl.WHITE)
                break
            }

            // Hits an Entity.
            if !world_space_empty(&game.current_world, next_pos) {
                rl.DrawRectangleV(target_screen_pos, { WORLD_UNITS, WORLD_UNITS }, ABILITY_PREVIEW_RED)
                rl.DrawTextureV(collide_icon, target_screen_pos, rl.WHITE)
                break
            }

            rl.DrawRectangleV(target_screen_pos, { WORLD_UNITS, WORLD_UNITS }, ABILITY_PREVIEW_GREEN)
            push_pos = next_pos
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
ability_bash :: proc(self: Ability_Bash, confirmation: Ability_Confirmation, user: ^Entity, timeline: ^Timeline) {
    direction := confirmation.(Direction)
    world_size := int(game.current_world.world_size)

    bash_distance := self.distance <= 0 ? world_size : self.distance

    user_handle := new_entity_handle(&game.current_world, user^)

    character, ok := to_character(user)
    assert(ok, "Not a Character.")

    actual_damage := self.damage + int(modifier_value(character.base.stats, self.damage_modifier))

    OVERSTEP_TIME :: 0.1
    end_pos := user.position

    for _ in 0..<bash_distance {
        new_pos := end_pos + DIRECTIONS[direction]

        if outside_of_world(game.current_world, new_pos) {
            add_event(timeline, event_lunge(user_handle, direction, 0.5, OVERSTEP_TIME))
            break
        }

        if !self.pass_through && !world_space_empty(&game.current_world, new_pos) {
            break
        }

        end_pos = new_pos
        add_event(timeline, event_entity_move(user_handle, direction, self.move_speed))
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
    use_sound: Maybe(Sound_Name),
    
    damage: int,
    damage_modifier: Modifier,

    range: int,
    pass_through: bool,
    projectile_speed: f32,

    projectile_particle: Particle_Name,
    hit_particle: Maybe(Particle_Name),
}


// Schedules the events needed to use an Ability_Projectile.
ability_projectile :: proc(self: Ability_Projectile, confirmation: Ability_Confirmation, user: ^Entity, timeline: ^Timeline) {
    direction := confirmation.(Direction)
    world_size := int(game.current_world.world_size)
    user_handle := new_entity_handle(&game.current_world, user^)

    projectile_distance := self.range <= 0 ? world_size : self.range

    character, ok := to_character(user)
    assert(ok, "Not a Character.")

    actual_damage := self.damage + int(modifier_value(character.base.stats, self.damage_modifier))

    projectile_handle := new_particle(user.position, self.projectile_particle)

    if self.use_sound != nil {
        add_event(timeline, event_play_sound(user_handle, self.use_sound.?))
    }

    current_pos := user.position
    for _ in 0..<projectile_distance {
        new_pos := current_pos + DIRECTIONS[direction]

        if outside_of_world(game.current_world, new_pos) {
            add_event(timeline, event_destroy_entity(user_handle, projectile_handle))
            if self.hit_particle != nil {
                add_event(timeline, event_create_particle(user_handle, self.hit_particle.?, current_pos))
            }
            break
        }

        add_event(timeline, event_entity_move(projectile_handle, direction, self.projectile_speed))

        if target := world_get_entity_at(&game.current_world, new_pos); entity_handle_valid(target) {
            add_event(timeline, event_deal_damage(user_handle, actual_damage, target))

            if !self.pass_through {
                add_event(timeline, event_destroy_entity(user_handle, projectile_handle))
                if self.hit_particle != nil {
                    add_event(timeline, event_create_particle(user_handle, self.hit_particle.?, new_pos))
                }
                break
            }
        }

        current_pos = new_pos
    }
}


// ---------------------------------- !END PROJECTILE! -----------------------------------


// +-------------------------------------------------------------------------------------+
// |                                       !PUSH!                                        |
// +-------------------------------------------------------------------------------------+


// Data for an Ability that pushes an adjacent target and damages it if it collides with
// another Entity or the edge of the map.
Ability_Push :: struct {
    push_distance: int,
    damage_on_collide: int,
    collide_particle: Maybe(Particle_Name),

    damage: int,
    damage_modifier: Modifier,

    direction: Direction,
    move_speed: f32,

    push_animation: bool,
    push_particle: Maybe(Particle_Name),
}


// Schedules the events needed to use an Ability_Push.
ability_push :: proc(self: Ability_Push, confirmation: Ability_Confirmation, user: ^Entity, timeline: ^Timeline) {
    direction := confirmation.(Direction)

    world_size := int(game.current_world.world_size)
    push_distance := self.push_distance > 0 ? self.push_distance : world_size

    user_handle := new_entity_handle(&game.current_world, user^)
    
    character, ok := to_character(user)
    assert(ok, "Not a Character.")

    lunge_time := self.move_speed / 2
    actual_damage := self.damage + int(modifier_value(character.base.stats, self.damage_modifier))

    // Do little shove animation, if configured.
    if self.push_animation {
        add_event(timeline, event_lunge(user_handle, direction, 0.5, lunge_time))
    }

    // Get Entity to push. If there is not one present, end the ability.
    pushed_handle := world_get_entity_at(&game.current_world, user.position + DIRECTIONS[direction])
    if !entity_handle_valid(pushed_handle) {
        return
    }
    pushed_entity := get_entity(pushed_handle)

    // Deal damage to pushed Entity.
    add_event(timeline, event_deal_damage(user_handle, actual_damage, pushed_handle))
    if self.push_particle != nil {
        add_event(timeline, event_create_particle(user_handle, self.push_particle.?, pushed_entity.position))
    }

    push_pos := pushed_entity.position

    // Schedule events for pushing entity.
    for _ in 0..<push_distance {
        new_pos := push_pos + DIRECTIONS[direction]

        // Hit world edge.
        if outside_of_world(game.current_world, new_pos) {
            add_event(timeline, event_lunge(pushed_handle, direction, 0.5, lunge_time))

            if self.collide_particle != nil {
                add_event(timeline, event_create_particle(user_handle, self.collide_particle.?, push_pos))
            }

            add_event(timeline, event_deal_damage(user_handle, self.damage_on_collide, pushed_handle))
            break
        }

        // Hit an Entity.
        if !world_space_empty(&game.current_world, new_pos) {
            hit_entity := world_get_entity_at(&game.current_world, new_pos)
            add_event(timeline, event_lunge(pushed_handle, direction, 0.5, lunge_time))

            if self.collide_particle != nil {
                add_event(timeline, event_create_particle(user_handle, self.collide_particle.?, push_pos))
            }

            add_event(timeline, event_deal_damage(user_handle, self.damage_on_collide, pushed_handle))
            add_event(timeline, event_lunge(hit_entity, direction, 0.5, lunge_time))
            break
        }

        push_pos = new_pos
        add_event(timeline, event_entity_move(pushed_handle, direction, self.move_speed))
    }
}


// ------------------------------------- !END PUSH! --------------------------------------


// +-------------------------------------------------------------------------------------+
// |                                    !PUSH BURST!                                     |
// +-------------------------------------------------------------------------------------+


// Data for an Ability that shoots a projectile in a straight line.
Ability_Push_Burst :: struct {
    push_distance: int,
    damage_on_collide: int,
    collide_particle: Maybe(Particle_Name),

    damage: int,
    damage_modifier: Modifier,

    move_speed: f32,
    push_particle: Maybe(Particle_Name),
}


// Schedules the events needed to use an Ability_Projectile.
ability_push_burst :: proc(self: Ability_Push_Burst, _: Ability_Confirmation, user: ^Entity, timeline: ^Timeline) {
    user_handle := new_entity_handle(&game.current_world, user^)
    
    found_targets: [dynamic]Entity_Handle
    defer delete(found_targets)

    // Get adjacent entities.
    adjacent_entities: [Direction]Entity_Handle
    for direction in Direction {
        pos := user.position + DIRECTIONS[direction]
        entity_handle := world_get_entity_at(&game.current_world, pos)

        if entity_handle_valid(entity_handle) {
            adjacent_entities[direction] = entity_handle
        }
    }

    // Push each adjacent enemy away.
    event := event_branch(user_handle, 4)
    branch := &event.type.(Event_Branch)

    for direction in Direction {
        if !entity_handle_valid(adjacent_entities[direction]) {
            continue
        }

        push := Ability_Push{
            push_distance = self.push_distance,
            damage_on_collide = self.damage_on_collide,
            collide_particle = self.collide_particle,

            damage = self.damage,
            damage_modifier = self.damage_modifier,

            direction = direction,
            move_speed = self.move_speed,

            push_animation = false,
            push_particle = self.push_particle,
        }

        ability_push(push, direction, user, &branch.timelines[direction])
    }

    add_event(timeline, event)
}


// ---------------------------------- !END PUSH BURST! -----------------------------------