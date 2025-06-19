SELECT p_reset_round(1);

UPDATE combat_participant
SET is_alive = FALSE
--- CHOOSE WINNER
WHERE id IN (1, 2, 4);

SELECT p_reset_round(1);