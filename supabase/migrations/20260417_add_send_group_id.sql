ALTER TABLE card_sends ADD COLUMN send_group_id UUID;

CREATE INDEX idx_card_sends_group ON card_sends(send_group_id) WHERE send_group_id IS NOT NULL;
