import { Type, type Static } from "@sinclair/typebox";

export const CardStatus = Type.Union([Type.Literal("draft"), Type.Literal("ready")]);

export const CardSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
  user_id: Type.String({ format: "uuid" }),
  template_id: Type.Union([Type.String({ format: "uuid" }), Type.Null()]),
  body: Type.Union([Type.String(), Type.Null()]),
  media_url: Type.Union([Type.String(), Type.Null()]),
  status: CardStatus,
  created_at: Type.String(),
  updated_at: Type.String(),
});

export type Card = Static<typeof CardSchema>;

export const CreateCardBodySchema = Type.Object({
  template_id: Type.Optional(Type.String({ format: "uuid" })),
  body: Type.Optional(Type.String()),
  media_url: Type.Optional(Type.String()),
});

export type CreateCardBody = Static<typeof CreateCardBodySchema>;

export const UpdateCardBodySchema = Type.Object({
  body: Type.Optional(Type.String()),
  media_url: Type.Optional(Type.Union([Type.String(), Type.Null()])),
  status: Type.Optional(CardStatus),
});

export type UpdateCardBody = Static<typeof UpdateCardBodySchema>;

export const CardIdParamsSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
});

export type CardIdParams = Static<typeof CardIdParamsSchema>;
