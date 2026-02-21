-- Local development setup - this file runs AFTER migrations
-- Create schemas that might be missing in local development
CREATE SCHEMA IF NOT EXISTS "pgsodium";

-- For local development, we'll skip pg_cron as it requires special Docker setup
-- Your scheduled jobs won't run locally, but that's typically fine for development

-- Auth schema triggers for local development only
-- Create trigger on auth.users table for new user handling
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Storage setup for local development
-- Create greeting_cards bucket with public access
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('greeting_cards', 'greeting_cards', true, null, null)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Set up RLS policies for greeting_cards bucket
-- Allow all authenticated users to upload
CREATE POLICY "Allow authenticated uploads" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'greeting_cards');

-- Allow public read access
CREATE POLICY "Allow public downloads" ON storage.objects
FOR SELECT TO public
USING (bucket_id = 'greeting_cards');

-- Allow authenticated users to update their own uploads
CREATE POLICY "Allow users to update own objects" ON storage.objects
FOR UPDATE TO authenticated
USING (bucket_id = 'greeting_cards' AND auth.uid() = owner)
WITH CHECK (bucket_id = 'greeting_cards');

-- Allow authenticated users to delete their own uploads
CREATE POLICY "Allow users to delete own objects" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'greeting_cards' AND auth.uid() = owner);