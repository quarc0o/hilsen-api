// repositories.ts
import { DeliveryStatus, ScheduledCard } from "./types.ts";

export class ConversationRepository {
  constructor(private supabase: any) {}

  async getConversationIdByParticipants(
    participants: string[]
  ): Promise<string | null> {
    const { data: conversationId, error } = await this.supabase.rpc(
      "find_conversation_by_participants",
      {
        participant_phone_numbers: participants,
      }
    );

    if (error) {
      console.error("Error fetching conversation id:", error);
      return null;
    }

    return conversationId;
  }

  async createConversationWithParticipants(
    participants: string[]
  ): Promise<string | Error> {
    const { data: conversationId, error } = await this.supabase.rpc(
      "create_conversation",
      {
        participant_phone_numbers: participants,
      }
    );

    if (error) {
      console.error("Error creating conversation:", error);
      return new Error("Failed to create conversation");
    }

    return conversationId;
  }
}

export class ChatMessageRepository {
  constructor(private supabase: any) {}

  async updateGiftDeliveryStatus(
    deliveryStatus: DeliveryStatus,
    chatMessageId: string,
    conversationId: string
  ) {
    try {
      const { data, error } = await this.supabase
        .from("chat_messages")
        .update({ delivery_status: deliveryStatus })
        .eq("id", chatMessageId);

      if (error) {
        console.log("Error updating gift delivery status:", error.message);
        throw new Error(
          `Error updating gift delivery status: ${error.message}`
        );
      }

      if (deliveryStatus === "DELIVERED" || deliveryStatus === "OPENED") {
        console.log("Updating conversation's last message");

        const { error } = await this.supabase.rpc(
          "update_conversation_last_message",
          {
            p_chat_message_id: chatMessageId,
            p_conversation_id: conversationId,
          }
        );

        if (error) {
          console.log(
            "Error updating conversation last message:",
            error.message
          );
          throw new Error(
            `Error updating conversation last message: ${error.message}`
          );
        }
      }

      if (data != null) {
        return data[0];
      }
    } catch (e) {
      console.log("Error updating gift delivery status:", e);
      throw e;
    }
  }
}

export class ScheduleChatMessageRepository {
  constructor(private supabase: any) {}

  async scheduleChatMessageForSending(scheduledCard: ScheduledCard) {
    try {
      const { data, error } = await this.supabase
        .from("scheduled_cards")
        .insert(scheduledCard)
        .select();

      console.log("Scheduled card:", data);

      if (error) {
        console.log("Error scheduling chat message:", error);
        throw new Error(`Error scheduling chat message: ${error.message}`);
      }

      return data;
    } catch (e) {
      console.log("Error scheduling chat message:", e);
      throw new Error(`Error scheduling chat message: ${e}`);
    }
  }
}
