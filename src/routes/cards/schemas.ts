import { Type, type Static } from "@sinclair/typebox";

export const CardStatus = Type.Union([Type.Literal("draft"), Type.Literal("ready")]);

export const CardSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
  creator_id: Type.String({ format: "uuid" }),
  template_id: Type.String({ format: "uuid" }),
  status: CardStatus,
  card_backside_url: Type.Union([Type.String(), Type.Null()]),
  message: Type.Union([Type.String(), Type.Null()]),
  overlay_items: Type.Union([Type.Any(), Type.Null()]),
  created_at: Type.String(),
  updated_at: Type.String(),
});

export type Card = Static<typeof CardSchema>;

export const CreateCardBodySchema = Type.Object({
  template_id: Type.String({ format: "uuid" }),
});

export type CreateCardBody = Static<typeof CreateCardBodySchema>;

export const UpdateCardBodySchema = Type.Object({
  message: Type.Optional(Type.String()),
  card_backside_url: Type.Optional(Type.Union([Type.String(), Type.Null()])),
  overlay_items: Type.Optional(Type.Any()),
  status: Type.Optional(CardStatus),
});

export type UpdateCardBody = Static<typeof UpdateCardBodySchema>;

export const CardIdParamsSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
});

export type CardIdParams = Static<typeof CardIdParamsSchema>;
