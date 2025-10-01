package game

import "core:log"

/*
# Overview
Handles the Particle system.

# Creating a New Particle Template
1. Add to the Particle_Name enum.
2. Create an entry in the load_particles proc for the new enum entry.
*/


Particle_Name :: enum {
    Puff,
    Fireball,
    Fire_Explode,
}


Particle :: struct {
    animation: Animation,

    start_offset: Vector2,
    end_offset: Vector2,

    _total_lifespan: f32,
}


load_particles :: proc() -> [Particle_Name]Particle {
    defer log.infof("Loaded %v Particles.", len(Particle_Name))
    return {
        .Puff = {
            animation = {
                atlas = new_texture_atlas(.Puff, { 6, 1 }),
                fps = 12,
                loop_count = 1,
                starting_frame = 0,
                ending_frame = 5,
            },
        },

        .Fireball = {
            animation = {
                atlas = new_texture_atlas(.Fireball, { 3, 1 }),
                starting_frame = 0,
                ending_frame = 2,
                fps = 9,
                loop_count = -1,
            },
        },

        .Fire_Explode = {
            animation = {
                atlas = new_texture_atlas(.Fire_Explode, { 5, 1}),
                fps = 12,
                loop_count = 1,
                starting_frame = 0,
                ending_frame = 4,
            },
        },
    }
}


new_particle :: proc {
    new_custom_particle,
    new_template_particle,
}


new_custom_particle :: proc(location: World_Coords, particle: Particle, layer: int = 0, loc := #caller_location) -> Entity_Handle {
    handle := new_entity(&game.current_world)
    entity := get_entity(handle)

    entity.position = location
    entity.offset = particle.start_offset
    entity.layer = layer

    mut_particle := particle

    total_frames := (mut_particle.animation.ending_frame - mut_particle.animation.starting_frame) + 1
    seconds_per_cycle := f32(total_frames) / f32(mut_particle.animation.fps)

    mut_particle._total_lifespan = f32(mut_particle.animation.loop_count) * seconds_per_cycle
    entity.type = mut_particle

    animation_play(&entity.animator, particle.animation)

    return handle
}


new_template_particle :: proc(location: World_Coords, particle: Particle_Name, layer: int = 0, loc := #caller_location) -> Entity_Handle {
    return new_custom_particle(location, game.particles[particle], layer, loc)
}


tick_particle :: proc(self: ^Entity) {
    // particle := self.type.(Particle)
    // self.offset = lerp(self.offset, particle.end_offset, self.animator._t / particle._total_lifespan)
    handle := new_entity_handle(&game.current_world, self^)
    if !self.animator.play {
        free_entity(handle)
    }
}