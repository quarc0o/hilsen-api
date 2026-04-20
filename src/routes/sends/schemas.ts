import { Type, type Static } from "@sinclair/typebox";

export enum SendStatusEnum {
  Scheduled = "scheduled",
  Sent = "sent",
}

export const SendStatus = Type.Enum(SendStatusEnum);

export const CardSendSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
  card_id: Type.String({ format: "uuid" }),
  sender_id: Type.String({ format: "uuid" }),
  recipient_phone: Type.Union([Type.String(), Type.Null()]),
  send_group_id: Type.Union([Type.String({ format: "uuid" }), Type.Null()]),
  status: SendStatus,
  scheduled_at: Type.Union([Type.String(), Type.Null()]),
  sent_at: Type.Union([Type.String(), Type.Null()]),
  opened_at: Type.Union([Type.String(), Type.Null()]),
  created_at: Type.String(),
  card_backside_url: Type.Optional(Type.Union([Type.String(), Type.Null()])),
  card_design_image_url: Type.Optional(Type.Union([Type.String(), Type.Null()])),
});

export type CardSend = Static<typeof CardSendSchema>;

export const SendCardBodySchema = Type.Object({
  recipient_phones: Type.Array(Type.String(), { minItems: 1 }),
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

export const SendGroupIdParamsSchema = Type.Object({
  groupId: Type.String({ format: "uuid" }),
});

export type SendGroupIdParams = Static<typeof SendGroupIdParamsSchema>;

export const UpdateSendBodySchema = Type.Object({
  scheduled_at: Type.Optional(Type.String()),
  recipient_phone: Type.Optional(Type.String()),
  recipient_phones: Type.Optional(Type.Array(Type.String(), { minItems: 1 })),
});

export type UpdateSendBody = Static<typeof UpdateSendBodySchema>;

export const UpdateSendGroupBodySchema = Type.Object({
  scheduled_at: Type.Optional(Type.String()),
  recipient_phones: Type.Optional(Type.Array(Type.String(), { minItems: 1 })),
});

export type UpdateSendGroupBody = Static<typeof UpdateSendGroupBodySchema>;
