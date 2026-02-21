import { Type, type Static } from "@sinclair/typebox";
import { TemplateSchema } from "../../templates/schemas.js";

export { TemplateSchema };

export const CreateTemplateBodySchema = Type.Object({
  slug: Type.String({ minLength: 1 }),
  title: Type.String({ minLength: 1 }),
  body_template: Type.String({ minLength: 1 }),
  category: Type.String({ minLength: 1 }),
  image_url: Type.Optional(Type.Union([Type.String(), Type.Null()])),
});

export type CreateTemplateBody = Static<typeof CreateTemplateBodySchema>;

export const UpdateTemplateBodySchema = Type.Object({
  slug: Type.Optional(Type.String({ minLength: 1 })),
  title: Type.Optional(Type.String({ minLength: 1 })),
  body_template: Type.Optional(Type.String({ minLength: 1 })),
  category: Type.Optional(Type.String({ minLength: 1 })),
  image_url: Type.Optional(Type.Union([Type.String(), Type.Null()])),
  is_active: Type.Optional(Type.Boolean()),
});

export type UpdateTemplateBody = Static<typeof UpdateTemplateBodySchema>;

export const TemplateIdParamsSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
});

export type TemplateIdParams = Static<typeof TemplateIdParamsSchema>;
