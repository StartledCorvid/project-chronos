package game

import "core:math/rand"
import "core:log"
import rl "vendor:raylib"


/*
# Overview
Handles the data and procedures done to manage items.

# Creating New Items
1. Add a new name to the Item_Name enum.
2. Add a matching entry to the ITEMS array.

# Creating a New Item Type/Slot Type
I would recommend against this. You decided that keeping it as two things
was design enough and would keep it simple. However, things are set up to
where you would just need to add a new entry to the Item_Type enum below.
*/





// The names of each Item in the game.
Item_Name :: enum {
    Fire_Sprite,
    Lightning_Sprite,
    Mighty_Shield,
    Poison_Vial,
    Potion_Of_Healing,
    Ruby_Amulet,
    Serrated_Edge,
    Skull_Ring,
    Wizards_Orb,
}


Item_Instance :: struct {
	base: Item_Name,
	level: int,
}


@(rodata)
ITEMS := [Item_Name]Item {
    .Fire_Sprite = {
    	name        = "Fire Sprite",
    	description = "Doing Fire damage restores {amount} HP.",
    	icon        = .Icon_Fire_Sprite,

    	rarity      = .Uncommon,
    	drop_weight = 100,

    	// TODO: Triggers
    	// TODO: Upgrade path.

    	trigger_sources = {
    		{
    			trigger = .On_Hit,
    			on_trigger = proc(self_name: Item_Name, payload: Trigger_Payload) {
    				if !entity_handle_valid(payload.target) {
    					return
    				}

    				instance := game.player_data.inventory.items[self_name]
    				damage_character(nil, payload.target, instance.level)
    			},
    		},
    	},
    },

    .Lightning_Sprite = {},

    .Mighty_Shield = {},

    .Poison_Vial = {},

    .Potion_Of_Healing = {},

    .Ruby_Amulet = {},

    .Serrated_Edge = {},

    .Skull_Ring = {},

    .Wizards_Orb = {},
}


// The different item rarities that determine how frequently them drop.
Rarity :: enum {
	Common,
	Uncommon,
	Rare,
	Legendary,
}


// Colors tied to each rarity.
@(rodata)
RARITY_COLORS := [Rarity]rl.Color {
	.Common    = { 0, 255, 0, 255 },
	.Uncommon  = { 0, 0, 255, 255 },
	.Rare      = { 255, 0, 255, 255 },
	.Legendary = { 255, 255, 75, 255 },
}


// Information that makes up an Item.
Item :: struct {
	name: string,
	description: string,
	icon: Texture_Name,

	rarity: Rarity,
	// Higher weight means more likely to drop.
	drop_weight: int,
	// The drop weight of the item when the player already has it.
	// A duplicate drop means that an upgrade opportunity will be given.
	upgrade_weight: int, 

	cost: u32,

	trigger_sources: []Trigger_Source,
}


// Holds a list of items and manages caching them by type.
Inventory :: struct {
	items: [Item_Name]Item_Instance, // TODO: Enum Array, with int (count) as the value?
    trigger_hub: Trigger_Hub,
}


inventory_deinit :: proc(inventory: ^Inventory, loc := #caller_location) {
	assert(inventory != nil, "Nil inventory pointer.", loc)

	for &item in inventory.items {
		item.level = 0
	}
}


activate_item_triggers :: proc(trigger_hub: ^Trigger_Hub, item_name: Item_Name, loc := #caller_location) {
	assert(trigger_hub != nil, "Nil Trigger_Hub pointer.", loc)

	item := ITEMS[item_name]
	for source in item.trigger_sources {
		register_watcher(trigger_hub, source, item_name, loc)
	}
}


deactivate_item_triggers :: proc(trigger_hub: ^Trigger_Hub, item: Item, loc := #caller_location) {
	assert(trigger_hub != nil, "Nil Trigger_Hub pointer.", loc)
	for source in item.trigger_sources {
		unregister_watcher(trigger_hub, source, loc)
	}
}


// Adds an Item to the Entity's Inventory.
add_item :: proc(inventory: ^Inventory, item_name: Item_Name, loc := #caller_location) {
	assert(inventory != nil, "Nil Inventory pointer.", loc)

	inventory.items[item_name].base = item_name
	inventory.items[item_name].level += 1

	activate_item_triggers(&inventory.trigger_hub, item_name, loc)
}


// Removes an Item from the Entity's inventory.
remove_item :: proc(inventory: ^Inventory, item_name: Item_Name, loc := #caller_location) {
	assert(inventory != nil, "Nil Inventory pointer.", loc)
	inventory.items[item_name].level = 0

	item := ITEMS[item_name]
	deactivate_item_triggers(&inventory.trigger_hub, item, loc)
}


// TODO: Move to a dedicated file?
trigger_heal :: proc(payload: Trigger_Payload) {

	
	
	log.infof("Triggered heal. Event: %v", payload.trigger)
	// TODO: Actual logic. This is just for testing.
}


// Draws the icon of the given Item. Returns the size of the image drawn.
ui_item :: proc(item_name: Item_Name, screen_pos: Vector2) -> Vector2 {
	item      := ITEMS[item_name]
	item_icon := get_texture(item.icon)
	icon_size := Vector2 {
		f32(item_icon.width),
		f32(item_icon.height),
	}

	rl.DrawTextureV(item_icon, screen_pos, rl.WHITE)

	mouse_pos := screen_to_render_point(rl.GetMousePosition())
	hit_rect := rl.Rectangle{
		x = screen_pos.x,
		y = screen_pos.y,
		width = icon_size.x,
		height = icon_size.y,
	}

	if rl.CheckCollisionPointRec(to_vector2(mouse_pos), hit_rect) {
		ui_item_tooltip(item, to_vector2(mouse_pos))
	}

	return icon_size
}


// Draws the list of equipped Relics in the given Inventory. Starts with the top left
// corner in `top_left_corner` on the screen. `max_row` is the maximum amount of
// relics that can appear in a single row before it starts a new one under it.
// Padding is optional, and is the amount of space between Relic icons.
ui_item_list :: proc(inventory: Inventory, top_left_corner: Vector2, max_row: int, padding := Vector2{ 2, 2 }) {
	max_height  := f32(0)
	next_corner := top_left_corner
	row_count   := 0

	for instance in inventory.items {
		if instance.level == 0 {
			continue
		}

		icon_size := ui_item(instance.base, next_corner)

		if icon_size.y > max_height {
			max_height = icon_size.y
		}

		next_corner.x += icon_size.x + padding.x

		row_count += 1
		if row_count % max_row == 0 {
			next_corner.x = top_left_corner.x
			next_corner.y += max_height + padding.y

			row_count = 0
			max_height = 0
		}
	}
}


// Gets a random weighted Item drop.
get_drop :: proc() -> Item_Name {
	max_weight := DROP_TABLE[len(DROP_TABLE) - 1].cumulative_weight
	random_weight := rand.int_max(max_weight + 1)

	for drop_entry in DROP_TABLE {
		if drop_entry.cumulative_weight >= random_weight {
			return drop_entry.item_name
		}
	}

	panic("Somehow couldn't find the proper item to drop.")
}


@(private="file")
Drop_Table :: [len(ITEMS)]Drop_Table_Entry


@(private="file")
Drop_Table_Entry :: struct {
	item_name: Item_Name,
	cumulative_weight: int,
}


@(private="file")
DROP_TABLE := generate_drop_table()


@(private="file")
generate_drop_table :: proc "contextless" () -> Drop_Table {
	table: Drop_Table

	cumulative_weight := 0
	for item, item_name in ITEMS {
		cumulative_weight += item.drop_weight

		table[item_name] = Drop_Table_Entry{
			cumulative_weight = cumulative_weight,
			item_name = item_name,
		}
	}

	return table
}
