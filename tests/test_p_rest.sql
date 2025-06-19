-- 1. Insert a new character and get its ID within the DO block
DO $$
DECLARE
    char_id INT;
    debug_message TEXT;  -- Variable to store debug messages
BEGIN
    -- Insert new character and get its ID
    INSERT INTO character (class_id)
    VALUES (1)
    RETURNING id INTO char_id;

    -- 2. Insert base attributes for the character (Warrior profile)
    INSERT INTO character_attribute (character_id, attribute_id, value)
    SELECT char_id, attr.attribute_id, attr.value
    FROM (
        VALUES
            (1, 14),   -- Strength
            (2, 11),   -- Dexterity
            (3, 13),   -- Constitution
            (4, 6),    -- Intelligence
            (5, 110)   -- Health
    ) AS attr(attribute_id, value);

    -- 3. Initialize character: set attributes, reset AP and health
    PERFORM p_set_character_attributes(char_id);
    PERFORM p_reset_current_ap(char_id);
    PERFORM p_reset_current_health(char_id);

    -- Debug: show character state
    RAISE NOTICE 'Character created with ID: %', char_id;
    RAISE NOTICE 'Initial character state:';

    SELECT current_health FROM character WHERE id = char_id INTO debug_message;
    RAISE NOTICE '%', debug_message;

    -- 4. Simulate damage and enter combat
    UPDATE character
    SET current_health = current_health - 20
        -- EDGE CASE WHEN is in_combat he cannot rest
        -- ,status = 'in_combat'
    WHERE id = char_id;


    RAISE NOTICE'After taking damage:';
    SELECT current_health FROM character WHERE id = char_id INTO debug_message;

     -- You can now print or return the final message if needed
    RAISE NOTICE '%', debug_message;

    -- 5. Rest the character (heal & reset AP)
    PERFORM p_rest_character(char_id);

    RAISE NOTICE 'After rest:';
    SELECT current_health FROM character WHERE id = char_id INTO debug_message;


    RAISE NOTICE '%', debug_message;
END $$;
