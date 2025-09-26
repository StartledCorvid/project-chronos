package game

import rl "vendor:raylib"

/*
# Overview
*/


Sound_Name :: enum {
    Hit_0,
}


load_sounds :: proc() -> [Sound_Name]rl.Sound {
    return {
        .Hit_0 = rl.LoadSound("res/sounds/hit_0.wav"),
    }
}