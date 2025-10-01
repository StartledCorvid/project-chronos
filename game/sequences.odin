package game


/*
# Overview
A collection of procedures that create a premade sequence of Events.
*/


// Creates a sequence of Events that makes the Character do a lunge animation.
// `entity_handle` is a Entity_Handle for the Entity to do the lunge animation.
// `lunge` is the translation that the lunge will do.
// `total_time` is the total amount of time (in seconds) that the lunge will take.
sequence_lunge :: proc(timeline: ^Timeline, entity_handle: Entity_Handle, direction: Direction, total_time: f32, lunge_distance: f32 = LUNGE_DISTANCE, loc := #caller_location) {
    assert(timeline != nil, "Nil Timeline pointer.", loc)

    lunge := to_vector2(grid_to_world_point(DIRECTIONS[direction])) * lunge_distance
    half_time := total_time / 2

    timeline_add(timeline, event_offset_travel(entity_handle, Vector2{ 0, 0 }, lunge, half_time, entity_handle))
    timeline_add(timeline, event_reset_offset(entity_handle, half_time, entity_handle))
}


// Creates a sequence of Events that makes the Character do a melee animation and damage
// any Entity that is in the direction that the attack is in.
// `entity_handle` is the Entity_Handle that does the attack.
// `direction` is the Direction to do the melee attack in.
// `damage` is the amount of damage that the attack should do.
// `total_time` is the total amount of time that the entire animation should take.
sequence_melee :: proc(timeline: ^Timeline, entity_handle: Entity_Handle, direction: Direction, damage: int, total_time: f32, lunge_distance: f32 = LUNGE_DISTANCE, loc := #caller_location) {
    assert(timeline != nil, "Nil Timeline pointer.", loc)

    half_time := total_time / 2
    lunge := to_vector2(grid_to_world_point(DIRECTIONS[direction])) * lunge_distance

    // Lunge forward.
    timeline_add(timeline, event_offset_travel(entity_handle, Vector2{ 0, 0 }, lunge, half_time, entity_handle))

    // Deal damage.
    entity := get_entity(entity_handle)

    attack_pos := entity.position + DIRECTIONS[direction]
    if target_handle := world_get_entity_at(&game.current_world, attack_pos); entity_handle_valid(target_handle) {
        timeline_add(timeline, event_deal_damage(damage, entity_handle, target_handle, entity_handle))
    }

    // Lunge back.
    // timeline_add(timeline, event_offset_travel(entity_handle, lunge, Vector2{ 0, 0 }, half_time, entity_handle))
    timeline_add(timeline, event_reset_offset(entity_handle, half_time, entity_handle))
}
