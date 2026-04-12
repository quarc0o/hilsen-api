import { type SupabaseClient } from "@supabase/supabase-js";

export async function createCard(
  supabase: SupabaseClient,
  userId: string,
  card: { template_id: string },
) {
  const { data, error } = await supabase
    .from("greeting_cards")
    .insert({
      creator_id: userId,
      template_id: card.template_id,
      status: "draft",
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function getCardById(supabase: SupabaseClient, cardId: string) {
  const { data, error } = await supabase
    .from("greeting_cards")
    .select("*")
    .eq("id", cardId)
    .single();

  if (error && error.code === "PGRST116") {
    return null;
  }

  if (error) throw error;
  return data;
}

export async function getMyCards(supabase: SupabaseClient, userId: string) {
  const { data, error } = await supabase
    .from("greeting_cards")
    .select("*")
    .eq("creator_id", userId)
    .order("created_at", { ascending: false });

  if (error) throw error;
  return data;
}

export async function updateCard(
  supabase: SupabaseClient,
  cardId: string,
  updates: Partial<{
    message: string;
    card_backside_url: string | null;
    overlay_items: unknown;
  }>,
) {
  const { data, error } = await supabase
    .from("greeting_cards")
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
  const { error } = await supabase.from("greeting_cards").delete().eq("id", cardId);

  if (error) throw error;
}
