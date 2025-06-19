
CREATE OR REPLACE FUNCTION p_reset_current_health(selected_character_id INT)
RETURNS VOID AS $$
DECLARE
    character_class_id INT;
BEGIN
    -- Retrieve class ID (if needed for later use)
    SELECT class_id INTO character_class_id
    FROM character
    WHERE id = selected_character_id;

    IF character_class_id IS NULL THEN
        RAISE NOTICE 'Character ID % does not exist', selected_character_id;
        RETURN;
    END IF;

    -- Update current health by adding max health
    UPDATE character
    SET current_health = max_health
    WHERE id = selected_character_id;

END;
$$ LANGUAGE plpgsql;