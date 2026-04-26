import { type FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import { UserSchema, UpdateUserBodySchema } from "./schemas.js";
import {
  getUserById,
  updateUser,
  deleteUser,
  markAgeVerified,
  blockAndDeleteUser,
  MIN_AGE,
} from "../../services/users.service.js";
import { notFound, forbidden } from "../../lib/errors.js";
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
    async (request, reply) => {
      const { age, ...profileUpdates } = request.body;

      if (age !== undefined) {
        const currentUser = await getUserById(fastify.supabase, request.userId);
        if (!currentUser) return notFound(reply, "User not found");
        if (currentUser.age_verified_at) {
          return forbidden(reply, "age_already_verified");
        }

        if (age < MIN_AGE) {
          await blockAndDeleteUser({
            supabase: fastify.supabase,
            userId: request.userId,
            supabaseId: request.supabaseId,
            posthog: getPostHogConfig(fastify.config),
            reason: "underage",
            onWarning: (message, detail) => {
              fastify.log.warn(detail, message);
              request.captureException(new Error(message), {
                "delete.user_id": request.userId,
                "delete.cause": "underage",
              });
            },
          });
          return forbidden(reply, "age_ineligible");
        }

        await markAgeVerified(fastify.supabase, request.userId);
      }

      if (Object.keys(profileUpdates).length === 0) {
        return getUserById(fastify.supabase, request.userId);
      }

      return updateUser(fastify.supabase, request.userId, profileUpdates);
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
