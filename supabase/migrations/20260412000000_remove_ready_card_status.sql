-- Remove the "ready" card status. Cards now go directly from "draft" to being sent.
-- First update any existing "ready" cards back to "draft"
UPDATE greeting_cards SET status = 'draft' WHERE status = 'ready';

-- Replace the CHECK constraint to only allow "draft"
ALTER TABLE greeting_cards
  DROP CONSTRAINT IF EXISTS greeting_cards_status_check;

ALTER TABLE greeting_cards
  ADD CONSTRAINT greeting_cards_status_check CHECK (status IN ('draft'));
