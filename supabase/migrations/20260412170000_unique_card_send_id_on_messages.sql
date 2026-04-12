-- Enforce that each card_send can only produce one message (idempotency safety net)
CREATE UNIQUE INDEX IF NOT EXISTS idx_messages_card_send_id_unique
  ON messages (card_send_id)
  WHERE card_send_id IS NOT NULL;
