import { buildApp } from "./app.js";
import { startScheduledSendsWorker } from "./workers/scheduled-sends.js";

declare module "fastify" {
  interface FastifyInstance {
    flushScheduledSends: () => void;
  }
}

const start = async () => {
  try {
    const app = await buildApp();

    // Decorate before listen (Fastify requirement), assign real implementation after worker starts
    app.decorate("flushScheduledSends", () => {});

    await app.listen({
      port: app.config.PORT,
      host: app.config.HOST,
    });

    const worker = startScheduledSendsWorker(app.supabase, {
      twilio: {
        accountSid: app.config.TWILIO_ACCOUNT_SID,
        authToken: app.config.TWILIO_AUTH_TOKEN,
        senderId: app.config.TWILIO_SENDER_ID,
      },
      appBaseUrl: app.config.APP_BASE_URL,
    });

    app.flushScheduledSends = worker.flush;

    const shutdown = async (signal: string) => {
      console.log(`\n[server] ${signal} received, shutting down...`);
      worker.stop();
      await app.close();
      process.exit(0);
    };

    process.on("SIGINT", () => shutdown("SIGINT"));
    process.on("SIGTERM", () => shutdown("SIGTERM"));
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
};

start();
