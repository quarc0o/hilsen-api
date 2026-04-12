import { Type, type Static } from "@sinclair/typebox";

export const TemplateSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
  card_title: Type.String(),
  categories: Type.Array(Type.String()),
  image_url: Type.String(),
});

export type Template = Static<typeof TemplateSchema>;

export const TemplateCategorySchema = Type.Object({
  category: Type.String(),
  count: Type.Number(),
});

export type TemplateCategory = Static<typeof TemplateCategorySchema>;

export const GetTemplatesQuerySchema = Type.Object({
  category: Type.Optional(Type.String()),
  search: Type.Optional(Type.String()),
  limit: Type.Optional(Type.Number({ minimum: 1, maximum: 100 })),
  offset: Type.Optional(Type.Number({ minimum: 0 })),
});

export type GetTemplatesQuery = Static<typeof GetTemplatesQuerySchema>;

export const TemplateIdParamsSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
});

export type TemplateIdParams = Static<typeof TemplateIdParamsSchema>;
