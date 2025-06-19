

CREATE OR REPLACE FUNCTION p_add_item (
    selected_character_id INTEGER,
    selected_item_id INTEGER
) RETURNS VOID AS $$
DECLARE
    item_weight FLOAT;
    current_owner INTEGER;
BEGIN
    -- Check if character exists
    IF NOT EXISTS (
        SELECT 1 FROM character WHERE id = selected_character_id
    ) THEN
        RAISE EXCEPTION 'Character with id % does not exist.', selected_character_id;
    END IF;

    -- Get the item's weight or raise an error if item doesn't exist
    SELECT weight INTO item_weight
    FROM item
    WHERE id = selected_item_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Item with id % does not exist.', selected_item_id;
    END IF;

    RAISE NOTICE 'Item weight: %', item_weight;

    -- Check if the item is already in the inventory system
    SELECT character_id INTO current_owner
    FROM inventory_item
    WHERE item_id = selected_item_id;

    -- CASE 1: Item was dropped (character_id IS NULL)
    IF FOUND AND current_owner IS NULL THEN
        RAISE NOTICE 'Item was dropped. Reassigning to character.';
        UPDATE inventory_item
        SET character_id = selected_character_id
        WHERE item_id = selected_item_id AND character_id IS NULL;

    -- CASE 2: Item is already owned by the same character
    ELSIF FOUND AND current_owner = selected_character_id THEN
        RAISE NOTICE 'Item is already in this character''s inventory. Doing nothing.';
        RETURN;

    -- CASE 3: Item is in someone else's inventory
    ELSIF FOUND AND current_owner <> selected_character_id THEN
        RAISE EXCEPTION 'Item % is already in inventory of another character (id %). Cannot steal.', selected_item_id, current_owner;

    -- CASE 4: Item not in inventory yet
    ELSE
        RAISE NOTICE 'Item not in inventory. Inserting new row.';
        INSERT INTO inventory_item (character_id, item_id)
        VALUES (selected_character_id, selected_item_id);
    END IF;

    -- Update item state
    UPDATE item
    SET state = 'inventory'
    WHERE id = selected_item_id;

    -- Update character's current weight
    UPDATE character
    SET current_weight = current_weight + item_weight
    WHERE id = selected_character_id;

    RAISE NOTICE 'Item % added (or reassigned) to character %', selected_item_id, selected_character_id;
END;
$$ LANGUAGE plpgsql;
