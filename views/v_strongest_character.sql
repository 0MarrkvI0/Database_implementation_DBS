CREATE VIEW v_strongest_characters AS
SELECT
    ch.id AS character_id,
    COALESCE(SUM(CASE WHEN cl.attacker_id = cp.id THEN cl.damage ELSE 0 END), 0) AS total_damage_done,  -- Damage done by the character
    COALESCE(SUM(CASE WHEN cl.target_id = cp.id THEN cl.damage ELSE 0 END), 0) AS total_damage_taken,  -- Damage taken by the character
    ch.current_health
FROM
    combat_participant cp
LEFT JOIN
    combat_log cl ON (cl.attacker_id = cp.id OR cl.target_id = cp.id)  -- Join on both attacker and target
JOIN
    character ch ON cp.character_id = ch.id
WHERE
    cl.event_msg_type = 'attack' AND cl.move_success = TRUE OR cl.attacker_id IS NULL  -- Include participants even with no logs
GROUP BY
    ch.id, ch.current_health;
