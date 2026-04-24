import { Type, type Static } from "@sinclair/typebox";

export enum SendStatusEnum {
  Scheduled = "scheduled",
  Sent = "sent",
  Failed = "failed",
  Canceled = "canceled",
}

export const SendStatus = Type.Enum(SendStatusEnum);

export const CardSendSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
  short_code: Type.String(),
  card_id: Type.String({ format: "uuid" }),
  sender_id: Type.String({ format: "uuid" }),
  recipient_phone: Type.Union([Type.String(), Type.Null()]),
  send_group_id: Type.Union([Type.String({ format: "uuid" }), Type.Null()]),
  status: SendStatus,
  scheduled_at: Type.Union([Type.String(), Type.Null()]),
  sent_at: Type.Union([Type.String(), Type.Null()]),
  opened_at: Type.Union([Type.String(), Type.Null()]),
  error: Type.Union([Type.String(), Type.Null()]),
  created_at: Type.String(),
  card_backside_url: Type.Optional(Type.Union([Type.String(), Type.Null()])),
  card_design_image_url: Type.Optional(Type.Union([Type.String(), Type.Null()])),
  sender_first_name: Type.Optional(Type.Union([Type.String(), Type.Null()])),
  message: Type.Optional(Type.Union([Type.String(), Type.Null()])),
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

export const SendShortCodeParamsSchema = Type.Object({
  code: Type.String(),
});

export type SendShortCodeParams = Static<typeof SendShortCodeParamsSchema>;

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

export const QuotaExceededSchema = Type.Object({
  error: Type.String(),
  used: Type.Integer(),
  limit: Type.Integer(),
  remaining: Type.Integer(),
  requested: Type.Integer(),
});

export type QuotaExceeded = Static<typeof QuotaExceededSchema>;

export const RecipientsOptedOutSchema = Type.Object({
  error: Type.String(),
  opted_out: Type.Array(Type.String()),
});

export type RecipientsOptedOut = Static<typeof RecipientsOptedOutSchema>;

export const SendUsageSchema = Type.Object({
  this_month: Type.Object({
    used: Type.Integer(),
    limit: Type.Integer(),
    remaining: Type.Integer(),
  }),
  all_time: Type.Integer(),
  resets_at: Type.String(),
});

export type SendUsage = Static<typeof SendUsageSchema>;
