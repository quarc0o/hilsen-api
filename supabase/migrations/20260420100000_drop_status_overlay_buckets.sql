-- Drop status (always 'draft', redundant) and its partial index
DROP INDEX IF EXISTS idx_greeting_cards_drafts;

ALTER TABLE greeting_cards DROP COLUMN IF EXISTS status;

-- Drop overlay_items (overlays no longer tracked in DB)
ALTER TABLE greeting_cards DROP COLUMN IF EXISTS overlay_items;