CREATE VIEW v_most_damage AS
SELECT
    ch.id AS character_id,
    COALESCE(SUM(cl.damage), 0) AS total_damage
FROM
    combat_participant cp
LEFT JOIN
    combat_log cl ON cl.attacker_id = cp.id AND cl.event_msg_type = 'attack' AND cl.move_success = TRUE
JOIN
    character ch ON cp.character_id = ch.id
GROUP BY
    ch.id;