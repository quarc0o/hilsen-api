-- card_backside_url is no longer stored; the API derives the path
-- from sender_id + card_id: card-images/{sender_id}/{card_id}.png
ALTER TABLE greeting_cards DROP COLUMN IF EXISTS card_backside_url;