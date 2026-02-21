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
  updates: Partial<{ display_name: string; avatar_url: string | null }>,
) {
  const { data, error } = await supabase
    .from("users")
    .update({ ...updates, updated_at: new Date().toISOString() })
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

export async function findOrCreateUserByPhone(supabase: SupabaseClient, phone: string) {
  // Check if user exists with this phone
  const { data: existing, error: findError } = await supabase
    .from("users")
    .select("*")
    .eq("phone", phone)
    .single();

  if (existing) return { user: existing, created: false };

  if (findError && findError.code !== "PGRST116") {
    throw findError;
  }

  // Create a lazy user (no supabase_id yet)
  const { data: created, error: createError } = await supabase
    .from("users")
    .insert({ phone, supabase_id: `lazy:${phone}` })
    .select()
    .single();

  if (createError) throw createError;
  return { user: created, created: true };
}

export async function matchLazyUser(supabase: SupabaseClient, supabaseId: string, phone: string) {
  // Find a lazy user with this phone and link to the real supabase_id
  const { data, error } = await supabase
    .from("users")
    .update({ supabase_id: supabaseId, updated_at: new Date().toISOString() })
    .eq("phone", phone)
    .like("supabase_id", "lazy:%")
    .select()
    .single();

  if (error && error.code === "PGRST116") {
    return null;
  }

  if (error) throw error;
  return data;
}
