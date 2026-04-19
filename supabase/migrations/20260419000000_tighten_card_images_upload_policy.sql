-- Tighten the upload policy so authenticated users can only upload
-- to their own folder inside card-images (scoped by user id).
DROP POLICY "Authenticated upload card-images" ON storage.objects;

CREATE POLICY "Users upload own card-images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'card-images'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] IN (
            SELECT id::text FROM users WHERE supabase_id = auth.uid()
        )
    );
