CREATE OR REPLACE FUNCTION p_enter_combat(
    selected_combat_id INTEGER,
    selected_character_id INTEGER
) RETURNS VOID AS $$
DECLARE
    time_joined TIMESTAMP;
    combat_participant_id INT;
    current_round_id INT;
BEGIN
    -- Get current timestamp
    time_joined := NOW();

    -- Check if combat exists
    IF NOT EXISTS (
        SELECT 1 FROM combat WHERE id = selected_combat_id AND end_time ISNULL
    ) THEN
        RAISE EXCEPTION 'Combat with id % does not exist.', selected_combat_id;
    END IF;

    -- Check if character exists
    IF NOT EXISTS (
        SELECT 1 FROM character WHERE id = selected_character_id
    ) THEN
        RAISE EXCEPTION 'Character with id % does not exist.', selected_character_id;
    END IF;

    -- Check if character is already in an active combat
    IF EXISTS (
        SELECT 1
        FROM combat_participant cp
        JOIN combat c ON c.id = cp.combat_id
        WHERE cp.character_id = selected_character_id
          AND c.end_time IS NULL
          AND cp.is_alive IS TRUE
          AND cp.combat_id <> selected_combat_id  -- Not the same combat
    ) THEN
        RAISE EXCEPTION 'Character with id % is already in an active combat.', selected_character_id;
    END IF;

    -- Insert character into combat_participant and get ID
    INSERT INTO combat_participant (combat_id, character_id, is_alive, join_time)
    VALUES (selected_combat_id, selected_character_id, TRUE, time_joined)
    RETURNING id INTO combat_participant_id;

    -- Find current round
    SELECT id INTO current_round_id
    FROM round
    WHERE combat_id = selected_combat_id
      AND start_time <= time_joined
      AND (end_time IS NULL)
    LIMIT 1;  -- Limit to one result to ensure we don't accidentally pick multiple rounds

    -- Handle case where no current round is found (if applicable)
    IF current_round_id IS NULL THEN
        RAISE EXCEPTION 'No current round found for combat id % at time %.', selected_combat_id, time_joined;
    END IF;

    -- Set the character's status to "in_combat" after joining a combat
    UPDATE character
    SET status = 'in_combat'
    WHERE id = selected_character_id;

    -- Log the action (character entering combat)
    INSERT INTO combat_log (round_id, combat_id, time, target_id, event_msg_type, move_success)
    VALUES (current_round_id, selected_combat_id, time_joined, combat_participant_id, 'login', TRUE);

    -- Debug info
    RAISE NOTICE 'Character % joined combat % at %, participant_id = %, round_id = %',
                 selected_character_id, selected_combat_id, time_joined, combat_participant_id, current_round_id;

END;
$$ LANGUAGE plpgsql;
