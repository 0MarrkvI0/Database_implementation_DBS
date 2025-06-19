DO $$
DECLARE
    combat_id INT;
BEGIN
    -- 1. Insert a new combat and get its ID
    INSERT INTO combat (start_time, end_time)
    VALUES (now(), NULL)
    RETURNING id INTO combat_id;

    -- Show the combat ID
    RAISE NOTICE 'Inserted combat with id: %', combat_id;

    -- EDGE-CASE. Add character with ID 5 into the combat before 1 round
    -- PERFORM p_enter_combat(combat_id, 5);

    -- 2. Insert first round for this combat
    INSERT INTO round (combat_id, number, start_time, end_time)
    VALUES (combat_id, 1, now(), NULL);

    -- 3. Add character with ID 5 into the combat
    PERFORM p_enter_combat(combat_id, 5);

END $$;

-- EDGE-CASE
SELECT p_enter_combat(NULL, 8899988);
SELECT p_enter_combat(7777, NULL);

-- can be alive only in one combat at same time
SELECT p_enter_combat(1, 5);


