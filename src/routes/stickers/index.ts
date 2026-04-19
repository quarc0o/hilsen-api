import { type FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import { Type } from "@sinclair/typebox";
import { StickerSchema, StickerIdParamsSchema } from "./schemas.js";
import { getStickers, getStickerById } from "../../services/stickers.service.js";
import { notFound } from "../../lib/errors.js";

const stickerRoutes: FastifyPluginAsyncTypebox = async (fastify) => {
  const directusUrl = fastify.config.DIRECTUS_URL;

  fastify.get(
    "/",
    {
      schema: {
        response: {
          200: Type.Array(StickerSchema),
        },
      },
    },
    async () => {
      return getStickers(directusUrl);
    },
  );

  fastify.get(
    "/:id",
    {
      schema: {
        params: StickerIdParamsSchema,
        response: {
          200: StickerSchema,
        },
      },
    },
    async (request, reply) => {
      const sticker = await getStickerById(directusUrl, request.params.id);
      if (!sticker) {
        return notFound(reply, "Sticker not found");
      }
      return sticker;
    },
  );
};

export default stickerRoutes;
