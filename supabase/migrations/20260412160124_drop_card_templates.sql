-- Templates now live in Directus CMS (directus.quarcoo.no / Greeting_Cards collection).
-- Drop the FK from greeting_cards.template_id -> card_templates so the column
-- stores a plain UUID referencing the Directus item ID.

ALTER TABLE greeting_cards DROP CONSTRAINT IF EXISTS greeting_cards_template_id_fkey;

-- Drop the card_templates table and its indexes / policies
DROP POLICY IF EXISTS templates_read ON card_templates;
DROP TABLE IF EXISTS card_templates;
