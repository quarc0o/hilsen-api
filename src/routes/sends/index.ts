import { type FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import { Type } from "@sinclair/typebox";
import {
  CardSendSchema,
  SendCardBodySchema,
  SendCardParamsSchema,
  SendIdParamsSchema,
  SendGroupIdParamsSchema,
  UpdateSendBodySchema,
  UpdateSendGroupBodySchema,
} from "./schemas.js";
import {
  sendCard,
  getMySends,
  getReceivedSends,
  getSendById,
  updateScheduledSend,
  cancelSend,
  updateSendGroup,
  cancelSendGroup,
} from "../../services/sends.service.js";
import { getCardById } from "../../services/cards.service.js";
import { getDesignById } from "../../services/designs.service.js";
import { notFound, forbidden, badRequest } from "../../lib/errors.js";

const sendRoutes: FastifyPluginAsyncTypebox = async (fastify) => {
  // POST /cards/:id/send
  fastify.post(
    "/cards/:id/send",
    {
      preHandler: [fastify.authenticate],
      schema: {
        params: SendCardParamsSchema,
        body: SendCardBodySchema,
        response: {
          201: Type.Array(CardSendSchema),
        },
      },
    },
    async (request, reply) => {
      const card = await getCardById(fastify.supabase, request.params.id);
      if (!card) {
        return notFound(reply, "Card not found");
      }
      if (card.creator_id !== request.userId) {
        return forbidden(reply);
      }
      const sends = await sendCard(fastify.supabase, request.userId, request.params.id, {
        recipientPhones: request.body.recipient_phones,
        scheduledAt: request.body.scheduled_at,
      });

      if (!request.body.scheduled_at) {
        fastify.flushScheduledSends();
      }

      return reply.code(201).send(sends);
    },
  );

  // GET /sends/mine
  fastify.get(
    "/sends/mine",
    {
      preHandler: [fastify.authenticate],
      schema: {
        response: {
          200: Type.Array(CardSendSchema),
        },
      },
    },
    async (request) => {
      return getMySends(fastify.supabase, request.userId);
    },
  );

  // GET /sends/received
  fastify.get(
    "/sends/received",
    {
      preHandler: [fastify.authenticate],
      schema: {
        response: {
          200: Type.Array(CardSendSchema),
        },
      },
    },
    async (request) => {
      return getReceivedSends(fastify.supabase, request.userId);
    },
  );

  // GET /sends/:id (public — no auth required)
  fastify.get(
    "/sends/:id",
    {
      schema: {
        params: SendIdParamsSchema,
        response: {
          200: CardSendSchema,
        },
      },
    },
    async (request, reply) => {
      const send = await getSendById(fastify.supabase, request.params.id);
      if (!send) {
        return notFound(reply, "Send not found");
      }

      const backsidePath = `${send.sender_id}/${send.card_id}.png`;
      const [{ data: urlData, error: storageError }, design] = await Promise.all([
        fastify.supabase.storage.from("card-images").createSignedUrl(backsidePath, 3600),
        send.card_design_id
          ? getDesignById(fastify.config.DIRECTUS_URL, send.card_design_id)
          : Promise.resolve(null),
      ]);

      if (storageError) {
        fastify.log.warn({ backsidePath, storageError }, "Failed to create signed URL for backside");
      }

      return {
        ...send,
        card_backside_url: urlData?.signedUrl ?? null,
        card_design_image_url: design?.image_url ?? null,
      };
    },
  );
  // PATCH /sends/:id — update a scheduled send (or expand into a group with recipient_phones)
  fastify.patch(
    "/sends/:id",
    {
      preHandler: [fastify.authenticate],
      schema: {
        params: SendIdParamsSchema,
        body: UpdateSendBodySchema,
        response: {
          200: Type.Union([CardSendSchema, Type.Array(CardSendSchema)]),
        },
      },
    },
    async (request, reply) => {
      const result = await updateScheduledSend(
        fastify.supabase,
        request.params.id,
        request.userId,
        {
          scheduledAt: request.body.scheduled_at,
          recipientPhone: request.body.recipient_phone,
          recipientPhones: request.body.recipient_phones,
        },
      );

      if (result.error === "not_found") return notFound(reply, "Send not found");
      if (result.error === "forbidden") return forbidden(reply);
      if (result.error === "already_sent") return badRequest(reply, "Send has already been sent");

      return result.data;
    },
  );

  // DELETE /sends/:id — cancel a scheduled send
  fastify.delete(
    "/sends/:id",
    {
      preHandler: [fastify.authenticate],
      schema: {
        params: SendIdParamsSchema,
      },
    },
    async (request, reply) => {
      const result = await cancelSend(fastify.supabase, request.params.id, request.userId);

      if (result.error === "not_found") return notFound(reply, "Send not found");
      if (result.error === "forbidden") return forbidden(reply);
      if (result.error === "already_sent") return badRequest(reply, "Send has already been sent");

      return reply.code(204).send();
    },
  );

  // PATCH /send-groups/:groupId — reschedule all scheduled sends in a group
  fastify.patch(
    "/send-groups/:groupId",
    {
      preHandler: [fastify.authenticate],
      schema: {
        params: SendGroupIdParamsSchema,
        body: UpdateSendGroupBodySchema,
        response: {
          200: Type.Array(CardSendSchema),
        },
      },
    },
    async (request, reply) => {
      const result = await updateSendGroup(
        fastify.supabase,
        request.params.groupId,
        request.userId,
        {
          scheduledAt: request.body.scheduled_at,
          recipientPhones: request.body.recipient_phones,
        },
      );

      if (result.error === "not_found") return notFound(reply, "Send group not found");

      return result.data;
    },
  );

  // DELETE /send-groups/:groupId — cancel all scheduled sends in a group
  fastify.delete(
    "/send-groups/:groupId",
    {
      preHandler: [fastify.authenticate],
      schema: {
        params: SendGroupIdParamsSchema,
      },
    },
    async (request, reply) => {
      const result = await cancelSendGroup(
        fastify.supabase,
        request.params.groupId,
        request.userId,
      );

      if (result.error === "not_found") return notFound(reply, "Send group not found");

      return reply.code(204).send();
    },
  );
};

export default sendRoutes;
