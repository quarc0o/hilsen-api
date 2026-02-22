import { Type, type Static } from "@sinclair/typebox";

export const TemplateSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
  title: Type.String(),
  subtitle: Type.Union([Type.String(), Type.Null()]),
  description: Type.Union([Type.String(), Type.Null()]),
  category: Type.String(),
  tags: Type.Union([Type.Array(Type.String()), Type.Null()]),
  slug: Type.String(),
  image_url: Type.String(),
  is_premium: Type.Boolean(),
  is_published: Type.Boolean(),
  sort_order: Type.Number(),
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
  tags: Type.Optional(Type.String()),
  search: Type.Optional(Type.String()),
  limit: Type.Optional(Type.Number({ minimum: 1, maximum: 100 })),
  offset: Type.Optional(Type.Number({ minimum: 0 })),
});

export type GetTemplatesQuery = Static<typeof GetTemplatesQuerySchema>;

export const TemplateSlugParamsSchema = Type.Object({
  slug: Type.String(),
});

export type TemplateSlugParams = Static<typeof TemplateSlugParamsSchema>;
