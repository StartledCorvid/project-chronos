package game

import "core:fmt"


to_vector2 :: proc{
    vector2i_to_vector2,
}


vector2i_to_vector2 :: proc(v: Vector2i) -> Vector2 {
    return {
        f32(v.x),
        f32(v.y),
    }
}


to_vector2i :: proc{
    vector2_to_vector2i,
}


vector2_to_vector2i :: proc(v: Vector2) -> Vector2i {
    return {
        i32(v.x),
        i32(v.y),
    }
}


// Panics the program using the given format string as a message.
panicf :: proc(formatted: string, args: ..any) {
    panic(fmt.tprintf(formatted, args))
}