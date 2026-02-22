import { Type, type Static } from "@sinclair/typebox";
import { TemplateSchema } from "../../templates/schemas.js";

export { TemplateSchema };

export const CreateTemplateBodySchema = Type.Object({
  slug: Type.String({ minLength: 1 }),
  title: Type.String({ minLength: 1 }),
  category: Type.String({ minLength: 1 }),
  image_url: Type.String({ minLength: 1 }),
  subtitle: Type.Optional(Type.Union([Type.String(), Type.Null()])),
  description: Type.Optional(Type.Union([Type.String(), Type.Null()])),
  tags: Type.Optional(Type.Array(Type.String())),
  is_premium: Type.Optional(Type.Boolean()),
  sort_order: Type.Optional(Type.Number()),
});

export type CreateTemplateBody = Static<typeof CreateTemplateBodySchema>;

export const UpdateTemplateBodySchema = Type.Object({
  slug: Type.Optional(Type.String({ minLength: 1 })),
  title: Type.Optional(Type.String({ minLength: 1 })),
  subtitle: Type.Optional(Type.Union([Type.String(), Type.Null()])),
  description: Type.Optional(Type.Union([Type.String(), Type.Null()])),
  category: Type.Optional(Type.String({ minLength: 1 })),
  tags: Type.Optional(Type.Array(Type.String())),
  image_url: Type.Optional(Type.String({ minLength: 1 })),
  is_premium: Type.Optional(Type.Boolean()),
  is_published: Type.Optional(Type.Boolean()),
  sort_order: Type.Optional(Type.Number()),
});

export type UpdateTemplateBody = Static<typeof UpdateTemplateBodySchema>;

export const TemplateIdParamsSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
});

export type TemplateIdParams = Static<typeof TemplateIdParamsSchema>;
