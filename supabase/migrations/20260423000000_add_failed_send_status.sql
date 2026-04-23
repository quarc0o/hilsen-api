-- Extend card_sends status enum with 'failed' and add an error column
-- so immediate sends can record per-recipient Twilio failures, and the
-- scheduled worker can mark stuck rows instead of silently looping.
ALTER TABLE card_sends
  DROP CONSTRAINT card_sends_status_check;

ALTER TABLE card_sends
  ADD CONSTRAINT card_sends_status_check CHECK (status IN ('scheduled', 'sent', 'failed'));

ALTER TABLE card_sends
  ADD COLUMN error TEXT;
