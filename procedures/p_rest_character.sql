CREATE OR REPLACE FUNCTION p_rest_character(
    selected_character_id INTEGER
)
RETURNS VOID AS $$
DECLARE
    current_status TEXT;
    this_current_health INT;
    this_max_health INT;
    this_current_ap INT;
    this_max_ap INT;
BEGIN
    -- Lock the character row and get all necessary data
    SELECT status, current_health, max_health, current_ap, max_ap
    INTO current_status, this_current_health, this_max_health, this_current_ap, this_max_ap
    FROM character
    WHERE id = selected_character_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Character with ID % not found', selected_character_id;
    END IF;

    IF current_status <> 'idle' THEN
        RAISE EXCEPTION 'Character % must be idle to rest. Current status: %', selected_character_id, current_status;
    END IF;

    -- Set status to 'resting'
    UPDATE character
    SET status = 'resting'
    WHERE id = selected_character_id;

    -- Loop to regenerate health and AP
    WHILE this_current_health < this_max_health OR this_current_ap < this_max_ap LOOP
        PERFORM pg_sleep(1); -- Simulate time passing

        -- Regenerate health and AP
        IF this_current_health < this_max_health THEN
            this_current_health := LEAST(this_current_health + 5, this_max_health);
        END IF;

        IF this_current_ap < this_max_ap THEN
            this_current_ap := LEAST(this_current_ap + 5, this_max_ap);
        END IF;

        -- Update character stats if needed
        UPDATE character
        SET current_health = this_current_health,
            current_ap = this_current_ap
        WHERE id = selected_character_id;

        -- Exit the loop early if both health and AP are full
        IF this_current_health = this_max_health AND this_current_ap = this_max_ap THEN
            EXIT;
        END IF;
    END LOOP;

    -- Set status back to 'idle'
    UPDATE character
    SET status = 'idle'
    WHERE id = selected_character_id;

END;
$$ LANGUAGE plpgsql;
