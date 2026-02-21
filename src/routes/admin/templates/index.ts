import { type FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import {
  TemplateSchema,
  CreateTemplateBodySchema,
  UpdateTemplateBodySchema,
  TemplateIdParamsSchema,
} from "./schemas.js";
import {
  createTemplate,
  updateTemplate,
  deleteTemplate,
} from "../../../services/templates.service.js";
import { notFound } from "../../../lib/errors.js";
import { requireAdmin } from "../../../lib/types.js";

const adminTemplateRoutes: FastifyPluginAsyncTypebox = async (fastify) => {
  fastify.addHook("preHandler", fastify.authenticate);
  fastify.addHook("preHandler", requireAdmin);

  fastify.post(
    "/",
    {
      schema: {
        body: CreateTemplateBodySchema,
        response: {
          201: TemplateSchema,
        },
      },
    },
    async (request, reply) => {
      const template = await createTemplate(fastify.supabase, request.body);
      return reply.code(201).send(template);
    },
  );

  fastify.patch(
    "/:id",
    {
      schema: {
        params: TemplateIdParamsSchema,
        body: UpdateTemplateBodySchema,
        response: {
          200: TemplateSchema,
        },
      },
    },
    async (request, reply) => {
      const template = await updateTemplate(fastify.supabase, request.params.id, request.body);
      if (!template) {
        return notFound(reply, "Template not found");
      }
      return template;
    },
  );

  fastify.delete(
    "/:id",
    {
      schema: {
        params: TemplateIdParamsSchema,
      },
    },
    async (request, reply) => {
      await deleteTemplate(fastify.supabase, request.params.id);
      return reply.code(204).send();
    },
  );
};

export default adminTemplateRoutes;
