// utils.ts
import { v4 as uuidv4 } from "https://esm.sh/uuid@9.0.0";
import { ChatMessage, ScheduledCard } from "./types.ts";

// Check if a date is in the future
export function isFutureDate(date: Date): boolean {
  const currentDate = new Date();
  return date > currentDate;
}

// Check if we should send a message immediately based on time difference
export function shouldSendImmediately(messageDate: Date): boolean {
  const currentDate = new Date();
  const timeDifferenceInMs = Math.abs(
    currentDate.getTime() - messageDate.getTime()
  );

  // Time threshold: 1000 seconds
  // (similar to your original 1 * 60 * 10 * 10 * 10)
  const threshold = 1000 * 1000;

  return timeDifferenceInMs < threshold;
}

// Create a scheduled card object
export function createScheduledCard(
  chat_message: ChatMessage,
  chatMessageId: string,
  conversationId: string,
  scheduledDate: Date
): ScheduledCard {
  return {
    id: uuidv4(),
    sender_first_name: chat_message.sender_user?.first_name ?? "",
    recipient_email: chat_message.recipient_mail,
    gift_id: chatMessageId,
    card_frontside_url:
      chat_message.gift?.greeting_card?.card_frontside_url ?? "",
    chat_message_id: chatMessageId,
    conversation_id: conversationId,
    scheduled_at: scheduledDate.toISOString(),
    created_at: new Date().toISOString(),
  };
}

// Create a JSON response
export function createJsonResponse(data: any, status: number = 200): Response {
  return new Response(JSON.stringify(data), {
    status: status,
    headers: { "Content-Type": "application/json" },
  });
}

// Create a success response
export function createSuccessResponse(message: string): Response {
  return createJsonResponse({ success: true, data: message });
}

// Create an error response
export function createErrorResponse(
  error: string,
  status: number = 500
): Response {
  return createJsonResponse({ error }, status);
}
