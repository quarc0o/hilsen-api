import { type SupabaseClient } from "@supabase/supabase-js";
import { findOrCreateUserByPhone } from "./users.service.js";

export async function sendCard(
  supabase: SupabaseClient,
  senderId: string,
  cardId: string,
  options: { recipientPhone?: string; recipientEmail?: string; scheduledAt?: string },
) {
  const { recipientPhone, recipientEmail, scheduledAt } = options;

  // 1. Resolve recipient if phone provided
  let recipientId: string | null = null;
  if (recipientPhone) {
    const { user: recipient } = await findOrCreateUserByPhone(supabase, recipientPhone);
    recipientId = recipient.id;
  }

  // 2. Find or create conversation between sender and recipient
  let conversationId: string | null = null;
  if (recipientId) {
    conversationId = await findOrCreateConversation(supabase, senderId, recipientId);
  }

  // 3. Create the card_send record (always "scheduled" — the worker moves it to "sent")
  const { data: send, error: sendError } = await supabase
    .from("card_sends")
    .insert({
      card_id: cardId,
      sender_id: senderId,
      recipient_id: recipientId,
      recipient_phone: recipientPhone ?? null,
      recipient_email: recipientEmail ?? null,
      conversation_id: conversationId,
      status: "scheduled",
      scheduled_at: scheduledAt ?? new Date().toISOString(),
      sent_at: null,
    })
    .select()
    .single();

  if (sendError) throw sendError;

  return send;
}

async function findOrCreateConversation(
  supabase: SupabaseClient,
  userAId: string,
  userBId: string,
): Promise<string> {
  // Look for an existing conversation between these two users
  const { data: existing, error: findError } = await supabase
    .from("conversations")
    .select("id, conversation_participants!inner(user_id)")
    .in("conversation_participants.user_id", [userAId, userBId]);

  if (findError) throw findError;

  // Find a conversation that has BOTH users
  if (existing) {
    for (const conv of existing) {
      const participants = (conv.conversation_participants as Array<{ user_id: string }>).map(
        (p) => p.user_id,
      );
      if (participants.includes(userAId) && participants.includes(userBId)) {
        return conv.id;
      }
    }
  }

  // Create new conversation
  const { data: newConv, error: createError } = await supabase
    .from("conversations")
    .insert({})
    .select()
    .single();

  if (createError) throw createError;

  // Add participants
  const { error: partError } = await supabase.from("conversation_participants").insert([
    { conversation_id: newConv.id, user_id: userAId },
    { conversation_id: newConv.id, user_id: userBId },
  ]);

  if (partError) throw partError;

  return newConv.id;
}

export async function getMySends(supabase: SupabaseClient, userId: string) {
  const { data, error } = await supabase
    .from("card_sends")
    .select("*")
    .or(`sender_id.eq.${userId},recipient_id.eq.${userId}`)
    .order("created_at", { ascending: false });

  if (error) throw error;
  return data;
}

export async function getSendById(supabase: SupabaseClient, sendId: string) {
  const { data, error } = await supabase.from("card_sends").select("*").eq("id", sendId).single();

  if (error && error.code === "PGRST116") {
    return null;
  }

  if (error) throw error;
  return data;
}

export async function processScheduledSends(supabase: SupabaseClient) {
  const { data: dueSends, error: fetchError } = await supabase
    .from("card_sends")
    .select("*")
    .eq("status", "scheduled")
    .lte("scheduled_at", new Date().toISOString());

  if (fetchError) throw fetchError;
  if (!dueSends || dueSends.length === 0) return [];

  const processed = [];

  for (const send of dueSends) {
    const { error: updateError } = await supabase
      .from("card_sends")
      .update({ status: "sent", sent_at: new Date().toISOString() })
      .eq("id", send.id);

    if (updateError) continue;

    // Insert the message into the conversation
    if (send.conversation_id) {
      await supabase.from("messages").insert({
        conversation_id: send.conversation_id,
        sender_id: send.sender_id,
        card_send_id: send.id,
      });

      await supabase
        .from("conversations")
        .update({ updated_at: new Date().toISOString() })
        .eq("id", send.conversation_id);
    }

    processed.push(send.id);
  }

  return processed;
}
