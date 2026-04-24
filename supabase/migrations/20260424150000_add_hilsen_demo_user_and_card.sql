-- ============================================================
-- Hilsen Demo user + greeting card
-- ============================================================
-- Seeds a well-known user + greeting_card used exclusively by the
-- public example-card-send feature (POST /demo-sends). All demo
-- sends are attributed to this user, which keeps the card_sends
-- FK to users satisfied without polluting real user accounts.
--
-- UUIDs are intentionally sentinel-like so they are easy to spot
-- in the DB. Not secret — the API ref them via env vars:
--   DEMO_USER_ID = 00000000-0000-4000-8000-000000000001
--   DEMO_CARD_ID = 00000000-0000-4000-8000-000000000002
--
-- The design_id references a Directus design (soft FK — there is
-- no DB-level FK to Directus). The backside image, when uploaded,
-- lives at card-images/<DEMO_USER_ID>/<DEMO_CARD_ID>.png.
-- Supabase Storage folders are virtual, so no bucket DDL is needed
-- here; the folder appears implicitly on the first upload.
-- ============================================================

INSERT INTO
    public.users (
        id,
        first_name,
        phone_number,
        email
    )
VALUES (
        '00000000-0000-4000-8000-000000000001',
        'Hilsen',
        NULL,
        NULL
    )
ON CONFLICT (id) DO NOTHING;

INSERT INTO
    public.greeting_cards (
        id,
        creator_id,
        design_id,
        message
    )
VALUES (
        '00000000-0000-4000-8000-000000000002',
        '00000000-0000-4000-8000-000000000001',
        'b0a84f0a-550b-4b39-95c1-348ac2dd8577',
        'En eksempel-hilsen fra Hilsen. Lag ditt eget kort på hilsen.app!'
    )
ON CONFLICT (id) DO NOTHING;