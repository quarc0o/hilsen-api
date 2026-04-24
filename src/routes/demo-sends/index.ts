import { type FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import rateLimit from "@fastify/rate-limit";
import {
  CreateDemoSendBodySchema,
  DemoSendResponseSchema,
  DemoSendErrorSchema,
} from "./schemas.js";
import { sendDemoCard } from "../../services/demo-sends.service.js";

const demoSendRoutes: FastifyPluginAsyncTypebox = async (fastify) => {
  await fastify.register(rateLimit, {
    global: false,
    keyGenerator: (req) => req.ip,
  });

  // POST /demo-sends — public, unauthenticated. Landing-page form: visitor
  // enters their phone number and gets a single example card. Defenses:
  //   - Lifetime 1 per phone (PK on demo_send_recipients)
  //   - Global daily cap (DEMO_DAILY_CAP) to bound Twilio spend
  //   - Per-IP rate limit below (3/hour)
  //   - Opt-out list respected (sms_opt_outs)
  //   - No sender identity shown — SMS is clearly branded as a Hilsen demo
  fastify.post(
    "/demo-sends",
    {
      config: {
        rateLimit: {
          max: 3,
          timeWindow: "1 hour",
        },
      },
      schema: {
        body: CreateDemoSendBodySchema,
        response: {
          201: DemoSendResponseSchema,
          400: DemoSendErrorSchema,
          409: DemoSendErrorSchema,
          503: DemoSendErrorSchema,
        },
      },
    },
    async (request, reply) => {
      const result = await sendDemoCard(fastify.supabase, request.body.phone_number, {
        twilio: {
          accountSid: fastify.config.TWILIO_ACCOUNT_SID,
          authToken: fastify.config.TWILIO_AUTH_TOKEN,
          senderId: fastify.config.TWILIO_SENDER_ID,
        },
        appBaseUrl: fastify.config.APP_BASE_URL,
        demoUserId: fastify.config.DEMO_USER_ID,
        demoCardId: fastify.config.DEMO_CARD_ID,
        demoDailyCap: fastify.config.DEMO_DAILY_CAP,
      });

      if ("ok" in result) {
        return reply.code(201).send(result);
      }

      if (result.error === "opted_out") {
        return reply.code(400).send({
          error: "Dette nummeret har reservert seg fra å motta SMS fra Hilsen.",
        });
      }
      if (result.error === "already_sent") {
        return reply.code(409).send({
          error: "Dette nummeret har allerede mottatt en eksempel-hilsen.",
        });
      }
      if (result.error === "daily_cap_reached") {
        return reply.code(503).send({
          error: "Vi har nådd dagens grense for eksempel-hilsener. Prøv igjen i morgen.",
        });
      }
      // sms_failed — treat as 400 so the client can prompt the user to check the number.
      return reply.code(400).send({
        error: "Kunne ikke sende SMS til dette nummeret. Sjekk at nummeret er riktig.",
      });
    },
  );
};

export default demoSendRoutes;
