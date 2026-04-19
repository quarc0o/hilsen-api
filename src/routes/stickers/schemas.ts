import { Type, type Static } from "@sinclair/typebox";

export const StickerSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
  image_url: Type.String(),
});

export type Sticker = Static<typeof StickerSchema>;

export const StickerIdParamsSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
});

export type StickerIdParams = Static<typeof StickerIdParamsSchema>;
