package gen

import "core:log"

/*
# Overview
Handles codegen for the Chronos project. Looks through the res folder
and creates hard-coded lookups for each image, animation, etc.
*/


main :: proc() {
    logger := log.create_console_logger()
    defer log.destroy_console_logger(logger)

    context.logger = logger

    gen_fights("embed/fights", "game/gen_content_fights.odin")
}
