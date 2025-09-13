package gen

import "core:log"
// import "core:io"
// import "core:os"

/*
# Overview
Handles codegen for the Chronos project. Looks through the res folder
and creates hard-coded lookups for each image, animation, etc.
*/


main :: proc() {
    logger := log.create_console_logger()
    defer log.destroy_console_logger(logger)

    context.logger = logger

    // gen_fights("res/fights", "game/gen_fights.odin")
}
