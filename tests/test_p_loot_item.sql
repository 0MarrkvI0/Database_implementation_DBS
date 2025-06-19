DO $$
DECLARE
    v_item_id INT;
BEGIN
    -- 1. Insert new item
    INSERT INTO item (state, item_modifier, name, weight, type, action)
    VALUES ('battleground', 0.15, 'Devil Sword', 4.5, 'sword', 'damage')
    RETURNING id INTO v_item_id;

    -- Show the item ID
    RAISE NOTICE 'Inserted item with id: %', v_item_id;

    -- 2. Insert item into battleground
    INSERT INTO battleground_item (item_id, combat_id, is_taken)
    VALUES (v_item_id, 1, FALSE);

    -- 3. Enter characters into combat
    PERFORM p_enter_combat(1, 3);
    PERFORM p_enter_combat(1, 4);

    -- 4. Loot attempts
    PERFORM p_loot_item(1, 1, v_item_id);
END $$;

-- Too heavy item test
DO $$
DECLARE
    v_item_id INT;
BEGIN
    -- 1. Insert new item
    INSERT INTO item (state, item_modifier, name, weight, type, action)
    VALUES ('battleground', 1000, 'BigTuna', 1000, 'other', 'damage')
    RETURNING id INTO v_item_id;

    -- Show the item ID
    RAISE NOTICE 'Inserted item with id: %', v_item_id;

    -- 2. Insert item into battleground
    INSERT INTO battleground_item (item_id, combat_id, is_taken)
    VALUES (v_item_id, 1, FALSE);

    -- 4. Loot attempts
    PERFORM p_loot_item(1, 1, v_item_id);
END $$;

-- Check if ITEM is already taken
SELECT p_loot_item(1, 1, 4);
-- Check EDGECASE
SELECT p_loot_item(1, 2, 77777);
