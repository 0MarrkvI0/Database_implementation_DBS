CREATE VIEW v_spell_statistics AS
SELECT
    cl.spell_id,
    COUNT(cl.spell_id) AS total_casts,                -- Total number of times the spell was cast
    SUM(CASE WHEN cl.move_success = TRUE THEN 1 ELSE 0 END) AS successful_casts,  -- Number of successful casts
    SUM(cl.damage) AS total_damage,                   -- Total damage done by the spell
    ROUND(AVG(cl.damage), 2) AS average_damage,                 -- Average damage of the spell
    ROUND((SUM(CASE WHEN cl.move_success = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(cl.spell_id)),2) AS success_rate  -- Success rate in percent
FROM
    combat_log cl
WHERE
    cl.spell_id IS NOT NULL
GROUP BY
    cl.spell_id;