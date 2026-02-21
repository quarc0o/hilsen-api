// index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ChatMessage } from "./types.ts";
import { createSupabaseClient } from "./client.ts";
import {
  ConversationRepository,
  ChatMessageRepository,
  ScheduleChatMessageRepository,
} from "./repositories.ts";
import {
  FindConversationUsecase,
  CreateConversationUsecase,
  UpdateDeliveryStatusUsecase,
  ScheduleChatMessageUsecase,
} from "./usecases.ts";
import {
  createScheduledCard,
  isFutureDate,
  shouldSendImmediately,
  createSuccessResponse,
  createErrorResponse,
} from "./utils.ts";
import { sendGiftEmail } from "../send-gift-email/sendGiftEmail.ts";

// Server configuration
const serverOptions = {
  hostname: "0.0.0.0",
  port: 8000,
};

// Start the server
serve(handleRequest, serverOptions);

// Main request handler
async function handleRequest(req: Request): Promise<Response> {
  // Initialize Supabase client
  const supabase = createSupabaseClient();

  // Initialize repositories
  const conversationRepo = new ConversationRepository(supabase);
  const chatMessageRepo = new ChatMessageRepository(supabase);
  const scheduleRepo = new ScheduleChatMessageRepository(supabase);

  // Initialize use cases
  const findConversation = new FindConversationUsecase(conversationRepo);
  const createConversation = new CreateConversationUsecase(conversationRepo);
  const updateDeliveryStatus = new UpdateDeliveryStatusUsecase(chatMessageRepo);
  const scheduleChatMessage = new ScheduleChatMessageUsecase(scheduleRepo);

  try {
    // Parse the request body
    const chatMessage: ChatMessage = await req.json();
    console.log("Received message:", chatMessage);

    // Process the conversation
    const conversationId = await processConversation(
      chatMessage,
      findConversation,
      createConversation
    );

    if (!conversationId) {
      return createErrorResponse("Error processing conversation", 500);
    }

    // Insert the chat message with gift
    const insertedMessage = await insertChatMessage(
      supabase,
      chatMessage,
      conversationId
    );

    if (!insertedMessage) {
      return createErrorResponse("Error inserting chat message", 500);
    }

    // Process message delivery based on date
    return await processMessageDelivery(
      chatMessage,
      insertedMessage,
      conversationId,
      updateDeliveryStatus,
      scheduleChatMessage
    );
  } catch (error) {
    console.error("Unexpected error:", error);
    return createErrorResponse("Internal Server Error", 500);
  }
}

// Process the conversation (find or create)
async function processConversation(
  chatMessage: ChatMessage,
  findConversationUsecase: FindConversationUsecase,
  createConversationUsecase: CreateConversationUsecase
): Promise<string | null> {
  const participants = chatMessage.participant_phone_numbers;

  // Find existing conversation
  let conversationId = await findConversationUsecase.execute(participants);
  console.log("Conversation search result:", conversationId);

  // Create new conversation if needed
  if (!conversationId) {
    console.log("Creating a new conversation");
    const createResult = await createConversationUsecase.execute(participants);

    if (createResult instanceof Error) {
      console.error("Error creating conversation:", createResult);
      return null;
    } else {
      conversationId = createResult;
    }
  }

  console.log("Conversation ID determined:", conversationId);
  return conversationId;
}

// Insert chat message with gift
async function insertChatMessage(
  supabase: any,
  chatMessage: ChatMessage,
  conversationId: string
) {
  try {
    const { data, error } = await supabase.rpc(
      "insert_chat_message_with_gift",
      {
        chat_data: {
          ...chatMessage,
          conversation_id: conversationId,
        },
      }
    );

    if (error) {
      console.error("Error inserting chat message:", error);
      return null;
    }

    console.log("Inserted chat message:", data);
    return data;
  } catch (error) {
    console.error("Error in insertChatMessage:", error);
    return null;
  }
}

// Process message delivery based on date
async function processMessageDelivery(
  chatMessage: ChatMessage,
  insertedMessage: any,
  conversationId: string,
  updateDeliveryStatus: UpdateDeliveryStatusUsecase,
  scheduleChatMessage: ScheduleChatMessageUsecase
): Promise<Response> {
  try {
    // Parse the message date
    const messageDate = new Date(chatMessage.sent_at);
    console.log("Message date:", messageDate.toISOString());
    console.log("Current date:", new Date().toISOString());

    // Determine if we should send now or schedule
    const sendNow = shouldSendImmediately(messageDate);
    const isFuture = isFutureDate(messageDate);

    console.log("Send immediately?", sendNow);
    console.log("Is future date?", isFuture);

    // Send immediately or default case
    if (sendNow || !isFuture) {
      // Try to send email if needed
      if (chatMessage.gift && chatMessage.recipient_mail) {
        try {
          await sendEmailToRecipient(chatMessage, insertedMessage.gift_id);
        } catch (error) {
          console.error("Email sending failed:", error);
          // Continue without email if it fails
        }
      }

      // Update delivery status
      await updateDeliveryStatus.execute(
        "DELIVERED",
        insertedMessage.id,
        conversationId
      );

      return createSuccessResponse("Chat message delivered successfully");
    } else if (isFuture) {
      // Schedule for future delivery
      console.log(
        "Scheduling for future delivery at:",
        messageDate.toISOString()
      );

      const scheduledCard = createScheduledCard(
        chatMessage,
        insertedMessage.id,
        conversationId,
        messageDate
      );

      await scheduleChatMessage.execute(scheduledCard);

      await updateDeliveryStatus.execute(
        "SCHEDULED",
        insertedMessage.id,
        conversationId
      );

      return createSuccessResponse(
        `Chat message scheduled for sending at: ${chatMessage.sent_at}`
      );
    } else {
      // This should not happen with the improved logic
      return createErrorResponse("Invalid date for message delivery", 400);
    }
  } catch (error) {
    console.error("Error in processMessageDelivery:", error);
    return createErrorResponse("Error processing message delivery", 500);
  }
}

async function sendEmailToRecipient(
  chatMessage: ChatMessage,
  giftId: string
): Promise<void> {
  console.log("Sending email to recipient");

  const cardFrontsideUrl =
    chatMessage.gift?.greeting_card?.card_frontside_url ?? "";

  await sendGiftEmail({
    senderFirstName: chatMessage.sender_user?.first_name ?? "",
    recipientEmail: chatMessage.recipient_mail!,
    giftId: giftId || "Unknown Gift ID",
    cardFrontsideUrl: cardFrontsideUrl,
  });

  console.log("Email sent successfully");
}
