-- Rename greeting_cards.template_id → design_id.
-- The column references a Directus item (front-side card design). "Template" is
-- being repurposed for editable back-side overlay templates, so the front-side
-- concept is renamed to "design" to avoid ambiguity.

ALTER TABLE greeting_cards RENAME COLUMN template_id TO design_id;
ALTER INDEX idx_greeting_cards_template RENAME TO idx_greeting_cards_design;
