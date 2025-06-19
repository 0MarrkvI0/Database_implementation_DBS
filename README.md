# Turn-Based RPG Combat System – PostgreSQL Implementation

**Autor:** Martin Kvietok  
**Predmet:** Database Systems  
**Fakulta:** Fakulta informatiky a informačných technológií, STU Bratislava  

## Popis projektu

**Database modeling by creating an E-R diagram and a logical model.**  
**The goal is to understand how to design tables, relationships, and attributes for future database development.** *(Subject: Database Systems)*

Toto zadanie sa zameriava na implementáciu RPG bojového systému v PostgreSQL. Projekt obsahuje definíciu tabuliek, procedúr, logiky súbojov, regenerácie, manipulácie s predmetmi a logovania udalostí.

## Obsah

### Funkcie a procedúry

- `p_rest_character` – Simulácia odpočinku postavy a regenerácia zdravia a AP.
- `p_enter_combat` – Zapojenie postavy do prebiehajúceho súboja.
- `p_reset_round` – Ukončenie aktuálneho kola a začatie nového.
- `p_loot_item` – Získanie predmetu z bojiska postavou.
- `p_effective_spell_cost` – Výpočet efektívnej ceny kúzla pre postavu.
- `p_cast_spell` – Zoslanie kúzla vrátane výpočtu AP, zásahu a účinkov.

### Výpočty a modelovanie

- Efektívne poškodenie a cena kúzla sú počítané pomocou hráčových atribútov, vybavenia a kúzla.
- Redukcia poškodenia zohľadňuje brnenie cieľa.

### Indexy

Projekt obsahuje optimalizované indexy pre rýchle vyhľadávanie:

- `idx_character_attr_pair`
- `idx_combat_participant_alive`
- `idx_inventory_item_is_equipped`
- `idx_combat_item_is_taken`
- `idx_round_time`

### Zmeny oproti predchádzajúcim verziám

- Nové akcie predmetov (liečenie, znižovanie AP, zvyšovanie poškodenia)
- Pridané časové stopy k bojom (`start_time`, `end_time`)
- Rozšírené typy udalostí v `combat_log` (`login`, `winner`, `round_start`, `round_end`)

## Testovanie a spustenie

**Poradie krokov:**

1. Spustiť `create_db.sql` – vytvorenie schémy databázy
2. Spustiť všetky skripty `p_*.sql` – uložené procedúry
3. Spustiť `init_db.sql` – naplnenie testovacími dátami
4. Spustiť testy v poradí:
   - `test_p_rest.sql`
   - `test_p_enter_combat.sql`
   - `test_p_loot_item.sql`
   - `test_p_cast_spell.sql`
   - `test_p_reset_round.sql`
5. Vytvoriť pohľady zo skriptov `v_*.sql`

## Použitá technológia

- **PostgreSQL** – relačná databáza pre spracovanie hierarchie a logiky súbojov
- **PL/pgSQL** – jazyk pre procedurálne funkcie a trigger logiku
- **UML diagramy** – modelovanie správania funkcií

## Diagramy

- Fyzický model databázy
- UML aktivity pre každú funkciu
