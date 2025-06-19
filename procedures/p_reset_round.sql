CREATE OR REPLACE FUNCTION p_reset_round(selected_combat_id INTEGER)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    current_round_id INT;
    current_round_number INT;
    time_ended TIMESTAMP;
    alive_count INT;
    current_character INT;
BEGIN
    RAISE NOTICE 'Starting p_reset_round for combat_id = %', selected_combat_id;

    -- Check if the combat exists
    IF NOT EXISTS (
        SELECT 1 FROM combat WHERE id = selected_combat_id
    ) THEN
        RAISE EXCEPTION 'Combat with id % does not exist.', selected_combat_id;
    END IF;

    -- Get the current timestamp
    time_ended := NOW();
    RAISE NOTICE 'Current timestamp set to %', time_ended;

    -- Count the number of alive participants
    SELECT COUNT(*) INTO alive_count
    FROM combat_participant
    WHERE combat_id = selected_combat_id
      AND is_alive IS TRUE;
    RAISE NOTICE 'Alive participants count: %', alive_count;

    -- Reset AP for all alive participants
    FOR current_character IN
        SELECT character_id
        FROM combat_participant
        WHERE combat_id = selected_combat_id
          AND is_alive IS TRUE
    LOOP
        RAISE NOTICE 'Resetting AP for character_id %', current_character;
        PERFORM p_reset_current_ap(current_character);
    END LOOP;

    -- Get the ID and number of the current round (most recent)
    SELECT id, number INTO current_round_id, current_round_number
    FROM round
    WHERE combat_id = selected_combat_id AND round.end_time IS NULL
    ORDER BY start_time DESC
    LIMIT 1;

    -- Check if a round was found
    IF current_round_id IS NULL THEN
        RAISE EXCEPTION 'No active round found for combat_id %', selected_combat_id;
    END IF;

    RAISE NOTICE 'Current round id: %, round number: %', current_round_id, current_round_number;

    -- Mark the current round as ended
    UPDATE round
    SET end_time = time_ended
    WHERE id = current_round_id;
    RAISE NOTICE 'Round % ended at %', current_round_id, time_ended;

    -- Log the end of the round
    INSERT INTO combat_log (round_id, combat_id, time, event_msg_type, move_success)
    VALUES (current_round_id, selected_combat_id, time_ended, 'round_end', TRUE);
    RAISE NOTICE 'Logged round_end event for round %', current_round_id;

    -- If there is only one player alive, end the combat and log the winner
    IF alive_count = 1 THEN
        -- Get the ID of the last alive participant
        SELECT id INTO current_character
        FROM combat_participant
        WHERE combat_id = selected_combat_id
          AND is_alive IS TRUE
        LIMIT 1;

        RAISE NOTICE 'Only one player alive, character_id % is the winner', current_character;

        -- Log the winner of the combat
        INSERT INTO combat_log (round_id, combat_id, target_id, time, event_msg_type, move_success)
        VALUES (current_round_id, selected_combat_id, current_character, time_ended, 'winner', TRUE);

        UPDATE combat_participant
        SET is_alive = FALSE
        WHERE id = current_character;

        -- End the combat by setting the end time
        UPDATE combat
        SET end_time = time_ended
        WHERE id = selected_combat_id;

        RAISE NOTICE 'Combat % ended at %', selected_combat_id, time_ended;

        RETURN;  -- Exit if only one player is alive
    END IF;

    -- Create a new round
    INSERT INTO round (number, combat_id, start_time)
    VALUES (current_round_number + 1, selected_combat_id, time_ended);
    RAISE NOTICE 'New round % created for combat %', current_round_number + 1, selected_combat_id;

    -- Log the start of the new round
    INSERT INTO combat_log (round_id, combat_id, time, event_msg_type, move_success)
    VALUES (current_round_id + 1, selected_combat_id, time_ended, 'round_start', TRUE);
    RAISE NOTICE 'Logged round_start event for round %', current_round_id + 1;

    RAISE NOTICE 'Finished p_reset_round for combat_id = %', selected_combat_id;
END;
$$;
