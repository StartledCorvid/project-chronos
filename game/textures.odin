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
    Wizard,
    Goblin,
    Spider,
    Minotaur,

    Icon_Fighter,
    Icon_Wizard,
    Icon_Goblin,
    Icon_Spider,
    Icon_Minotaur,

    Icon_Bash,
    Icon_Push_Burst,
    Icon_Fireball,
    Icon_Collide,

    Puff,
    Fireball,
    Fire_Explode,

    Icon_Totem_Of_Speed,
    Icon_Adventurers_Gear,

    Icon_Fire_Sprite,
    Icon_Lightning_Sprite,
    Icon_Might_Shield,
    Icon_Poison_Vial,
    Icon_Potion_Of_Healing,
    Icon_Ruby_Amulet,
    Icon_Serrated_Edge,
    Icon_Skull_Ring,
    Icon_Wizards_Orb,
}


load_textures :: proc() -> [Texture_Name]rl.Texture {
    defer log.infof("Loaded %v Textures.", len(Texture_Name))
    return [Texture_Name]rl.Texture{
        .Tile_Dirt       = rl.LoadTexture("res/images/dirt_tile.png"),

        .Fighter         = rl.LoadTexture("res/images/fighter.png"),
        .Wizard          = rl.LoadTexture("res/images/wizard.png"),
        .Goblin          = rl.LoadTexture("res/images/goblin.png"),
        .Spider          = rl.LoadTexture("res/images/spider.png"),
        .Minotaur        = rl.LoadTexture("res/images/minotaur.png"),

        .Icon_Fighter    = rl.LoadTexture("res/images/icon_fighter.png"),
        .Icon_Wizard     = rl.LoadTexture("res/images/icon_wizard.png"),
        .Icon_Goblin     = rl.LoadTexture("res/images/icon_goblin.png"),
        .Icon_Spider     = rl.LoadTexture("res/images/icon_spider.png"),
        .Icon_Minotaur   = rl.LoadTexture("res/images/icon_minotaur.png"),
        .Icon_Collide    = rl.LoadTexture("res/images/icon_collide.png"),

        .Icon_Bash       = rl.LoadTexture("res/images/icon_bash.png"),
        .Icon_Push_Burst = rl.LoadTexture("res/images/icon_push_burst.png"),
        .Icon_Fireball   = rl.LoadTexture("res/images/icon_fireball.png"),

        .Puff            = rl.LoadTexture("res/images/puff.png"),
        .Fireball        = rl.LoadTexture("res/images/fireball.png"),
        .Fire_Explode    = rl.LoadTexture("res/images/fire_explode.png"),

        .Icon_Totem_Of_Speed   = rl.LoadTexture("res/images/icon_totem_of_speed.png"),
        .Icon_Adventurers_Gear = rl.LoadTexture("res/images/icon_adventurers_gear.png"),

        .Icon_Fire_Sprite       = rl.LoadTexture("res/images/items/item_fire_sprite.png"),
        .Icon_Lightning_Sprite  = rl.LoadTexture("res/images/items/item_lightning_sprite.png"),
        .Icon_Might_Shield      = rl.LoadTexture("res/images/items/item_mighty_shield.png"),
        .Icon_Poison_Vial       = rl.LoadTexture("res/images/items/item_poison_vial.png"),
        .Icon_Potion_Of_Healing = rl.LoadTexture("res/images/items/item_potion_of_healing.png"),
        .Icon_Ruby_Amulet       = rl.LoadTexture("res/images/items/item_ruby_amulet.png"),
        .Icon_Serrated_Edge     = rl.LoadTexture("res/images/items/item_serrated_edge.png"),
        .Icon_Skull_Ring        = rl.LoadTexture("res/images/items/item_skull_ring.png"),
        .Icon_Wizards_Orb       = rl.LoadTexture("res/images/items/item_wizards_orb.png"),
    }
}


// Creates a new `Texture_Atlas`.
new_texture_atlas :: proc(texture_name: Texture_Name, frame_count: Vector2i) -> Texture_Atlas {
    texture := get_texture(texture_name)
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
