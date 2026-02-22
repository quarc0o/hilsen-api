import { type SupabaseClient } from "@supabase/supabase-js";

export async function getMyConversations(supabase: SupabaseClient, userId: string) {
  const { data, error } = await supabase
    .from("conversation_participants")
    .select("conversation_id")
    .eq("user_id", userId);

  if (error) throw error;
  if (!data || data.length === 0) return [];

  const ids = data.map((row) => row.conversation_id);

  const { data: conversations, error: convError } = await supabase
    .from("conversations")
    .select("*")
    .in("id", ids)
    .order("updated_at", { ascending: false });

  if (convError) throw convError;
  return conversations ?? [];
}

export async function getConversationMessages(supabase: SupabaseClient, conversationId: string) {
  const { data, error } = await supabase
    .from("messages")
    .select("*")
    .eq("conversation_id", conversationId)
    .order("created_at", { ascending: true });

  if (error) throw error;
  return data;
}

export async function sendMessage(
  supabase: SupabaseClient,
  conversationId: string,
  senderId: string,
  content: string,
) {
  const { data, error } = await supabase
    .from("messages")
    .insert({
      conversation_id: conversationId,
      sender_id: senderId,
      text_content: content,
    })
    .select()
    .single();

  if (error) throw error;

  // Update conversation's updated_at
  await supabase
    .from("conversations")
    .update({ updated_at: new Date().toISOString() })
    .eq("id", conversationId);

  return data;
}

export async function isConversationParticipant(
  supabase: SupabaseClient,
  conversationId: string,
  userId: string,
): Promise<boolean> {
  const { count, error } = await supabase
    .from("conversation_participants")
    .select("*", { count: "exact", head: true })
    .eq("conversation_id", conversationId)
    .eq("user_id", userId);

  if (error) throw error;
  return (count ?? 0) > 0;
}
