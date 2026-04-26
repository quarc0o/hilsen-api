import { type FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import rateLimit from "@fastify/rate-limit";
import { CreateReportBodySchema, ReportResponseSchema } from "./schemas.js";
import { createCardReport } from "../../services/reports.service.js";
import { notFound } from "../../lib/errors.js";

const reportRoutes: FastifyPluginAsyncTypebox = async (fastify) => {
  await fastify.register(rateLimit, {
    global: false,
    keyGenerator: (req) => req.ip,
  });

  // POST /reports — public, unauthenticated. Required by Apple
  // Guideline 1.2 (UGC apps must offer a way to flag content).
  // Recipients usually receive cards via SMS short link without an
  // account, so this endpoint can't require auth.
  //
  // Rate-limited per IP to keep the moderation queue sane; we'd
  // rather drop a few legitimate reports than have a single actor
  // flood the queue.
  fastify.post(
    "/reports",
    {
      config: {
        rateLimit: {
          max: 5,
          timeWindow: "1 hour",
        },
      },
      schema: {
        body: CreateReportBodySchema,
        response: {
          201: ReportResponseSchema,
        },
      },
    },
    async (request, reply) => {
      // Optional auth: capture reporter_id when a valid Bearer token is
      // present so the reporter's own inbox can hide the card. Anonymous
      // reports (from the public short-link page) still work without a
      // token, just without the inbox-hide side effect.
      let reporterId: string | null = null;
      const authHeader = request.headers.authorization;
      if (authHeader?.startsWith("Bearer ")) {
        try {
          await request.jwtVerify();
          const supabaseId = request.user.sub;
          const { data: user } = await fastify.supabase
            .from("users")
            .select("id")
            .eq("supabase_id", supabaseId)
            .maybeSingle();
          if (user) reporterId = user.id;
        } catch {
          // Invalid/expired token — fall through and treat as anonymous.
        }
      }

      const result = await createCardReport(fastify.supabase, {
        sendId: request.body.send_id,
        reason: request.body.reason,
        reporterId,
      });
      if (!result.ok) {
        return notFound(reply, "Send not found");
      }
      return reply.code(201).send({ id: result.id });
    },
  );
};

export default reportRoutes;
