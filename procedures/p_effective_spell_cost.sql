CREATE OR REPLACE FUNCTION p_effective_spell_cost (
    selected_spell_id INTEGER,
    selected_caster_id INTEGER
) RETURNS NUMERIC AS $$
DECLARE
    effective_cost NUMERIC;
    spell_base_cost NUMERIC;
    spell_category NUMERIC;
    spell_base_cost_modifier NUMERIC;
    attribute_modifier_sum NUMERIC := 0;
    item_modifier_sum NUMERIC := 0;
    cur_spell_attribute RECORD;
    attr_value NUMERIC;
    item_rec RECORD;
BEGIN
    -- Load base spell cost
    SELECT base_cost,category_id INTO spell_base_cost,spell_category
    FROM spell
    WHERE id = selected_spell_id;

    -- Load base cost modifier from category
    SELECT category_base_cost_modifier INTO spell_base_cost_modifier
    FROM category
    WHERE id = spell_category;

    -- Check if spell exists
    IF spell_base_cost IS NULL THEN
        RAISE EXCEPTION 'Spell with id % not found.', selected_spell_id;
    END IF;

    RAISE NOTICE 'Base cost of spell % is %', selected_spell_id, spell_base_cost;

    -- Apply attribute modifiers
    FOR cur_spell_attribute IN
        SELECT attribute_id, modifier_type
        FROM spell_attribute
        WHERE spell_id = selected_spell_id
          AND action = 'ap_cost'
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
                    attribute_modifier_sum := attribute_modifier_sum + attr_value / 100;
                WHEN '-' THEN
                    attribute_modifier_sum := attribute_modifier_sum - attr_value / 100;
                WHEN '*' THEN
                    attribute_modifier_sum := attribute_modifier_sum * (attr_value / 100); -- optional
                WHEN '/' THEN
                    IF attr_value != 0 THEN
                        attribute_modifier_sum := attribute_modifier_sum / (attr_value / 100); -- optional
                    END IF;
            END CASE;
        END IF;
    END LOOP;

    RAISE NOTICE 'Total attribute_modifier_sum: %', attribute_modifier_sum;

    -- Load item modifiers
    FOR item_rec IN
        SELECT item.item_modifier
        FROM inventory_item ii
        JOIN item ON item.id = ii.item_id
        WHERE ii.character_id = selected_caster_id
          AND ii.is_equipped IS TRUE
          AND item.action = 'ap_cost'
    LOOP
        RAISE NOTICE 'Item modifier found: %', item_rec.item_modifier;
        item_modifier_sum := item_modifier_sum + item_rec.item_modifier;
    END LOOP;

    RAISE NOTICE 'Total item_modifier_sum: %', item_modifier_sum;

    -- Compute effective cost
    effective_cost := spell_base_cost * spell_base_cost_modifier * (1 - attribute_modifier_sum) * (1 - item_modifier_sum);

    RAISE NOTICE 'Effective cost (rounded): %', ROUND(effective_cost);

    RETURN ROUND(effective_cost);
END;
$$ LANGUAGE plpgsql;
