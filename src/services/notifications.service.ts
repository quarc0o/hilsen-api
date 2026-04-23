import twilio from "twilio";
import { captureWithTags } from "../lib/sentry.js";

export interface TwilioConfig {
  accountSid: string;
  authToken: string;
  senderId: string;
}

export interface SmsResult {
  success: boolean;
  messageSid?: string;
  error?: string;
}

export interface SendCardSmsContext {
  cardSendId?: string;
}

let client: twilio.Twilio | null = null;

function getClient(config: TwilioConfig): twilio.Twilio {
  if (!client) {
    client = twilio(config.accountSid, config.authToken);
  }
  return client;
}

export async function sendCardSms(
  config: TwilioConfig,
  recipientPhone: string,
  senderFirstName: string,
  cardViewUrl: string,
  privacyUrl: string,
  context: SendCardSmsContext = {},
): Promise<SmsResult> {
  try {
    const twilioClient = getClient(config);
    const e164Phone = `+${recipientPhone.replace(/^\+/, "")}`;
    const message = await twilioClient.messages.create({
      to: e164Phone,
      from: config.senderId,
      body: `${senderFirstName} har sendt deg en hilsen!\n\nÅpne: ${cardViewUrl}\n\nPersonvern og stopp SMS: ${privacyUrl}`,
    });

    return { success: true, messageSid: message.sid };
  } catch (err) {
    const twilioErr = err as { code?: number | string; status?: number | string };
    captureWithTags(err, {
      "twilio.error_code": twilioErr.code,
      "twilio.status": twilioErr.status,
      card_send_id: context.cardSendId,
    });
    const errorMessage = err instanceof Error ? err.message : String(err);
    return { success: false, error: errorMessage };
  }
}
