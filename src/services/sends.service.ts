import { type SupabaseClient } from "@supabase/supabase-js";
import { findOrCreateUserByPhone } from "./users.service.js";

export async function sendCard(
  supabase: SupabaseClient,
  senderId: string,
  cardId: string,
  recipientPhone: string,
  scheduledAt?: string,
) {
  // 1. Resolve recipient (find or create lazy user)
  const { user: recipient } = await findOrCreateUserByPhone(supabase, recipientPhone);

  // 2. Find or create conversation between sender and recipient
  const conversationId = await findOrCreateConversation(supabase, senderId, recipient.id);

  // 3. Create the card_send record
  const status = scheduledAt ? "scheduled" : "sent";
  const { data: send, error: sendError } = await supabase
    .from("card_sends")
    .insert({
      card_id: cardId,
      sender_id: senderId,
      recipient_id: recipient.id,
      conversation_id: conversationId,
      status,
      scheduled_at: scheduledAt ?? null,
      sent_at: scheduledAt ? null : new Date().toISOString(),
    })
    .select()
    .single();

  if (sendError) throw sendError;

  // 4. Insert a message into the conversation
  if (!scheduledAt) {
    const { error: msgError } = await supabase.from("messages").insert({
      conversation_id: conversationId,
      sender_id: senderId,
      card_send_id: send.id,
      content: null,
    });

    if (msgError) throw msgError;
  }

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
    .eq("sender_id", userId)
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
    // Mark as sent
    const { error: updateError } = await supabase
      .from("card_sends")
      .update({ status: "sent", sent_at: new Date().toISOString() })
      .eq("id", send.id);

    if (updateError) continue;

    // Insert the message
    await supabase.from("messages").insert({
      conversation_id: send.conversation_id,
      sender_id: send.sender_id,
      card_send_id: send.id,
      content: null,
    });

    processed.push(send.id);
  }

  return processed;
}
