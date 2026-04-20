import { Type, type Static } from "@sinclair/typebox";

export const DesignSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
  card_title: Type.String(),
  categories: Type.Array(Type.String()),
  image_url: Type.String(),
});

export type Design = Static<typeof DesignSchema>;

export const DesignCategorySchema = Type.Object({
  category: Type.String(),
  count: Type.Number(),
});

export type DesignCategory = Static<typeof DesignCategorySchema>;

export const GetDesignsQuerySchema = Type.Object({
  category: Type.Optional(Type.String()),
  search: Type.Optional(Type.String()),
  limit: Type.Optional(Type.Number({ minimum: 1, maximum: 100 })),
  offset: Type.Optional(Type.Number({ minimum: 0 })),
});

export type GetDesignsQuery = Static<typeof GetDesignsQuerySchema>;

export const DesignIdParamsSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
});

export type DesignIdParams = Static<typeof DesignIdParamsSchema>;
