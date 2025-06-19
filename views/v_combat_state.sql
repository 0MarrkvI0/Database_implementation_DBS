CREATE VIEW v_combat_state AS
SELECT
    ch.id AS character_id,
    ch.current_ap,
    c.id AS combat_id,
    r_last.number AS current_round
FROM
    combat c
JOIN
    (   -- Find latest round per combat
        SELECT combat_id, MAX(number) AS number
        FROM round
        WHERE end_time IS NULL
        GROUP BY combat_id
    ) r_last
    ON c.id = r_last.combat_id
JOIN round r
    ON r.combat_id = r_last.combat_id AND r.number = r_last.number
JOIN combat_participant cp
    ON cp.combat_id = c.id
JOIN character ch
    ON ch.id = cp.character_id
WHERE
    cp.is_alive = TRUE;
