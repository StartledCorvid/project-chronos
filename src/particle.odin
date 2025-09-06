package game
/*
# Overview
Handles the Particle system.
*/


MAX_PARTICLES :: 1000


Particle_Type :: union {
    Burst_Particle,
    Loop_Particle,
}


// Does a singular burst of particles, then ends.
Burst_Particle :: struct {
    burst_count: int,

}


// A particle that loops, emitting over and over until it is destroyed.
Loop_Particle :: struct {

}


Particle :: struct {
    type: Particle_Type,
}


Particle_Emitter :: struct {
    emit_count: int,
    
}