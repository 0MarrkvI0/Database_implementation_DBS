CREATE OR REPLACE FUNCTION p_set_character_attributes(selected_character_id INT)
RETURNS VOID AS $$
DECLARE
    character_class_id INT;
    dexterity INT;
    intelligence INT;
    strength INT;
    constitution INT;
    health INT;
    class_modifier FLOAT;
    class_armor_bonus FLOAT;
    class_inventory_modifier FLOAT;
BEGIN
    -- Retrieve the class ID for the character
    SELECT class_id INTO character_class_id
    FROM character
    WHERE id = selected_character_id;

    IF character_class_id IS NULL THEN
        RAISE NOTICE 'Character ID % does not exist', selected_character_id;
        RETURN;
    END IF;

    -- Retrieve character attributes
    SELECT value INTO dexterity
    FROM character_attribute
    WHERE character_id = selected_character_id AND attribute_id = (SELECT id FROM attribute WHERE name = 'Dexterity');

    SELECT value INTO intelligence
    FROM character_attribute
    WHERE character_id = selected_character_id AND attribute_id = (SELECT id FROM attribute WHERE name = 'Intelligence');

    SELECT value INTO strength
    FROM character_attribute
    WHERE character_id = selected_character_id AND attribute_id = (SELECT id FROM attribute WHERE name = 'Strength');

    SELECT value INTO constitution
    FROM character_attribute
    WHERE character_id = selected_character_id AND attribute_id = (SELECT id FROM attribute WHERE name = 'Constitution');

    SELECT value INTO health
    FROM character_attribute
    WHERE character_id = selected_character_id AND attribute_id = (SELECT id FROM attribute WHERE name = 'Health');

    -- Retrieve class-related modifiers
    SELECT
        c.class_modifier,
        c.class_armor_modifier,
        c.class_inventory_modifier
    INTO
        class_modifier,
        class_armor_bonus,
        class_inventory_modifier
    FROM class c
    WHERE c.id = character_class_id;

    -- Calculate and update the character's attributes
    UPDATE character
    SET
        max_ap = ROUND((dexterity + intelligence) * class_modifier),
        max_health = health,
        armor = ROUND(10 + (dexterity::FLOAT / 2) + class_armor_bonus),
        max_inventory = ROUND((strength + constitution) * class_inventory_modifier)
    WHERE id = selected_character_id;

END;
$$ LANGUAGE plpgsql;

