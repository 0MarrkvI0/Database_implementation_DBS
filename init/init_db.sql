-- CATEGORY
INSERT INTO category (name, category_base_cost_modifier)
VALUES
    ('Fire', 1.2),
    ('Ice', 1.1),
    ('Physical', 1.0),
    ('Heal', 0.8);

-- SPELL
INSERT INTO spell (category_id, name, base_cost, base_damage, accuracy)
VALUES
    (1, 'Fireball', 10, 30, 15),
    (2, 'Frostbite', 8, 20, 17),
    (3, 'Power Strike', 6, 25, 8),
    (3, 'Shield Bash', 4, 10, 14),
    (4, 'Self-Healing', 20, 15, 20);

-- ATTRIBUTE
INSERT INTO attribute (name)
VALUES
    ('Strength'),       -- sila
    ('Dexterity'),      -- obratnosť
    ('Constitution'),   -- odolnosť
    ('Intelligence'),   -- inteligencia
    ('Health');         -- zdravie


-- CLASS
INSERT INTO class (name, class_modifier, class_armor_modifier, class_inventory_modifier)
VALUES ('Warrior', 1.0, 2.25, 1.25),
       ('Mage', 1.1, 0.8, 0.7);

-- CHARACTER
INSERT INTO character (class_id)
VALUES (1),
       (2),
       (2),
       (1);

-- Postava 1 (Warrior)
INSERT INTO character_attribute (character_id, attribute_id, value) VALUES
(1, 1, 15),  -- Strength
(1, 2, 10),  -- Dexterity
(1, 3, 14),  -- Constitution
(1, 4, 5),   -- Intelligence
(1, 5, 100); -- Health

-- Postava 2 (Mage)
INSERT INTO character_attribute (character_id, attribute_id, value) VALUES
(2, 1, 5),
(2, 2, 8),
(2, 3, 9),
(2, 4, 15),
(2, 5, 80);

-- Postava 3 (Mage)
INSERT INTO character_attribute (character_id, attribute_id, value) VALUES
(3, 1, 6),
(3, 2, 9),
(3, 3, 10),
(3, 4, 13),
(3, 5, 85);

-- Postava 4 (Warrior)
INSERT INTO character_attribute (character_id, attribute_id, value) VALUES
(4, 1, 14),
(4, 2, 11),
(4, 3, 13),
(4, 4, 6),
(4, 5, 110);


-- COMBAT
INSERT INTO combat (start_time, end_time)
VALUES (now(), NULL);

-- ROUND
INSERT INTO round (combat_id, number, start_time, end_time)
VALUES (1, 1, now(), NULL);

-- COMBAT_PARTICIPANT
INSERT INTO combat_participant (character_id, combat_id, is_alive, join_time)
VALUES (1, 1, true, now()),
       (2, 1, true, now());

-- COMBAT_LOG
INSERT INTO combat_log (
    round_id, combat_id, time, dice_throw, attacker_id, target_id, event_msg_type,
    spell_id, ap_cost, damage, move_success, item_id
)
VALUES (
    1, 1, now(), 17, 1, 2, 'attack',
    1, 10, 30, true, NULL
);

-- SPELL_ATTRIBUTE
INSERT INTO spell_attribute (attribute_id, spell_id, action, modifier_type)
VALUES
(1, 3, 'ap_cost', '+'),
(2, 3, 'ap_cost', '-');

-- ITEM
INSERT INTO item (state, item_modifier, name, weight, type, action)
VALUES
('inventory', 0.12, 'Enchanted Sword', 5.0, 'sword', 'ap_cost'),
('inventory',0.09 , 'Golden Ring', 0.5, 'ring', 'ap_cost'),
('battleground',0.15,'Iron Sword',6.0,'sword','damage');

-- INVENTORY_ITEM
INSERT INTO inventory_item (item_id, is_equipped)
VALUES
(1, true),
(2, true);


-- BATTLEGROUND_ITEM
INSERT INTO battleground_item (item_id, combat_id, is_taken)
VALUES (3, 1, false);


SELECT p_set_character_attributes(1);
SELECT p_set_character_attributes(2);
SELECT p_set_character_attributes(3);
SELECT p_set_character_attributes(4);

SELECT p_reset_current_ap(1);
SELECT p_reset_current_health(1);

SELECT p_reset_current_ap(2);
SELECT p_reset_current_health(2);

SELECT p_reset_current_ap(3);
SELECT p_reset_current_health(3);

SELECT p_reset_current_ap(4);
SELECT p_reset_current_health(4);

SELECT p_add_item(1,1);
SELECT p_add_item(1,2);