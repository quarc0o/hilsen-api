import { type FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import { Type } from "@sinclair/typebox";
import { TemplateSchema, TemplateIdParamsSchema } from "./schemas.js";
import { getTemplates, getTemplateById, createTemplate } from "../../services/templates.service.js";
import {
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
      // placeholder files are keyed by overlay UUID (stripped from "placeholder_<uuid>")
      const placeholderUuids = Object.keys(placeholderFiles);
      const [previewFileId, ...placeholderFileIds] = await Promise.all([
        uploadFileToDirectus(directusUrl, token, previewFile),
        ...placeholderUuids.map((uuid) =>
          uploadFileToDirectus(directusUrl, token, placeholderFiles[uuid]),
        ),
      ]);

      // map overlay uuid → full Directus asset URL
      const placeholderUrlMap = Object.fromEntries(
        placeholderUuids.map((uuid, i) => [uuid, `${directusUrl}/assets/${placeholderFileIds[i]}`]),
      );

      // Inject placeholderImageUrl into matching overlay items (matched by item.uuid)
      const resolvedItems = parsed.data.map((item) => {
        const uuid = item.uuid as string | undefined;
        if (!uuid || !placeholderUrlMap[uuid]) return item;
        return { ...item, placeholderImageUrl: placeholderUrlMap[uuid] };
      });

      // Use the first placeholder file ID for the Card_Templates.Placeholder_Image field
      const placeholderFileId = placeholderFileIds[0] ?? null;

      const template = await createTemplate(
        directusUrl,
        token,
        parsed.name,
        resolvedItems,
        previewFileId,
        placeholderFileId,
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
