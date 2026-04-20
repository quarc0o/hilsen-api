import { Type, type Static } from "@sinclair/typebox";

export const PlaceholderImageSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
  image_url: Type.String(),
});

export type PlaceholderImage = Static<typeof PlaceholderImageSchema>;
