package game
/*

*/

import "core:log"
import rl "vendor:raylib"


Texture_Atlas :: struct {
    texture: Texture_Name,
    texture_count: Vector2i,

    _frame_size: Vector2i,
}


Texture_Name :: enum {
    Tile_Dirt,

    Fighter,
    Goblin,

    Puff,
}


load_textures :: proc() -> [Texture_Name]rl.Texture {
    textures := [Texture_Name]rl.Texture{
        .Tile_Dirt = rl.LoadTexture("res/images/dirt_tile.png"),

        .Fighter = rl.LoadTexture("res/images/fighter.png"),
        .Goblin = rl.LoadTexture("res/images/goblin.png"),

        .Puff = rl.LoadTexture("res/images/puff.png"),
    }

    when ODIN_DEBUG {
        for texture, texture_name in textures {
            log.debugf("Loaded texture %v: (width: %v, height: %v)", texture_name, texture.width, texture.height)
        }
    }

    return textures
}


// Creates a new `Texture_Atlas`.
new_texture_atlas :: proc(texture_name: Texture_Name, frame_count: Vector2i) -> Texture_Atlas {
    texture := get_texture(texture_name)
    log.debugf("Info for %V: Count X: %v, Count Y: %v, width: %v, height: %v", texture_name, frame_count.x, frame_count.y, texture.width, texture.height)
    frame_size := Vector2i{
        texture.width / frame_count.x,
        texture.height / frame_count.y,
    }

    return {
        texture = texture_name,
        texture_count = frame_count,
        _frame_size = frame_size,
    }
}


get_texture :: proc(texture_name: Texture_Name) -> rl.Texture {
    return game.textures[texture_name]
}
