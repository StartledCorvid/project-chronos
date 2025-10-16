package game

import "core:log"
import "core:math/rand"
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


Damage_Type :: enum {
	None,
	Impact,
	Piercing,
	Slicing,
	Fire,
}


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
    	description = "Doing Fire damage restores (2 * LVL) HP.",
    	icon        = .Icon_Fire_Sprite,

    	rarity      = .Uncommon,
    	drop_weight = 100,

    	// TODO: Upgrade path.

    	trigger_sources = {
    		{
    			type = .On_Hit,
    			on_trigger = proc(self: Trigger_Listener, payload: Trigger_Payload) {
    				BASE_HEAL :: 1
    				data := payload.(Trigger_On_Hit)

    				if data.damage_type != .Fire {
    					return
    				}

    				heal_amount := BASE_HEAL * self.source.level
    				heal_character(data.attacker, heal_amount)
    				log.debugf("Triggered Fire Sprite and healed %v", heal_amount)
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
		if item.level > 0 {
			remove_item(inventory, item.base)
		}
	}
}


activate_item_triggers :: proc(item_instance: ^Item_Instance, loc := #caller_location) {
	assert(item_instance != nil, "Nil Item_Instance pointer.", loc)

	item := ITEMS[item_instance.base]
	for source in item.trigger_sources {
		listener := Trigger_Listener{
			on_trigger = source.on_trigger,
			source = item_instance,
			type = source.type,
		}
		register_trigger(listener, loc)
	}
}


deactivate_item_triggers :: proc(item_instance: ^Item_Instance, loc := #caller_location) {
	assert(item_instance != nil, "Nil Item_Instance pointer.", loc)

	item := ITEMS[item_instance.base]
	for source in item.trigger_sources {
		listener := Trigger_Listener{
			on_trigger = source.on_trigger,
			source = item_instance,
			type = source.type,
		}
		unregister_trigger(listener, loc)
	}
}


// Adds an Item to the Entity's Inventory.
add_item :: proc(inventory: ^Inventory, item_name: Item_Name, loc := #caller_location) {
	assert(inventory != nil, "Nil Inventory pointer.", loc)

	inventory.items[item_name].base = item_name

	if inventory.items[item_name].level <= 0 {
		activate_item_triggers(&inventory.items[item_name], loc)
	}

	inventory.items[item_name].level += 1
}


// Removes an Item from the Entity's inventory.
remove_item :: proc(inventory: ^Inventory, item_name: Item_Name, loc := #caller_location) {
	assert(inventory != nil, "Nil Inventory pointer.", loc)
	inventory.items[item_name].level = 0

	deactivate_item_triggers(&inventory.items[item_name], loc)
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
