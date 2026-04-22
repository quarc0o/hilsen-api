import { type SupabaseClient } from "@supabase/supabase-js";
import { deletePostHogPerson, type PostHogConfig } from "../lib/posthog.js";

export async function getUserById(supabase: SupabaseClient, userId: string) {
  const { data, error } = await supabase.from("users").select("*").eq("id", userId).single();

  if (error && error.code === "PGRST116") {
    return null;
  }

  if (error) throw error;
  return data;
}

export async function getUserBySupabaseId(supabase: SupabaseClient, supabaseId: string) {
  const { data, error } = await supabase
    .from("users")
    .select("*")
    .eq("supabase_id", supabaseId)
    .single();

  if (error && error.code === "PGRST116") {
    return null;
  }

  if (error) throw error;
  return data;
}

export async function updateUser(
  supabase: SupabaseClient,
  userId: string,
  updates: Partial<{ first_name: string; last_name: string | null; email: string | null }>,
) {
  const { data, error } = await supabase
    .from("users")
    .update(updates)
    .eq("id", userId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

export interface DeleteUserDeps {
  supabase: SupabaseClient;
  userId: string;
  supabaseId: string;
  posthog: PostHogConfig | null;
  // Called for non-fatal cleanup failures (orphan storage / PostHog miss).
  // Fatal errors are thrown.
  onWarning?: (message: string, detail: Record<string, unknown>) => void;
}

// Deletes a user and every trace of them:
//   1. auth.users row — DB rows cascade (public.users → greeting_cards, card_sends)
//      via FK ON DELETE CASCADE (migration 20260422000000).
//   2. Storage objects under card-images/{userId}/.
//   3. PostHog person + events.
//
// Auth delete must succeed (otherwise the user still has a live session).
// Storage and PostHog failures are logged but not fatal — leftover files or
// analytics records are benign and can be swept later.
export async function deleteUser(deps: DeleteUserDeps): Promise<void> {
  const { supabase, userId, supabaseId, posthog, onWarning } = deps;

  const { error: authError } = await supabase.auth.admin.deleteUser(supabaseId);
  if (authError) throw authError;

  try {
    await removeUserStorage(supabase, userId);
  } catch (error) {
    onWarning?.("failed to delete user storage", { userId, error });
  }

  if (posthog) {
    const result = await deletePostHogPerson(posthog, supabaseId);
    if (!result.ok) {
      onWarning?.("failed to delete posthog person", { supabaseId, result });
    }
  }
}

async function removeUserStorage(supabase: SupabaseClient, userId: string): Promise<void> {
  const bucket = supabase.storage.from("card-images");
  const userFolder = `${userId}`;

  const { data: files } = await bucket.list(userFolder, { limit: 1000 });
  if (!files || files.length === 0) return;

  const allPaths: string[] = [];

  for (const item of files) {
    if (item.id === null) {
      const { data: subFiles } = await bucket.list(`${userFolder}/${item.name}`, { limit: 1000 });
      if (subFiles) {
        for (const sub of subFiles) {
          if (sub.id === null) {
            const { data: deepFiles } = await bucket.list(
              `${userFolder}/${item.name}/${sub.name}`,
              { limit: 1000 },
            );
            if (deepFiles) {
              allPaths.push(
                ...deepFiles.map((f) => `${userFolder}/${item.name}/${sub.name}/${f.name}`),
              );
            }
          } else {
            allPaths.push(`${userFolder}/${item.name}/${sub.name}`);
          }
        }
      }
    } else {
      allPaths.push(`${userFolder}/${item.name}`);
    }
  }

  if (allPaths.length > 0) {
    await bucket.remove(allPaths);
  }
}
