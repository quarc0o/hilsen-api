import { type FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import { Type } from "@sinclair/typebox";
import { TemplateSchema, TemplateIdParamsSchema } from "./schemas.js";
import { getTemplates, getTemplateById } from "../../services/templates.service.js";
import { notFound } from "../../lib/errors.js";

const templateRoutes: FastifyPluginAsyncTypebox = async (fastify) => {
  const directusUrl = fastify.config.DIRECTUS_URL;

  fastify.get(
    "/",
    {
      schema: {
        response: {
          200: Type.Array(TemplateSchema),
        },
      },
    },
    async () => {
      return getTemplates(directusUrl);
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
