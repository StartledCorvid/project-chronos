package game
/*
# Overview
Math procedures used by the game.
*/

import "core:math"


// +---------------------------------------------------------------------------+
// |                             !DECLARATIONS!                                |
// +---------------------------------------------------------------------------+


// A 2D point.
Vector2 :: [2]f32


// A 2D point in integer space.
Vector2i :: [2]i32


// Constant for 2 Pi
PI2 :: math.PI * 2


// --------------------------- !END DECLARATIONS! ------------------------------


// +---------------------------------------------------------------------------+
// |                         !LINEAR INTERPOLATION!                            |
// +---------------------------------------------------------------------------+


// Linearly interpolates two values.
lerp :: proc {
	lerp_float,
	lerp_vec2,
}


// Linearly interpolates the two given floats.
lerp_float :: proc(a, b, t: f32) -> f32 {
	return a + t * (b - a)
}


// Linearly interpolates two 2D points.
lerp_vec2 :: proc(a, b: Vector2, t: f32) -> [2]f32 {
	return {
		lerp_float(a.x, b.x, t),
		lerp_float(a.y, b.y, t),
	}
}


// --------------------- !END LINEAR INTERPOLATION! ----------------------------