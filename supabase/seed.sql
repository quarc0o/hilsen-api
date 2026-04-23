-- Local development setup - this file runs AFTER migrations.
-- The baseline migration handles tables, policies, buckets, and the
-- on_auth_user_created trigger; this file is only for things Supabase
-- Cloud auto-provides but the local dev Docker image doesn't.

CREATE SCHEMA IF NOT EXISTS "pgsodium";
