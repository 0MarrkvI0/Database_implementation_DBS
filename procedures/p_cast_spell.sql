CREATE OR REPLACE FUNCTION p_cast_spell (
    selected_caster_id INTEGER,
    selected_target_id INTEGER,
    selected_spell_id INTEGER,
    selected_combat_id INTEGER
) RETURNS VOID AS $$
DECLARE
    spell_ap_cost INT;
    roll_result INT;
    spell_damage NUMERIC;
    combat_target RECORD;
    combat_attacker RECORD;
    armor_value NUMERIC;
    spell_accuracy NUMERIC;
    last_round_id INTEGER;
    is_healing BOOLEAN;
    target_max_health INTEGER;
BEGIN
    -- Verify the caster is alive and part of the combat
    SELECT cp.id, ch.current_ap INTO combat_attacker
    FROM combat_participant cp
    JOIN character ch ON ch.id = cp.character_id
    WHERE cp.character_id = selected_caster_id
      AND cp.is_alive IS TRUE
      AND cp.combat_id = selected_combat_id
    LIMIT 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Caster is not a living participant in this combat.';
    END IF;

    -- Select both columns into the RECORD variable for the target
    SELECT cp.id, ch.armor INTO combat_target
    FROM combat_participant cp
    JOIN character ch ON ch.id = cp.character_id
    WHERE cp.character_id = selected_target_id
      AND cp.is_alive IS TRUE
      AND cp.combat_id = selected_combat_id
    LIMIT 1;

    -- Check if the target exists and is valid
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Target with id % not found or not alive in this combat.', selected_target_id;
    END IF;


    -- Check if caster is trying to cast on themselves and ensure it's a healing spell
    IF combat_target.id = combat_attacker.id THEN
        -- Check if the spell is of the 'Heal' category
        IF EXISTS (
            SELECT 1
            FROM spell
            JOIN category ON spell.category_id = category.id
            WHERE spell.id = selected_spell_id
              AND category.name = 'Heal'
        ) THEN
            RAISE NOTICE 'Target is healing themselves.';
            is_healing = TRUE;
        ELSE
            -- Raise an exception for non-healing spells
            RAISE EXCEPTION 'Redundant action: cannot attack yourself unless healing.';
        END IF;
    END IF;

    -- Get spell AP cost
    SELECT p_effective_spell_cost(selected_spell_id, selected_caster_id)
    INTO spell_ap_cost;

    -- Determine the last round for this combat
    SELECT id INTO last_round_id
    FROM round
    WHERE combat_id = selected_combat_id
    ORDER BY id DESC
    LIMIT 1;

    IF last_round_id IS NULL THEN
        RAISE EXCEPTION 'No rounds found for combat %.', selected_combat_id;
    END IF;

    -- Check AP and update
    IF combat_attacker.current_ap >= spell_ap_cost THEN
        UPDATE character
        SET current_ap = current_ap - spell_ap_cost
        WHERE id = selected_caster_id;
    ELSE
        RAISE EXCEPTION 'Not enough AP to cast the spell. Required: %, Available: %', spell_ap_cost, combat_attacker.current_ap;
    END IF;

    -- Simulate a d20 roll
    roll_result := floor(random() * 20 + 1);
    RAISE NOTICE 'Caster % rolled a % when casting spell %', selected_caster_id, roll_result, selected_spell_id;

    -- Get the spell damage
    SELECT p_spell_damage(selected_spell_id, selected_caster_id)
    INTO spell_damage;

    -- Assign armor value from the target's record
    armor_value := combat_target.armor;

    -- Log the armor value of the target
    RAISE NOTICE 'Armor value of target: %', armor_value;

    -- Check if armor is greater than or equal to the spell damage
    IF armor_value >= spell_damage AND is_healing IS FALSE THEN
        -- Armor completely blocks the damage
        spell_damage := 0;
        RAISE NOTICE 'Armor fully blocked damage, new damage: %', spell_damage;
    ELSIF is_healing IS FALSE THEN
        -- Armor partially reduces the damage
        spell_damage := spell_damage - (armor_value / 20);  -- Armor reduces damage (percentage reduction)
        RAISE NOTICE 'Armor reduced damage, new damage: %', spell_damage;
    END IF;

    -- Get spell accuracy
    SELECT accuracy INTO spell_accuracy
    FROM spell
    WHERE id = selected_spell_id;

    -- Accuracy check
    IF spell_accuracy IS NULL THEN
        RAISE EXCEPTION 'Spell accuracy not found for spell %', selected_spell_id;
    END IF;

    RAISE NOTICE 'Spell accuracy: %', spell_accuracy;

    IF is_healing IS TRUE THEN
        INSERT INTO combat_log (round_id, combat_id, time, dice_throw, attacker_id, target_id, event_msg_type, spell_id, ap_cost, damage, move_success)
        VALUES (last_round_id, selected_combat_id, now(), roll_result, combat_attacker.id, combat_target.id, 'heal', selected_spell_id, spell_ap_cost, spell_damage, true);

        -- Fetch max health into a variable
        SELECT max_health INTO target_max_health
        FROM character
        WHERE id = selected_target_id;

        -- Update health, ensuring it does not exceed max_health
        UPDATE character
        SET current_health = LEAST(current_health + spell_damage, target_max_health)
        WHERE id = selected_target_id;

        RAISE NOTICE 'Target % took % heal, remaining HP: %', selected_target_id, spell_damage, (SELECT current_health FROM character WHERE id = selected_target_id);

        RETURN;
    END IF;

    IF spell_accuracy >= roll_result THEN
        -- Apply damage to the target's health
        UPDATE character
        SET current_health = current_health - spell_damage
        WHERE id = selected_target_id;

        RAISE NOTICE 'Target % took % damage, remaining HP: %', selected_target_id, spell_damage, (SELECT current_health FROM character WHERE id = selected_target_id);

        -- Log the combat event
        INSERT INTO combat_log(round_id, combat_id, time, dice_throw, attacker_id, target_id, event_msg_type, spell_id, ap_cost, damage, move_success)
        VALUES (last_round_id, selected_combat_id, now(), roll_result, combat_attacker.id, combat_target.id, 'attack', selected_spell_id, spell_ap_cost, spell_damage, true);
    ELSE
        INSERT INTO combat_log(round_id, combat_id, time, dice_throw, attacker_id, target_id, event_msg_type, spell_id, ap_cost, damage, move_success)
        VALUES (last_round_id, selected_combat_id, now(), roll_result, combat_attacker.id, combat_target.id, 'attack', selected_spell_id, spell_ap_cost, spell_damage, false);
        RAISE NOTICE 'Target % dodged the spell due to insufficient accuracy roll.', selected_target_id;
    END IF;

    -- Check if target is dead
    IF (SELECT current_health FROM character WHERE id = selected_target_id) <= 0 THEN
        RAISE NOTICE 'Target % has died.', selected_target_id;
        INSERT INTO combat_log(round_id, combat_id, time, target_id, event_msg_type, move_success)
        VALUES (last_round_id, selected_combat_id, now(), combat_target.id, 'died', true);
        UPDATE combat_participant
        SET is_alive = FALSE
        WHERE id = combat_target.id;

        -- Set the character's status to "in_combat" after joining a combat
        UPDATE character
        SET status = 'in_combat'
        WHERE id = selected_target_id;

        -- drop items
    END IF;

END;
$$ LANGUAGE plpgsql;
