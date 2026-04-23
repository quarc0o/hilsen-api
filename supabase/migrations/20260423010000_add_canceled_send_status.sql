-- Add 'canceled' status so removing a recipient from a scheduled group
-- (or cancelling a whole send) becomes a soft-delete. Hard deletes lose
-- audit trail and silently lose visibility if a diff bug ever skips a row.
ALTER TABLE card_sends
  DROP CONSTRAINT card_sends_status_check;

ALTER TABLE card_sends
  ADD CONSTRAINT card_sends_status_check
  CHECK (status IN ('scheduled', 'sent', 'failed', 'canceled'));
