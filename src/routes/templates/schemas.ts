import { Type, type Static } from "@sinclair/typebox";

export const TemplateSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
  slug: Type.String(),
  title: Type.String(),
  body_template: Type.String(),
  category: Type.String(),
  image_url: Type.Union([Type.String(), Type.Null()]),
  is_active: Type.Boolean(),
  created_at: Type.String(),
  updated_at: Type.String(),
});

export type Template = Static<typeof TemplateSchema>;

export const TemplateCategorySchema = Type.Object({
  category: Type.String(),
  count: Type.Number(),
});

export type TemplateCategory = Static<typeof TemplateCategorySchema>;

export const GetTemplatesQuerySchema = Type.Object({
  category: Type.Optional(Type.String()),
  limit: Type.Optional(Type.Number({ minimum: 1, maximum: 100 })),
  offset: Type.Optional(Type.Number({ minimum: 0 })),
});

export type GetTemplatesQuery = Static<typeof GetTemplatesQuerySchema>;

export const TemplateSlugParamsSchema = Type.Object({
  slug: Type.String(),
});

export type TemplateSlugParams = Static<typeof TemplateSlugParamsSchema>;
