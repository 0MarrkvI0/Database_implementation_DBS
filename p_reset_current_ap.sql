
CREATE OR REPLACE FUNCTION p_reset_current_ap(selected_character_id INTEGER)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    row_count INT;
BEGIN
    UPDATE character
    SET current_ap = max_ap
    WHERE id = selected_character_id;

    GET DIAGNOSTICS row_count = ROW_COUNT;

    IF row_count = 0 THEN
        RAISE NOTICE 'No character with ID % found to reset AP.', selected_character_id;
    END IF;
END;
$$;