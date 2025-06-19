CREATE VIEW v_combat_damage AS
SELECT
    cl.combat_id,
    cl.round_id,
    COALESCE(SUM(
        CASE
            WHEN cl.event_msg_type = 'attack' AND cl.move_success IS TRUE
            THEN cl.damage
            ELSE 0
        END
    ), 0) AS total_damage
FROM
    combat_log cl
GROUP BY
    cl.combat_id, cl.round_id;