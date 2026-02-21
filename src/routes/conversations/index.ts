import { type FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import { Type } from "@sinclair/typebox";
import {
  ConversationSchema,
  MessageSchema,
  ConversationIdParamsSchema,
  SendMessageBodySchema,
} from "./schemas.js";
import {
  getMyConversations,
  getConversationMessages,
  sendMessage,
  isConversationParticipant,
} from "../../services/conversations.service.js";
import { forbidden } from "../../lib/errors.js";

const conversationRoutes: FastifyPluginAsyncTypebox = async (fastify) => {
  fastify.addHook("preHandler", fastify.authenticate);

  fastify.get(
    "/",
    {
      schema: {
        response: {
          200: Type.Array(ConversationSchema),
        },
      },
    },
    async (request) => {
      return getMyConversations(fastify.supabase, request.userId);
    },
  );

  fastify.get(
    "/:id/messages",
    {
      schema: {
        params: ConversationIdParamsSchema,
        response: {
          200: Type.Array(MessageSchema),
        },
      },
    },
    async (request, reply) => {
      const isParticipant = await isConversationParticipant(
        fastify.supabase,
        request.params.id,
        request.userId,
      );
      if (!isParticipant) {
        return forbidden(reply);
      }
      return getConversationMessages(fastify.supabase, request.params.id);
    },
  );

  fastify.post(
    "/:id/messages",
    {
      schema: {
        params: ConversationIdParamsSchema,
        body: SendMessageBodySchema,
        response: {
          201: MessageSchema,
        },
      },
    },
    async (request, reply) => {
      const isParticipant = await isConversationParticipant(
        fastify.supabase,
        request.params.id,
        request.userId,
      );
      if (!isParticipant) {
        return forbidden(reply);
      }
      const message = await sendMessage(
        fastify.supabase,
        request.params.id,
        request.userId,
        request.body.content,
      );
      return reply.code(201).send(message);
    },
  );
};

export default conversationRoutes;
