import { type SupabaseClient } from "@supabase/supabase-js";
import { sendCardSms, type TwilioConfig } from "./notifications.service.js";

export interface SendsWorkerConfig {
  twilio: TwilioConfig;
  appBaseUrl: string;
}

export async function sendCard(
  supabase: SupabaseClient,
  senderId: string,
  cardId: string,
  options: { recipientPhones: string[]; scheduledAt: string },
) {
  const { recipientPhones, scheduledAt } = options;

  const sendGroupId = recipientPhones.length > 1 ? crypto.randomUUID() : null;

  const rows = recipientPhones.map((phone) => ({
    card_id: cardId,
    sender_id: senderId,
    recipient_phone: phone.replace(/^\+/, ""),
    send_group_id: sendGroupId,
    status: "scheduled",
    scheduled_at: scheduledAt,
    sent_at: null,
  }));

  const { data: sends, error } = await supabase.from("card_sends").insert(rows).select();

  if (error) throw error;

  return sends;
}

export async function sendCardImmediate(
  supabase: SupabaseClient,
  senderId: string,
  cardId: string,
  options: { recipientPhones: string[] },
  twilioConfig: TwilioConfig,
  appBaseUrl: string,
) {
  const { recipientPhones } = options;
  const sendGroupId = recipientPhones.length > 1 ? crypto.randomUUID() : null;

  const { data: sender } = await supabase
    .from("users")
    .select("first_name")
    .eq("id", senderId)
    .single();
  const senderFirstName = sender?.first_name ?? "Noen";

  const now = new Date().toISOString();
  const rows = await Promise.all(
    recipientPhones.map(async (rawPhone) => {
      const id = crypto.randomUUID();
      const phone = rawPhone.replace(/^\+/, "");
      const cardViewUrl = `${appBaseUrl}/s/${id}`;
      const result = await sendCardSms(twilioConfig, phone, senderFirstName, cardViewUrl, {
        cardSendId: id,
      });

      return {
        id,
        card_id: cardId,
        sender_id: senderId,
        recipient_phone: phone,
        send_group_id: sendGroupId,
        status: result.success ? "sent" : "failed",
        scheduled_at: null,
        sent_at: result.success ? now : null,
        error: result.success ? null : (result.error ?? "Unknown error"),
      };
    }),
  );

  const { data, error } = await supabase.from("card_sends").insert(rows).select();

  if (error) throw error;

  return data;
}

export async function getReceivedSends(supabase: SupabaseClient, userId: string) {
  const { data: user, error: userError } = await supabase
    .from("users")
    .select("phone_number")
    .eq("id", userId)
    .single();

  if (userError) throw userError;
  if (!user?.phone_number) return [];

  const { data, error } = await supabase
    .from("card_sends")
    .select("*, greeting_cards(design_id)")
    .eq("recipient_phone", user.phone_number)
    .eq("status", "sent")
    .order("created_at", { ascending: false });

  if (error) throw error;
  return (data ?? []).map(({ greeting_cards, ...send }) => ({
    ...send,
    card_design_id: (greeting_cards as { design_id: string | null } | null)?.design_id ?? null,
  }));
}

export async function getMySends(supabase: SupabaseClient, userId: string) {
  const { data, error } = await supabase
    .from("card_sends")
    .select("*, greeting_cards(design_id)")
    .eq("sender_id", userId)
    .order("created_at", { ascending: false });

  if (error) throw error;
  return (data ?? []).map(({ greeting_cards, ...send }) => ({
    ...send,
    card_design_id: (greeting_cards as { design_id: string | null } | null)?.design_id ?? null,
  }));
}

export async function getSendById(supabase: SupabaseClient, sendId: string) {
  const { data, error } = await supabase
    .from("card_sends")
    .select("*, greeting_cards(design_id)")
    .eq("id", sendId)
    .single();

  if (error && error.code === "PGRST116") {
    return null;
  }

  if (error) throw error;

  const { greeting_cards, ...send } = data;
  return {
    ...send,
    card_design_id: (greeting_cards as { design_id: string | null } | null)?.design_id ?? null,
  };
}

export async function updateScheduledSend(
  supabase: SupabaseClient,
  sendId: string,
  senderId: string,
  updates: { scheduledAt?: string; recipientPhone?: string; recipientPhones?: string[] },
) {
  const send = await getSendById(supabase, sendId);
  if (!send) return { error: "not_found" as const };
  if (send.sender_id !== senderId) return { error: "forbidden" as const };
  if (send.status !== "scheduled") return { error: "already_sent" as const };

  // If recipient_phones provided, expand into a group
  if (updates.recipientPhones) {
    const sendGroupId = send.send_group_id ?? crypto.randomUUID();

    // Assign group ID to the existing send if it doesn't have one
    if (!send.send_group_id) {
      const updateFields: Record<string, unknown> = { send_group_id: sendGroupId };
      if (updates.scheduledAt) updateFields.scheduled_at = updates.scheduledAt;

      const { error } = await supabase.from("card_sends").update(updateFields).eq("id", sendId);

      if (error) throw error;
    }

    // Delegate to updateSendGroup for the diff logic
    return updateSendGroup(supabase, sendGroupId, senderId, {
      scheduledAt: updates.scheduledAt,
      recipientPhones: updates.recipientPhones,
    });
  }

  // Simple single-field updates
  const updateFields: Record<string, unknown> = {};
  if (updates.scheduledAt) updateFields.scheduled_at = updates.scheduledAt;
  if (updates.recipientPhone)
    updateFields.recipient_phone = updates.recipientPhone.replace(/^\+/, "");

  const { data, error } = await supabase
    .from("card_sends")
    .update(updateFields)
    .eq("id", sendId)
    .select()
    .single();

  if (error) throw error;
  return { data };
}

export async function cancelSend(supabase: SupabaseClient, sendId: string, senderId: string) {
  const send = await getSendById(supabase, sendId);
  if (!send) return { error: "not_found" as const };
  if (send.sender_id !== senderId) return { error: "forbidden" as const };
  if (send.status !== "scheduled") return { error: "already_sent" as const };

  const { error } = await supabase.from("card_sends").delete().eq("id", sendId);

  if (error) throw error;
  return { success: true };
}

export async function updateSendGroup(
  supabase: SupabaseClient,
  sendGroupId: string,
  senderId: string,
  updates: { scheduledAt?: string; recipientPhones?: string[] },
) {
  const { data: existingSends, error: fetchError } = await supabase
    .from("card_sends")
    .select("*")
    .eq("send_group_id", sendGroupId)
    .eq("sender_id", senderId)
    .eq("status", "scheduled");

  if (fetchError) throw fetchError;
  if (!existingSends || existingSends.length === 0) return { error: "not_found" as const };

  // Update scheduled_at on all existing scheduled sends if provided
  if (updates.scheduledAt) {
    const { error } = await supabase
      .from("card_sends")
      .update({ scheduled_at: updates.scheduledAt })
      .eq("send_group_id", sendGroupId)
      .eq("sender_id", senderId)
      .eq("status", "scheduled");

    if (error) throw error;
  }

  // Diff recipient phones if provided
  if (updates.recipientPhones) {
    const existingPhones = new Set(existingSends.map((s) => s.recipient_phone));
    const normalizedPhones = updates.recipientPhones.map((p) => p.replace(/^\+/, ""));
    const newPhones = new Set(normalizedPhones);

    // Delete sends for removed phones
    const phonesToRemove = existingSends.filter((s) => !newPhones.has(s.recipient_phone));
    if (phonesToRemove.length > 0) {
      const { error } = await supabase
        .from("card_sends")
        .delete()
        .in(
          "id",
          phonesToRemove.map((s) => s.id),
        );

      if (error) throw error;
    }

    // Insert sends for added phones
    const phonesToAdd = normalizedPhones.filter((p) => !existingPhones.has(p));
    if (phonesToAdd.length > 0) {
      // Use card_id and scheduled_at from an existing send in the group
      const reference = existingSends[0];
      const scheduledAt = updates.scheduledAt ?? reference.scheduled_at;

      const rows = phonesToAdd.map((phone) => ({
        card_id: reference.card_id,
        sender_id: senderId,
        recipient_phone: phone,
        send_group_id: sendGroupId,
        status: "scheduled",
        scheduled_at: scheduledAt,
        sent_at: null,
      }));

      const { error } = await supabase.from("card_sends").insert(rows).select();

      if (error) throw error;
    }
  }

  // Re-fetch and return the current state of the group
  const { data, error } = await supabase
    .from("card_sends")
    .select("*")
    .eq("send_group_id", sendGroupId)
    .eq("sender_id", senderId)
    .eq("status", "scheduled");

  if (error) throw error;
  return { data };
}

export async function cancelSendGroup(
  supabase: SupabaseClient,
  sendGroupId: string,
  senderId: string,
) {
  const { data: sends, error: fetchError } = await supabase
    .from("card_sends")
    .select("*")
    .eq("send_group_id", sendGroupId)
    .eq("sender_id", senderId)
    .eq("status", "scheduled");

  if (fetchError) throw fetchError;
  if (!sends || sends.length === 0) return { error: "not_found" as const };

  const { error } = await supabase
    .from("card_sends")
    .delete()
    .eq("send_group_id", sendGroupId)
    .eq("sender_id", senderId)
    .eq("status", "scheduled");

  if (error) throw error;
  return { success: true };
}

export async function processScheduledSends(supabase: SupabaseClient, config: SendsWorkerConfig) {
  const { data: dueSends, error: fetchError } = await supabase
    .from("card_sends")
    .select("*")
    .eq("status", "scheduled")
    .lte("scheduled_at", new Date().toISOString());

  if (fetchError) throw fetchError;
  if (!dueSends || dueSends.length === 0) return [];

  const processed = [];

  for (const send of dueSends) {
    // 1. Send SMS via Twilio
    const { data: sender } = await supabase
      .from("users")
      .select("first_name")
      .eq("id", send.sender_id)
      .single();

    const senderFirstName = sender?.first_name ?? "Noen";
    const cardViewUrl = `${config.appBaseUrl}/s/${send.id}`;
    const result = await sendCardSms(
      config.twilio,
      send.recipient_phone,
      senderFirstName,
      cardViewUrl,
      { cardSendId: send.id },
    );

    // 2. If SMS fails, mark row as failed with the Twilio error and continue
    if (!result.success) {
      console.error(`[scheduled-sends] SMS failed for send ${send.id}: ${result.error}`);
      await supabase
        .from("card_sends")
        .update({ status: "failed", error: result.error ?? "Unknown error" })
        .eq("id", send.id);
      continue;
    }

    // 3. Mark card_send as sent
    const { error: updateError } = await supabase
      .from("card_sends")
      .update({ status: "sent", sent_at: new Date().toISOString() })
      .eq("id", send.id);

    if (updateError) continue;

    processed.push(send.id);
  }

  return processed;
}
