import { type FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import { Type } from "@sinclair/typebox";
import {
  DesignSchema,
  DesignCategorySchema,
  GetDesignsQuerySchema,
  DesignIdParamsSchema,
} from "./schemas.js";
import { getDesigns, getDesignCategories, getDesignById } from "../../services/designs.service.js";
import { notFound } from "../../lib/errors.js";

const designRoutes: FastifyPluginAsyncTypebox = async (fastify) => {
  const directusUrl = fastify.config.DIRECTUS_URL;

  fastify.get(
    "/",
    {
      schema: {
        querystring: GetDesignsQuerySchema,
        response: {
          200: Type.Array(DesignSchema),
        },
      },
    },
    async (request) => {
      const { category, search, limit, offset } = request.query;
      return getDesigns(directusUrl, { category, search, limit, offset });
    },
  );

  fastify.get(
    "/categories",
    {
      schema: {
        response: {
          200: Type.Array(DesignCategorySchema),
        },
      },
    },
    async () => {
      return getDesignCategories(directusUrl);
    },
  );

  fastify.get(
    "/:id",
    {
      schema: {
        params: DesignIdParamsSchema,
        response: {
          200: DesignSchema,
        },
      },
    },
    async (request, reply) => {
      const design = await getDesignById(directusUrl, request.params.id);
      if (!design) {
        return notFound(reply, "Design not found");
      }
      return design;
    },
  );
};

export default designRoutes;
