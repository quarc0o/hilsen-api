-- Replace the old status constraint (pending/scheduled/sent/delivered/opened)
-- with the reduced enum (scheduled/sent)
ALTER TABLE card_sends
  DROP CONSTRAINT card_sends_status_check;

ALTER TABLE card_sends
  ADD CONSTRAINT card_sends_status_check CHECK (status IN ('scheduled', 'sent'));
