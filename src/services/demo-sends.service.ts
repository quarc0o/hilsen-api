import { type SupabaseClient } from "@supabase/supabase-js";
import { sendDemoSms, type TwilioConfig } from "./notifications.service.js";
import { getOptedOutPhones } from "./opt-outs.service.js";

export interface DemoSendConfig {
  twilio: TwilioConfig;
  appBaseUrl: string;
  demoUserId: string;
  demoCardId: string;
  demoDailyCap: number;
}

export type DemoSendResult =
  | { ok: true; card_send_id: string }
  | { error: "opted_out" }
  | { error: "already_sent" }
  | { error: "daily_cap_reached" }
  | { error: "sms_failed"; message: string };

function todayStartUtcIso(): string {
  const now = new Date();
  return new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), 0, 0, 0),
  ).toISOString();
}

export async function sendDemoCard(
  supabase: SupabaseClient,
  phoneRaw: string,
  config: DemoSendConfig,
): Promise<DemoSendResult> {
  const phone = phoneRaw.replace(/^\+/, "");

  const optedOut = await getOptedOutPhones(supabase, [phone]);
  if (optedOut.has(phone)) return { error: "opted_out" };

  // Daily cap: soft-atomic (check-then-insert race is bounded by concurrency,
  // which is tiny for this traffic. A handful of over-cap sends is acceptable
  // vs. the complexity of a proper transaction.)
  const { count: dailyCount, error: countError } = await supabase
    .from("demo_send_recipients")
    .select("*", { count: "exact", head: true })
    .gte("first_sent_at", todayStartUtcIso());
  if (countError) throw countError;
  if ((dailyCount ?? 0) >= config.demoDailyCap) return { error: "daily_cap_reached" };

  // Lifetime-1: PK conflict == already demoed.
  const { error: insertRecipientError } = await supabase
    .from("demo_send_recipients")
    .insert({ phone_number: phone });
  if (insertRecipientError) {
    if (insertRecipientError.code === "23505") return { error: "already_sent" };
    throw insertRecipientError;
  }

  const { data: send, error: insertSendError } = await supabase
    .from("card_sends")
    .insert({
      card_id: config.demoCardId,
      sender_id: config.demoUserId,
      recipient_phone: phone,
      status: "scheduled",
    })
    .select()
    .single();
  if (insertSendError) {
    // Roll back the recipient row so the user isn't permanently blocked by a
    // failure that had nothing to do with them.
    await supabase.from("demo_send_recipients").delete().eq("phone_number", phone);
    throw insertSendError;
  }

  const cardViewUrl = `${config.appBaseUrl}/s/${send.short_code}`;
  const privacyUrl = `${config.appBaseUrl}/personvern`;
  const result = await sendDemoSms(config.twilio, phone, cardViewUrl, privacyUrl, {
    cardSendId: send.id,
  });

  if (!result.success) {
    await supabase
      .from("card_sends")
      .update({ status: "failed", error: result.error ?? "Unknown error" })
      .eq("id", send.id);
    // Free the phone so the user can try again (typos, carrier errors).
    await supabase.from("demo_send_recipients").delete().eq("phone_number", phone);
    return { error: "sms_failed", message: result.error ?? "Unknown error" };
  }

  await supabase
    .from("card_sends")
    .update({ status: "sent", sent_at: new Date().toISOString() })
    .eq("id", send.id);

  return { ok: true, card_send_id: send.id };
}
