import { type SupabaseClient } from "@supabase/supabase-js";
import { sendCardSms, type TwilioConfig } from "./notifications.service.js";

export interface SendsWorkerConfig {
  twilio: TwilioConfig;
  appBaseUrl: string;
}

export const MONTHLY_SEND_LIMIT = 2;

export async function getMonthlySendUsage(supabase: SupabaseClient, senderId: string) {
  const { data, error } = await supabase.rpc("count_card_sends_this_month", {
    p_sender_id: senderId,
  });
  if (error) throw error;
  const used = (data as number | null) ?? 0;
  return {
    used,
    limit: MONTHLY_SEND_LIMIT,
    remaining: Math.max(0, MONTHLY_SEND_LIMIT - used),
  };
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

  const senderFirstName = await fetchSenderFirstName(supabase, senderId);

  const baseRows = recipientPhones.map((rawPhone) => ({
    card_id: cardId,
    sender_id: senderId,
    recipient_phone: rawPhone.replace(/^\+/, ""),
    send_group_id: sendGroupId,
    status: "scheduled" as const,
    scheduled_at: null,
    sent_at: null,
  }));

  const { data: inserted, error: insertError } = await supabase
    .from("card_sends")
    .insert(baseRows)
    .select();

  if (insertError) throw insertError;

  const now = new Date().toISOString();
  await Promise.all(
    inserted.map(async (send) => {
      const cardViewUrl = `${appBaseUrl}/s/${send.short_code}`;
      const result = await sendCardSms(
        twilioConfig,
        send.recipient_phone,
        senderFirstName,
        cardViewUrl,
        { cardSendId: send.id },
      );

      const update = result.success
        ? { status: "sent", sent_at: now, error: null }
        : { status: "failed", error: result.error ?? "Unknown error" };

      const { error } = await supabase.from("card_sends").update(update).eq("id", send.id);
      if (error) throw error;
    }),
  );

  const { data, error } = await supabase
    .from("card_sends")
    .select("*")
    .in(
      "id",
      inserted.map((s) => s.id),
    );

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
    .neq("status", "canceled")
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
    .select("*, greeting_cards(design_id), users!card_sends_sender_id_fkey(first_name)")
    .eq("id", sendId)
    .single();

  if (error && error.code === "PGRST116") {
    return null;
  }

  if (error) throw error;

  const { greeting_cards, users, ...send } = data;
  return {
    ...send,
    card_design_id: (greeting_cards as { design_id: string | null } | null)?.design_id ?? null,
    sender_first_name: (users as { first_name: string | null } | null)?.first_name ?? null,
  };
}

export async function getSendByShortCode(supabase: SupabaseClient, shortCode: string) {
  const { data, error } = await supabase
    .from("card_sends")
    .select("*, greeting_cards(design_id), users!card_sends_sender_id_fkey(first_name)")
    .eq("short_code", shortCode)
    .single();

  if (error && error.code === "PGRST116") {
    return null;
  }

  if (error) throw error;

  const { greeting_cards, users, ...send } = data;
  return {
    ...send,
    card_design_id: (greeting_cards as { design_id: string | null } | null)?.design_id ?? null,
    sender_first_name: (users as { first_name: string | null } | null)?.first_name ?? null,
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

async function fetchSenderFirstName(supabase: SupabaseClient, senderId: string) {
  const { data: sender } = await supabase
    .from("users")
    .select("first_name")
    .eq("id", senderId)
    .single();
  return sender?.first_name ?? "Noen";
}

async function deliverAndUpdate(
  supabase: SupabaseClient,
  send: { id: string; short_code: string; recipient_phone: string },
  senderFirstName: string,
  twilioConfig: TwilioConfig,
  appBaseUrl: string,
) {
  const cardViewUrl = `${appBaseUrl}/s/${send.short_code}`;
  const result = await sendCardSms(
    twilioConfig,
    send.recipient_phone,
    senderFirstName,
    cardViewUrl,
    { cardSendId: send.id },
  );

  const update = result.success
    ? { status: "sent", sent_at: new Date().toISOString(), error: null }
    : { status: "failed", error: result.error ?? "Unknown error" };

  const { error } = await supabase.from("card_sends").update(update).eq("id", send.id);
  if (error) throw error;
}

export async function sendNow(
  supabase: SupabaseClient,
  sendId: string,
  senderId: string,
  twilioConfig: TwilioConfig,
  appBaseUrl: string,
) {
  const send = await getSendById(supabase, sendId);
  if (!send) return { error: "not_found" as const };
  if (send.sender_id !== senderId) return { error: "forbidden" as const };
  if (send.status !== "scheduled") return { error: "already_sent" as const };

  const senderFirstName = await fetchSenderFirstName(supabase, senderId);
  await deliverAndUpdate(supabase, send, senderFirstName, twilioConfig, appBaseUrl);

  const { data, error } = await supabase.from("card_sends").select("*").eq("id", sendId).single();
  if (error) throw error;

  return { data };
}

export async function sendGroupNow(
  supabase: SupabaseClient,
  sendGroupId: string,
  senderId: string,
  twilioConfig: TwilioConfig,
  appBaseUrl: string,
) {
  const { data: sends, error: fetchError } = await supabase
    .from("card_sends")
    .select("*")
    .eq("send_group_id", sendGroupId)
    .eq("sender_id", senderId)
    .eq("status", "scheduled");

  if (fetchError) throw fetchError;
  if (!sends || sends.length === 0) return { error: "not_found" as const };

  const senderFirstName = await fetchSenderFirstName(supabase, senderId);

  await Promise.all(
    sends.map((send) =>
      deliverAndUpdate(supabase, send, senderFirstName, twilioConfig, appBaseUrl),
    ),
  );

  const ids = sends.map((s) => s.id);
  const { data, error } = await supabase.from("card_sends").select("*").in("id", ids);
  if (error) throw error;

  return { data };
}

export async function cancelSend(supabase: SupabaseClient, sendId: string, senderId: string) {
  const send = await getSendById(supabase, sendId);
  if (!send) return { error: "not_found" as const };
  if (send.sender_id !== senderId) return { error: "forbidden" as const };
  if (send.status !== "scheduled") return { error: "already_sent" as const };

  const { error } = await supabase
    .from("card_sends")
    .update({ status: "canceled" })
    .eq("id", sendId);

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

  // Compute the recipient diff up front so we can quota-check before any writes.
  let phonesToRemoveIds: string[] = [];
  let phonesToAdd: string[] = [];
  let normalizedPhones: string[] = [];
  if (updates.recipientPhones) {
    const existingPhones = new Set(existingSends.map((s) => s.recipient_phone));
    normalizedPhones = updates.recipientPhones.map((p) => p.replace(/^\+/, ""));
    const newPhones = new Set(normalizedPhones);
    const phonesToRemove = existingSends.filter((s) => !newPhones.has(s.recipient_phone));
    phonesToRemoveIds = phonesToRemove.map((s) => s.id);
    phonesToAdd = normalizedPhones.filter((p) => !existingPhones.has(p));
  }

  // Quota check: only rows we're inserting count; rows being canceled in the same
  // op credit back, so swapping recipients at the limit is legal.
  if (phonesToAdd.length > 0) {
    const { used, limit, remaining } = await getMonthlySendUsage(supabase, senderId);
    const effectiveRemaining = remaining + phonesToRemoveIds.length;
    if (phonesToAdd.length > effectiveRemaining) {
      return {
        error: "quota_exceeded" as const,
        quota: { used, limit, remaining, requested: phonesToAdd.length },
      };
    }
  }

  if (updates.scheduledAt) {
    const { error } = await supabase
      .from("card_sends")
      .update({ scheduled_at: updates.scheduledAt })
      .eq("send_group_id", sendGroupId)
      .eq("sender_id", senderId)
      .eq("status", "scheduled");

    if (error) throw error;
  }

  if (updates.recipientPhones) {
    if (phonesToRemoveIds.length > 0) {
      const { error } = await supabase
        .from("card_sends")
        .update({ status: "canceled" })
        .in("id", phonesToRemoveIds);

      if (error) throw error;
    }

    if (phonesToAdd.length > 0) {
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
    .update({ status: "canceled" })
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
    const cardViewUrl = `${config.appBaseUrl}/s/${send.short_code}`;
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
