import { type FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import { Type } from "@sinclair/typebox";
import {
  TemplateSchema,
  TemplateCategorySchema,
  GetTemplatesQuerySchema,
  TemplateIdParamsSchema,
} from "./schemas.js";
import {
  getTemplates,
  getTemplateCategories,
  getTemplateById,
} from "../../services/templates.service.js";
import { notFound } from "../../lib/errors.js";

const templateRoutes: FastifyPluginAsyncTypebox = async (fastify) => {
  const directusUrl = fastify.config.DIRECTUS_URL;

  fastify.get(
    "/",
    {
      schema: {
        querystring: GetTemplatesQuerySchema,
        response: {
          200: Type.Array(TemplateSchema),
        },
      },
    },
    async (request) => {
      const { category, search, limit, offset } = request.query;
      return getTemplates(directusUrl, { category, search, limit, offset });
    },
  );

  fastify.get(
    "/categories",
    {
      schema: {
        response: {
          200: Type.Array(TemplateCategorySchema),
        },
      },
    },
    async () => {
      return getTemplateCategories(directusUrl);
    },
  );

  fastify.get(
    "/:id",
    {
      schema: {
        params: TemplateIdParamsSchema,
        response: {
          200: TemplateSchema,
        },
      },
    },
    async (request, reply) => {
      const template = await getTemplateById(directusUrl, request.params.id);
      if (!template) {
        return notFound(reply, "Template not found");
      }
      return template;
    },
  );
};

export default templateRoutes;
