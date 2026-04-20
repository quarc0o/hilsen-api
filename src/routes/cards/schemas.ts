import { Type, type Static } from "@sinclair/typebox";

export const CardSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
  creator_id: Type.String({ format: "uuid" }),
  design_id: Type.String({ format: "uuid" }),
  message: Type.Union([Type.String(), Type.Null()]),
  created_at: Type.String(),
  updated_at: Type.String(),
});

export type Card = Static<typeof CardSchema>;

export const CreateCardBodySchema = Type.Object({
  design_id: Type.String({ format: "uuid" }),
});

export type CreateCardBody = Static<typeof CreateCardBodySchema>;

export const UpdateCardBodySchema = Type.Object({
  message: Type.Optional(Type.String()),
});

export type UpdateCardBody = Static<typeof UpdateCardBodySchema>;

export const CardIdParamsSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
});

export type CardIdParams = Static<typeof CardIdParamsSchema>;
