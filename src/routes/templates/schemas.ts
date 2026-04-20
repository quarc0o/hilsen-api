import { Type, type Static } from "@sinclair/typebox";

export const TemplateSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
  data: Type.Any(),
  preview_url: Type.String(),
});

export type Template = Static<typeof TemplateSchema>;

export const TemplateIdParamsSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
});

export type TemplateIdParams = Static<typeof TemplateIdParamsSchema>;
