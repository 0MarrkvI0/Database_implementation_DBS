CREATE TYPE character_status AS ENUM ('resting', 'in_combat', 'idle');
CREATE TYPE event_type AS ENUM ('attack', 'heal', 'pick_item', 'drop_item', 'died','login', 'round_end','round_start','winner');
CREATE TYPE action_type AS ENUM ('damage', 'ap_cost', 'heal');
CREATE TYPE modifier_op AS ENUM ('+', '-', '*', '/');
CREATE TYPE item_state AS ENUM ('battleground', 'inventory');
CREATE TYPE item_type AS ENUM ('sword', 'bow','wand','ring','gold', 'other');


CREATE TABLE attribute (
    id SERIAL PRIMARY KEY,
    name VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE class (
    id SERIAL PRIMARY KEY,
    name VARCHAR(20) NOT NULL UNIQUE,
    class_modifier FLOAT NOT NULL,
    class_armor_modifier FLOAT NOT NULL,
    class_inventory_modifier FLOAT NOT NULL
);

CREATE TABLE category (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    category_base_cost_modifier FLOAT NOT NULL
);

CREATE TABLE character (
    id SERIAL PRIMARY KEY,
    class_id INT REFERENCES class(id) NOT NULL,
    max_health INT,
    max_ap INT,
    armor INT,
    max_inventory INT,
    current_weight FLOAT DEFAULT 0,
    current_health INT,
    current_ap INT,
    status character_status DEFAULT 'idle' NOT NULL
);

CREATE TABLE character_attribute (
    character_id INT REFERENCES character(id) NOT NULL,
    attribute_id INT REFERENCES attribute(id) NOT NULL,
    value INT NOT NULL CHECK (value >= 0) DEFAULT 0
);

CREATE TABLE spell (
    id SERIAL PRIMARY KEY,
    category_id INT NOT NULL REFERENCES category(id),
    name VARCHAR(50) NOT NULL,
    base_cost INT NOT NULL,
    base_damage INT NOT NULL,
    accuracy INT NOT NULL CHECK (accuracy BETWEEN 1 AND 20)
);

CREATE TABLE spell_attribute (
    id SERIAL PRIMARY KEY,
    attribute_id INT NOT NULL REFERENCES attribute(id),
    spell_id INT NOT NULL REFERENCES spell(id),
    action action_type NOT NULL,
    modifier_type modifier_op NOT NULL
);

CREATE TABLE item (
    id SERIAL PRIMARY KEY,
    state item_state NOT NULL,
    item_modifier FLOAT NOT NULL,
    action action_type,
    name VARCHAR(50) NOT NULL,
    weight FLOAT NOT NULL CHECK (weight >=0),
    type item_type NOT NULL
);

CREATE TABLE inventory_item (
    id SERIAL PRIMARY KEY,
    character_id INT REFERENCES character(id),
    item_id INT REFERENCES item(id),
    is_equipped BOOLEAN DEFAULT false
);

CREATE TABLE combat (
    id SERIAL PRIMARY KEY,
    start_time TIMESTAMP,
    end_time TIMESTAMP
);

CREATE TABLE round (
    id SERIAL PRIMARY KEY,
    combat_id INT REFERENCES combat(id) NOT NULL,
    number INT NOT NULL CHECK (number > 0),
    start_time TIMESTAMP,
    end_time TIMESTAMP
);

CREATE TABLE battleground_item (
    id SERIAL PRIMARY KEY,
    item_id INT REFERENCES item(id),
    combat_id INT REFERENCES combat(id),
    is_taken BOOLEAN DEFAULT false
);

CREATE TABLE combat_participant (
    id SERIAL PRIMARY KEY,
    character_id INT REFERENCES character(id) NOT NULL,
    combat_id INT REFERENCES combat(id) NOT NULL,
    is_alive BOOLEAN DEFAULT true,
    join_time TIMESTAMP NOT NULL
);

CREATE TABLE combat_log (
    id SERIAL PRIMARY KEY,
    round_id INT NOT NULL REFERENCES round(id),
    combat_id INT NOT NULL REFERENCES combat(id),
    time TIMESTAMP NOT NULL,
    dice_throw INT DEFAULT 0 CHECK (dice_throw BETWEEN 0 AND 20),
    attacker_id INT REFERENCES combat_participant(id),
    target_id INT REFERENCES combat_participant(id),
    event_msg_type event_type NOT NULL,
    spell_id INT REFERENCES spell(id),
    ap_cost INT,
    damage INT,
    move_success BOOLEAN,
    item_id INT REFERENCES battleground_item(id)
);

CREATE INDEX idx_character_attr_pair ON character_attribute(character_id, attribute_id);
CREATE INDEX idx_combat_participant_alive ON combat_participant(combat_id, is_alive, character_id);
CREATE INDEX idx_inventory_item_is_equipped ON inventory_item(character_id,item_id,is_equipped);
CREATE INDEX idx_combat_item_is_taken ON battleground_item(combat_id,item_id,is_taken);
CREATE INDEX idx_round_time ON round(start_time,end_time);

