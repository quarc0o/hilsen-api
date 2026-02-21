import { Type, type Static } from "@sinclair/typebox";

export const ConversationSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
  created_at: Type.String(),
  updated_at: Type.String(),
});

export type Conversation = Static<typeof ConversationSchema>;

export const MessageSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
  conversation_id: Type.String({ format: "uuid" }),
  sender_id: Type.String({ format: "uuid" }),
  card_send_id: Type.Union([Type.String({ format: "uuid" }), Type.Null()]),
  content: Type.Union([Type.String(), Type.Null()]),
  created_at: Type.String(),
});

export type Message = Static<typeof MessageSchema>;

export const ConversationIdParamsSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
});

export type ConversationIdParams = Static<typeof ConversationIdParamsSchema>;

export const SendMessageBodySchema = Type.Object({
  content: Type.String({ minLength: 1 }),
});

export type SendMessageBody = Static<typeof SendMessageBodySchema>;
