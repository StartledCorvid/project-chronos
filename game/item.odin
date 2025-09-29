package game

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
	// Relics
	Relic_Totem_Of_Speed,

	// Gear
	Gear_Adventurers_Gear,
}


@(rodata)
ITEMS := [Item_Name]Item {
	// Relics
	.Relic_Totem_Of_Speed = {
		name = "Totem of Speed",
		description = "Speed. I am speed.",
		icon = .Icon_Totem_Of_Speed,

		type = .Relic,
		rarity = .Common,

		cost = 5,

		trigger_sources = {
			{
				trigger = .On_Hit,
				on_trigger = trigger_heal,
			},
		},
	},	

	// Gear
	.Gear_Adventurers_Gear = {
		name = "Adventurer's Gear",
		description = "Gear for an adevnturer.",
		icon = .Icon_Adventurers_Gear,

		type = .Gear,
		rarity = .Common,

		cost = 5,

		trigger_sources = {
			{
				trigger = .When_Hit,
				on_trigger = trigger_heal,
			},
		},
	},
}


// The different types of items in the game.
Item_Type :: enum {
	Gear,
	Relic,
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

	type: Item_Type,
	rarity: Rarity,

	cost: u32,

	ability: Maybe(Ability_Name),
	trigger_sources: []Trigger_Source,
}


// Holds a list of items and manages caching them by type.
Inventory :: struct {
	gear: Maybe(Item_Name),
	relics: [dynamic]Item_Name, // TODO: Enum Array, with int (count) as the value?
}


inventory_deinit :: proc(inventory: ^Inventory, loc := #caller_location) {
	assert(inventory != nil, "Nil inventory pointer.", loc)
	clear(&inventory.relics)
}


// Adds a Relic to the given Inventory.
add_relic :: proc(inventory: ^Inventory, item_name: Item_Name, loc := #caller_location) {
	assert(inventory != nil, "Nil inventory pointer.", loc)
	assert(ITEMS[item_name].type == .Relic, "Trying to add a Relic that is not of type Relic.", loc)

	append(&inventory.relics, item_name)
}


// Removes a Relic from an inventory.
remove_relic :: proc(inventory: ^Inventory, item_name: Item_Name, loc := #caller_location) {
	assert(inventory != nil, "Nil inventory pointer.", loc)
	assert(ITEMS[item_name].type == .Relic, "Trying to remove a Relic that is not of type Relic.", loc)

	index := len(inventory.relics) - 1
	for index > 0 {
		if inventory.relics[index] == item_name {
			ordered_remove(&inventory.relics, index, loc)
			break
		}
		index -= 1
	}
}


// Equips a piece of gear to the given Entity. This unequips the existing gear. Will
// panic if the Entity is not a Character with an Inventory. This overload is needed
// for Trigger management.
equip_gear :: proc(entity: ^Entity, item_name: Item_Name, loc := #caller_location) {
	assert(entity != nil, "Nil Entity pointer.", loc)
	assert(ITEMS[item_name].type == .Gear, "Trying to equip gear that is not of type Gear.", loc)

	unequip_gear(entity, loc)

	character := &entity.type.(Character)
	character.inventory.gear = item_name

	item := ITEMS[item_name]

	for source in item.trigger_sources {
		register_watcher(&entity.trigger_hub, source, loc)
	}
}


// Unequips the currently equipped peice of gear from the given Entity, if any is
// equipped. Panics if the Entity is not a Character. This overload is needed for Trigger
// management.
unequip_gear :: proc(entity: ^Entity, loc := #caller_location) {
	character := &entity.type.(Character)

	if character.inventory.gear != nil {
		equipped_item := ITEMS[character.inventory.gear.?]
		for source in equipped_item.trigger_sources {
			unregister_watcher(&entity.trigger_hub, source, loc)
		}
	}

	character.inventory.gear = nil
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
		ui_item_tooltip(item, screen_pos, icon_size)
	}

	return icon_size
}


// Draws the list of equipped Relics in the given Inventory. Starts with the top left
// corner in `top_left_corner` on the screen. `max_row` is the maximum amount of
// relics that can appear in a single row before it starts a new one under it.
// Padding is optional, and is the amount of space between Relic icons.
ui_relic_list :: proc(inventory: Inventory, top_left_corner: Vector2, max_row: int, padding := Vector2{ 2, 2 }) {
	max_height  := f32(0)
	next_corner := top_left_corner
	row_count   := 0

	for relic_name in inventory.relics {
		icon_size := ui_item(relic_name, next_corner)

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

