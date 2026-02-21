import { type SupabaseClient } from "@supabase/supabase-js";

export async function createCard(
  supabase: SupabaseClient,
  userId: string,
  card: {
    template_id?: string;
    body?: string;
    media_url?: string;
  },
) {
  const { data, error } = await supabase
    .from("cards")
    .insert({
      user_id: userId,
      ...card,
      status: "draft",
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function getCardById(supabase: SupabaseClient, cardId: string) {
  const { data, error } = await supabase.from("cards").select("*").eq("id", cardId).single();

  if (error && error.code === "PGRST116") {
    return null;
  }

  if (error) throw error;
  return data;
}

export async function getMyCards(supabase: SupabaseClient, userId: string) {
  const { data, error } = await supabase
    .from("cards")
    .select("*")
    .eq("user_id", userId)
    .order("created_at", { ascending: false });

  if (error) throw error;
  return data;
}

export async function updateCard(
  supabase: SupabaseClient,
  cardId: string,
  updates: Partial<{
    body: string;
    media_url: string | null;
    status: "draft" | "ready";
  }>,
) {
  const { data, error } = await supabase
    .from("cards")
    .update({ ...updates, updated_at: new Date().toISOString() })
    .eq("id", cardId)
    .select()
    .single();

  if (error && error.code === "PGRST116") {
    return null;
  }

  if (error) throw error;
  return data;
}

export async function deleteCard(supabase: SupabaseClient, cardId: string) {
  const { error } = await supabase.from("cards").delete().eq("id", cardId);

  if (error) throw error;
}
