CREATE OR REPLACE FUNCTION p_spell_damage (
    selected_spell_id INTEGER,
    selected_caster_id INTEGER
) RETURNS NUMERIC AS $$
DECLARE
    effective_damage NUMERIC;
    spell_base_damage NUMERIC;
    attribute_modifier_sum NUMERIC := 0;
    multiplicative_modifier NUMERIC := 1;
    item_modifier_sum NUMERIC := 0;
    cur_spell_attribute RECORD;
    attr_value NUMERIC;
    item_rec RECORD;
BEGIN
    -- Load base spell damage
    SELECT base_damage INTO spell_base_damage
    FROM spell
    WHERE id = selected_spell_id;

    IF spell_base_damage IS NULL THEN
        RAISE EXCEPTION 'Spell with id % not found.', selected_spell_id;
    END IF;

    RAISE NOTICE 'Base damage of spell % is %', selected_spell_id, spell_base_damage;

    -- Attribute modifiers
    FOR cur_spell_attribute IN
        SELECT attribute_id, modifier_type
        FROM spell_attribute
        WHERE spell_id = selected_spell_id
          AND action = 'damage'
    LOOP
        SELECT value INTO attr_value
        FROM character_attribute
        WHERE character_id = selected_caster_id
          AND attribute_id = cur_spell_attribute.attribute_id;

        RAISE NOTICE 'Processing attribute_id %, value %, modifier %',
            cur_spell_attribute.attribute_id, attr_value, cur_spell_attribute.modifier_type;

        IF attr_value IS NOT NULL THEN
            CASE cur_spell_attribute.modifier_type
                WHEN '+' THEN
                    attribute_modifier_sum := attribute_modifier_sum + (attr_value / 100);
                WHEN '-' THEN
                    attribute_modifier_sum := attribute_modifier_sum - (attr_value / 100);
                WHEN '*' THEN
                    multiplicative_modifier := multiplicative_modifier * (1 + attr_value / 100);
                WHEN '/' THEN
                    IF attr_value != 0 THEN
                        multiplicative_modifier := multiplicative_modifier / (1 + attr_value / 100);
                    END IF;
            END CASE;
        END IF;
    END LOOP;

    RAISE NOTICE 'Total attribute_modifier_sum: %', attribute_modifier_sum;
    RAISE NOTICE 'Multiplicative modifier from attributes: %', multiplicative_modifier;

    -- Item modifiers
    FOR item_rec IN
        SELECT item.item_modifier
        FROM inventory_item ii
        JOIN item ON item.id = ii.item_id
        WHERE ii.character_id = selected_caster_id
          AND ii.is_equipped IS TRUE
          AND item.action = 'damage'
    LOOP
        RAISE NOTICE 'Item modifier found: %', item_rec.item_modifier;
        item_modifier_sum := item_modifier_sum + item_rec.item_modifier;
    END LOOP;

    RAISE NOTICE 'Total item_modifier_sum: %', item_modifier_sum;

    -- Compute effective damage
    effective_damage := spell_base_damage + (((1 + attribute_modifier_sum/20) + multiplicative_modifier)/20) + (1 + item_modifier_sum);

    RAISE NOTICE 'Effective damage (rounded): %', ROUND(effective_damage);

    RETURN ROUND(effective_damage);
END;
$$ LANGUAGE plpgsql;
