import { type FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import { Type } from "@sinclair/typebox";
import {
  CardSchema,
  CreateCardBodySchema,
  UpdateCardBodySchema,
  CardIdParamsSchema,
} from "./schemas.js";
import {
  createCard,
  getCardById,
  getMyCards,
  updateCard,
  deleteCard,
} from "../../services/cards.service.js";
import { notFound, forbidden } from "../../lib/errors.js";

const cardRoutes: FastifyPluginAsyncTypebox = async (fastify) => {
  fastify.addHook("preHandler", fastify.authenticate);

  fastify.post(
    "/",
    {
      schema: {
        body: CreateCardBodySchema,
        response: {
          201: CardSchema,
        },
      },
    },
    async (request, reply) => {
      const card = await createCard(fastify.supabase, request.userId, request.body);
      return reply.code(201).send(card);
    },
  );

  fastify.get(
    "/mine",
    {
      schema: {
        response: {
          200: Type.Array(CardSchema),
        },
      },
    },
    async (request) => {
      return getMyCards(fastify.supabase, request.userId);
    },
  );

  fastify.get(
    "/:id",
    {
      schema: {
        params: CardIdParamsSchema,
        response: {
          200: CardSchema,
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
      return card;
    },
  );

  fastify.patch(
    "/:id",
    {
      schema: {
        params: CardIdParamsSchema,
        body: UpdateCardBodySchema,
        response: {
          200: CardSchema,
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
      return updateCard(fastify.supabase, request.params.id, request.body);
    },
  );

  fastify.delete(
    "/:id",
    {
      schema: {
        params: CardIdParamsSchema,
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
      await deleteCard(fastify.supabase, request.params.id);
      return reply.code(204).send();
    },
  );
};

export default cardRoutes;
