package game

World_Names :: enum {
    Default,
}

@(rodata)
world_data_list := [World_Names]World_Data{
    .Default = {
        tile_texture_path = "res/images/dirt_tile.png",
        world_size = 2,
    },
}