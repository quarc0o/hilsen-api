import { type FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import { Type } from "@sinclair/typebox";
import {
  CardSendSchema,
  SendCardBodySchema,
  SendCardParamsSchema,
  SendIdParamsSchema,
  UpdateSendBodySchema,
} from "./schemas.js";
import {
  sendCard,
  getMySends,
  getSendById,
  updateScheduledSend,
  cancelSend,
} from "../../services/sends.service.js";
import { getCardById } from "../../services/cards.service.js";
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
          201: CardSendSchema,
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
      const send = await sendCard(fastify.supabase, request.userId, request.params.id, {
        recipientPhone: request.body.recipient_phone,
        scheduledAt: request.body.scheduled_at,
      });

      return reply.code(201).send(send);
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
      return send;
    },
  );
  // PATCH /sends/:id — update scheduled time
  fastify.patch(
    "/sends/:id",
    {
      preHandler: [fastify.authenticate],
      schema: {
        params: SendIdParamsSchema,
        body: UpdateSendBodySchema,
        response: {
          200: CardSendSchema,
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
      const result = await cancelSend(
        fastify.supabase,
        request.params.id,
        request.userId,
      );

      if (result.error === "not_found") return notFound(reply, "Send not found");
      if (result.error === "forbidden") return forbidden(reply);
      if (result.error === "already_sent") return badRequest(reply, "Send has already been sent");

      return reply.code(204).send();
    },
  );
};

export default sendRoutes;
