import { type FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import { Type } from "@sinclair/typebox";
import { TemplateSchema, TemplateIdParamsSchema } from "./schemas.js";
import { getTemplates, getTemplateById, createTemplate } from "../../services/templates.service.js";
import {
  uploadPlaceholderImage,
  uploadFileToDirectus,
  type FileUpload,
} from "../../services/placeholder-images.service.js";
import { notFound, badRequest } from "../../lib/errors.js";

const templateRoutes: FastifyPluginAsyncTypebox = async (fastify) => {
  const directusUrl = fastify.config.DIRECTUS_URL;

  // POST / — upload a new template (multipart: title, data JSON, placeholder image files)
  fastify.post(
    "/",
    {
      preHandler: [fastify.authenticate],
      schema: {
        consumes: ["multipart/form-data"],
        // body schema omitted — multipart bypasses Fastify's JSON body validator;
        // fields are parsed manually via request.parts()
        response: { 201: TemplateSchema },
      },
    },
    async (request, reply) => {
      const directusUrl = fastify.config.DIRECTUS_URL;
      const token = fastify.config.DIRECTUS_TOKEN;

      let rawData: string | undefined;
      let previewFile: FileUpload | undefined;
      const placeholderFiles: Record<string, FileUpload> = {};

      for await (const part of request.parts()) {
        if (part.type === "field") {
          if (part.fieldname === "data") rawData = part.value as string;
        } else {
          const file: FileUpload = {
            buffer: await part.toBuffer(),
            filename: part.filename ?? part.fieldname,
            mimetype: part.mimetype,
          };
          if (part.fieldname === "preview") {
            previewFile = file;
          } else if (part.fieldname.startsWith("placeholder_")) {
            // strip prefix so the key matches overlay placeholder_id values
            const uuid = part.fieldname.slice("placeholder_".length);
            placeholderFiles[uuid] = file;
          }
        }
      }

      if (!rawData) return badRequest(reply, "Missing field: data");
      if (!previewFile) return badRequest(reply, "Missing file: preview");

      let parsed: { name: string; data: Array<Record<string, unknown>> };
      try {
        parsed = JSON.parse(rawData);
      } catch {
        return badRequest(reply, "Field 'data' is not valid JSON");
      }
      if (!parsed.name) return badRequest(reply, "data.name is required");

      // Upload preview + all placeholder images in parallel
      const placeholderUuids = Object.keys(placeholderFiles);
      const [previewFileId, ...placeholderUploads] = await Promise.all([
        uploadFileToDirectus(directusUrl, token, previewFile),
        ...placeholderUuids.map((uuid) =>
          uploadPlaceholderImage(directusUrl, token, placeholderFiles[uuid]),
        ),
      ]);
      const placeholderMap = Object.fromEntries(
        placeholderUuids.map((uuid, i) => [uuid, placeholderUploads[i]]),
      );

      // Substitute placeholder_id → placeholder_image_id in each overlay item
      const resolvedItems = parsed.data.map((item) => {
        const pid = item.placeholder_id as string | undefined;
        if (!pid || !placeholderMap[pid]) return item;
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        const { placeholder_id, ...rest } = item;
        return { ...rest, placeholder_image_id: placeholderMap[pid].id };
      });

      const template = await createTemplate(
        directusUrl,
        token,
        parsed.name,
        resolvedItems,
        previewFileId,
      );
      return reply.code(201).send(template);
    },
  );

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
