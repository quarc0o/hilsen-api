// types.ts
export type DeliveryStatus = "PENDING" | "DELIVERED" | "OPENED" | "SCHEDULED";

export interface ChatMessage {
  id?: string;
  sender_phone_number: string;
  recipient_mail?: string;
  gift?: {
    greeting_card?: {
      card_frontside_url?: string;
    };
  };
  sender_user?: {
    first_name?: string;
  };
  participant_phone_numbers: string[];
  sent_at: string;
  conversation_id?: string;
}

export interface ScheduledCard {
  id: string;
  sender_first_name?: string;
  recipient_email?: string;
  gift_id?: string;
  card_frontside_url?: string;
  chat_message_id: string;
  conversation_id: string;
  scheduled_at: string;
  created_at: string;
}

export interface EmailParams {
  senderFirstName: string;
  recipientEmail: string;
  giftId: string;
  cardFrontsideUrl: string;
}
