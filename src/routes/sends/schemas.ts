import { Type, type Static } from "@sinclair/typebox";

export const SendStatus = Type.Union([
  Type.Literal("pending"),
  Type.Literal("sent"),
  Type.Literal("delivered"),
  Type.Literal("scheduled"),
]);

export const CardSendSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
  card_id: Type.String({ format: "uuid" }),
  sender_id: Type.String({ format: "uuid" }),
  recipient_id: Type.String({ format: "uuid" }),
  conversation_id: Type.String({ format: "uuid" }),
  status: SendStatus,
  scheduled_at: Type.Union([Type.String(), Type.Null()]),
  sent_at: Type.Union([Type.String(), Type.Null()]),
  created_at: Type.String(),
});

export type CardSend = Static<typeof CardSendSchema>;

export const SendCardBodySchema = Type.Object({
  recipient_phone: Type.String(),
  scheduled_at: Type.Optional(Type.String()),
});

export type SendCardBody = Static<typeof SendCardBodySchema>;

export const SendCardParamsSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
});

export type SendCardParams = Static<typeof SendCardParamsSchema>;

export const SendIdParamsSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
});

export type SendIdParams = Static<typeof SendIdParamsSchema>;
