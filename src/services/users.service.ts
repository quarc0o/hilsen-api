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

export async function findOrCreateUserByPhone(supabase: SupabaseClient, phone: string) {
  const { data: existing, error: findError } = await supabase
    .from("users")
    .select("*")
    .eq("phone_number", phone)
    .single();

  if (existing) return { user: existing, created: false };

  if (findError && findError.code !== "PGRST116") {
    throw findError;
  }

  // Create a lazy user (no supabase_id yet — handle_new_user trigger links on signup)
  const { data: created, error: createError } = await supabase
    .from("users")
    .insert({ phone_number: phone })
    .select()
    .single();

  if (createError) throw createError;
  return { user: created, created: true };
}

export async function matchLazyUser(supabase: SupabaseClient, userId: string, phone: string) {
  // Link card_sends that have recipient_phone matching but no recipient_id
  const { error } = await supabase
    .from("card_sends")
    .update({ recipient_id: userId })
    .eq("recipient_phone", phone)
    .is("recipient_id", null);

  if (error) throw error;
}
