import { type FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import { UserSchema, UpdateUserBodySchema } from "./schemas.js";
import { getUserById, updateUser, deleteUser } from "../../services/users.service.js";
import { notFound } from "../../lib/errors.js";
import { getPostHogConfig } from "../../lib/posthog.js";

const userRoutes: FastifyPluginAsyncTypebox = async (fastify) => {
  fastify.get(
    "/me",
    {
      preHandler: [fastify.authenticate],
      schema: {
        response: {
          200: UserSchema,
        },
      },
    },
    async (request, reply) => {
      const user = await getUserById(fastify.supabase, request.userId);
      if (!user) {
        return notFound(reply, "User not found");
      }
      return user;
    },
  );

  fastify.patch(
    "/me",
    {
      preHandler: [fastify.authenticate],
      schema: {
        body: UpdateUserBodySchema,
        response: {
          200: UserSchema,
        },
      },
    },
    async (request) => {
      return updateUser(fastify.supabase, request.userId, request.body);
    },
  );

  fastify.delete(
    "/me",
    {
      preHandler: [fastify.authenticate],
    },
    async (request, reply) => {
      await deleteUser({
        supabase: fastify.supabase,
        userId: request.userId,
        supabaseId: request.supabaseId,
        posthog: getPostHogConfig(fastify.config),
        onWarning: (message, detail) => {
          fastify.log.warn(detail, message);
          request.captureException(new Error(message), {
            "delete.user_id": request.userId,
          });
        },
      });
      return reply.code(204).send();
    },
  );
};

export default userRoutes;
