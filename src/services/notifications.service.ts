import twilio from "twilio";

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
): Promise<SmsResult> {
  try {
    const twilioClient = getClient(config);
    const e164Phone = `+${recipientPhone.replace(/^\+/, "")}`;
    const message = await twilioClient.messages.create({
      to: e164Phone,
      from: config.senderId,
      body: `${senderFirstName} har sendt deg en hilsen. Se den her: ${cardViewUrl}`,
    });

    return { success: true, messageSid: message.sid };
  } catch (err) {
    const errorMessage = err instanceof Error ? err.message : String(err);
    return { success: false, error: errorMessage };
  }
}
