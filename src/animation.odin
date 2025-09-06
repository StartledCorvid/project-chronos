package game

import rl "vendor:raylib"


Animator :: struct {
	// TODO: State machine?
	current_animation: Animation,
	play: bool,

	_t: f32,
}


Animation :: struct {
	starting_frame: i32,
	ending_frame:   i32,
	loop_count:     i32, // Make -1 for infinite.
	fps:            i32,
	current_frame:  rl.Rectangle,

	atlas: Texture_Atlas,
}


// Plays the given `Animation` on an `Animator`.
animation_play :: proc(animator: ^Animator, animation: Animation) {
	animator.current_animation = animation
	animator._t = 0
	animator.play = true
}


// Checks if the given `Animation` is setup and valid.
is_animation_valid :: proc(animation: Animation) -> bool {
	return animation.atlas.texture != nil
}


// Plays the current animation on the given `Animator`.
animator_play :: proc(animator: ^Animator, loc := #caller_location) {
	assert(animator != nil, "Nil Animator pointer.", loc)
	assert(is_animation_valid(animator.current_animation), "No valid Animation set.", loc)

	animator.play = true
	animator._t = 0
}


// Pauses the given `Animator`'s playback.
animator_pause :: proc(animator: ^Animator) {
	animator.play = false
}


// Has the given `Animator` pass a tick, given the amount of time since last frame.
animator_tick :: proc(animator: ^Animator, delta_time: f32, loc := #caller_location) {
	assert(animator != nil, "Nil Animator pointer.", loc)
	if !animator.play {
		return
	}

	animator._t += delta_time

	animation     := &animator.current_animation
	frame_count   := (animation.ending_frame - animation.starting_frame) + 1
	frames_passed := i32(animator._t * f32(animation.fps))

	current_frame_index := (frames_passed % frame_count) + animation.starting_frame

	atlas := animation.atlas

	animation.current_frame = rl.Rectangle{
		x = f32(current_frame_index % animation.atlas.texture_count.x * animation.atlas._frame_size.x),
		y = f32(current_frame_index / animation.atlas.texture_count.y * animation.atlas._frame_size.y),

		width  = f32(atlas._frame_size.x),
		height = f32(atlas._frame_size.y),
	}
}
