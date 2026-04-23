import { type FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import rateLimit from "@fastify/rate-limit";
import { CreateOptOutBodySchema, OptOutResponseSchema } from "./schemas.js";
import { addOptOut } from "../../services/opt-outs.service.js";

const optOutRoutes: FastifyPluginAsyncTypebox = async (fastify) => {
  await fastify.register(rateLimit, {
    global: false,
    keyGenerator: (req) => req.ip,
  });

  // POST /opt-outs — public, unauthenticated. Anyone can submit a phone
  // number to stop future Hilsen SMS to that number. No verification by
  // design: GDPR favors making opt-out frictionless, even at the cost
  // of a malicious actor opting someone else out. Worst case is that a
  // recipient stops receiving cards — they can un-block via support.
  fastify.post(
    "/opt-outs",
    {
      config: {
        rateLimit: {
          max: 10,
          timeWindow: "1 minute",
        },
      },
      schema: {
        body: CreateOptOutBodySchema,
        response: {
          201: OptOutResponseSchema,
        },
      },
    },
    async (request, reply) => {
      const result = await addOptOut(fastify.supabase, request.body.phone_number, "form");
      return reply.code(201).send(result);
    },
  );
};

export default optOutRoutes;
