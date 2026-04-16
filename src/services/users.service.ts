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
  updates: Partial<{ first_name: string; last_name: string; email: string | null }>,
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
  const { error } = await supabase.from("users").delete().eq("id", userId);

  if (error) throw error;
}


