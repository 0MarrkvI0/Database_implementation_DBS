CREATE OR REPLACE FUNCTION p_loot_item (
    selected_combat_id INTEGER,
    selected_character_id INTEGER,
    selected_item_id INTEGER
) RETURNS VOID AS $$
DECLARE
    item_weight FLOAT;
    cur_item_id INTEGER;
    combat_character_id INTEGER;
    character_cur_weight FLOAT;
    character_max_weight FLOAT;
    last_round_id INTEGER;
BEGIN
    -- Lock the item row to avoid race conditions
    IF NOT EXISTS (
        SELECT 1
        FROM battleground_item
        WHERE combat_id = selected_combat_id
          AND item_id = selected_item_id
          AND is_taken = FALSE
        FOR UPDATE
    ) THEN
        RAISE EXCEPTION 'Item % is not available in combat % or already taken.', selected_item_id, selected_combat_id;
    END IF;

    -- Verify that the character is a participant in the combat
    SELECT id INTO combat_character_id
    FROM combat_participant
    WHERE character_id = selected_character_id AND combat_id = selected_combat_id AND is_alive IS TRUE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Character % is not participating in combat %.', selected_character_id, selected_combat_id;
    END IF;

    -- Get current and max inventory weight
    SELECT current_weight, max_inventory INTO character_cur_weight, character_max_weight
    FROM character
    WHERE id = selected_character_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Character with id % does not exist.', selected_character_id;
    END IF;

    -- Get the item weight
    SELECT weight INTO item_weight
    FROM item
    WHERE id = selected_item_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Item with id % does not exist.', selected_item_id;
    END IF;

    -- Check if the character can carry the item
    IF character_cur_weight + item_weight > character_max_weight THEN
        RAISE EXCEPTION 'Inventory full. Character % cannot carry item % (%.2f > %.2f).',
            selected_character_id, selected_item_id, character_cur_weight + item_weight, character_max_weight;
    END IF;

    -- Add item to character using existing add_item() function
    PERFORM p_add_item(selected_character_id, selected_item_id);

    -- Mark the item as taken in the battleground
    UPDATE battleground_item
    SET is_taken = TRUE
    WHERE combat_id = selected_combat_id AND item_id = selected_item_id;

    -- Determine the last round for this combat
    SELECT id INTO last_round_id
    FROM round
    WHERE combat_id = selected_combat_id
    ORDER BY id DESC
    LIMIT 1;

    IF last_round_id IS NULL THEN
        RAISE EXCEPTION 'No rounds found for combat %.', selected_combat_id;
    END IF;

    -- Get the internal battleground item ID for logging
    SELECT id INTO cur_item_id
    FROM battleground_item
    WHERE item_id = selected_item_id AND combat_id = selected_combat_id
    LIMIT 1;

    -- Log the loot event
    INSERT INTO combat_log (round_id, combat_id, time, target_id, event_msg_type, move_success, item_id)
    VALUES (last_round_id, selected_combat_id, now(), combat_character_id, 'pick_item', true, cur_item_id);

    RAISE NOTICE 'Character % successfully looted item % in combat %.', selected_character_id, selected_item_id,selected_combat_id ;

END;
$$ LANGUAGE plpgsql;
