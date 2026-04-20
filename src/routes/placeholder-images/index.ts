import { type FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import { Type } from "@sinclair/typebox";
import { PlaceholderImageSchema } from "./schemas.js";
import { getPlaceholderImages } from "../../services/placeholder-images.service.js";

const placeholderImageRoutes: FastifyPluginAsyncTypebox = async (fastify) => {
  fastify.get(
    "/",
    {
      schema: {
        response: {
          200: Type.Array(PlaceholderImageSchema),
        },
      },
    },
    async () => {
      return getPlaceholderImages(fastify.config.DIRECTUS_URL);
    },
  );
};

export default placeholderImageRoutes;
