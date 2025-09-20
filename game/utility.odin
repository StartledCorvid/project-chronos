package game

import "core:fmt"


// Panics the program using the given format string as a message.
panicf :: proc(formatted: string, args: ..any) {
    panic(fmt.tprintf(formatted, args))
}