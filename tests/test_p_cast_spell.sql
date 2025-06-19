UPDATE inventory_item
SET is_equipped = true
WHERE character_id = 1;

SELECT p_cast_spell(1,2,3,1);
-- EDGECASE
SELECT p_cast_spell(1,777,3,1);
SELECT p_cast_spell(1,2,88888,1);
SELECT p_cast_spell(1,2,3,8888);

SELECT p_cast_spell(2,1,2,1);
SELECT p_cast_spell(3,2,3,1);

SELECT p_reset_current_ap(3);

UPDATE character
SET current_health = current_health - 20
WHERE id = 3;

SELECT p_cast_spell(3,3,6,1);
