import { type SupabaseClient } from "@supabase/supabase-js";

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

export async function deleteUser(supabase: SupabaseClient, userId: string) {
  // Clean up all user images from storage before deleting the DB row
  const bucket = supabase.storage.from("card-images");
  const userFolder = `${userId}`;

  // List all objects under the user's folder and delete them in batches
  const { data: files } = await bucket.list(userFolder, { limit: 1000 });
  if (files && files.length > 0) {
    // Files may be nested in subfolders — list each subfolder recursively
    const allPaths: string[] = [];

    for (const item of files) {
      if (item.id === null) {
        // It's a folder — list its contents
        const { data: subFiles } = await bucket.list(`${userFolder}/${item.name}`, { limit: 1000 });
        if (subFiles) {
          for (const sub of subFiles) {
            if (sub.id === null) {
              // Another level (e.g. overlays/{cardId}/)
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

  const { error } = await supabase.from("users").delete().eq("id", userId);

  if (error) throw error;
}
