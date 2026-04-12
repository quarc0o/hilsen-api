import { type FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import { Type } from "@sinclair/typebox";
import {
  CardSendSchema,
  SendCardBodySchema,
  SendCardParamsSchema,
  SendIdParamsSchema,
} from "./schemas.js";
import { sendCard, getMySends, getSendById } from "../../services/sends.service.js";
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
      if (!request.body.recipient_phone && !request.body.recipient_email) {
        return badRequest(reply, "Either recipient_phone or recipient_email is required");
      }

      const send = await sendCard(fastify.supabase, request.userId, request.params.id, {
        recipientPhone: request.body.recipient_phone,
        recipientEmail: request.body.recipient_email,
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

  // GET /sends/:id
  fastify.get(
    "/sends/:id",
    {
      preHandler: [fastify.authenticate],
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
      if (send.sender_id !== request.userId && send.recipient_id !== request.userId) {
        return forbidden(reply);
      }
      return send;
    },
  );
};

export default sendRoutes;
