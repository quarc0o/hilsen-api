import { type FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import { Type } from "@sinclair/typebox";
import {
  TemplateSchema,
  TemplateCategorySchema,
  GetTemplatesQuerySchema,
  TemplateSlugParamsSchema,
} from "./schemas.js";
import {
  getTemplates,
  getTemplateCategories,
  getTemplateBySlug,
} from "../../services/templates.service.js";
import { notFound } from "../../lib/errors.js";

const templateRoutes: FastifyPluginAsyncTypebox = async (fastify) => {
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
      const { category, limit, offset } = request.query;
      return getTemplates(fastify.supabase, { category, limit, offset });
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
      return getTemplateCategories(fastify.supabase);
    },
  );

  fastify.get(
    "/:slug",
    {
      schema: {
        params: TemplateSlugParamsSchema,
        response: {
          200: TemplateSchema,
        },
      },
    },
    async (request, reply) => {
      const template = await getTemplateBySlug(fastify.supabase, request.params.slug);
      if (!template) {
        return notFound(reply, "Template not found");
      }
      return template;
    },
  );
};

export default templateRoutes;
