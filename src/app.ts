import Fastify from "fastify";
import { TypeBoxTypeProvider } from "@fastify/type-provider-typebox";
import fastifyEnv from "@fastify/env";
import fastifyCors from "@fastify/cors";
import fastifyMultipart from "@fastify/multipart";
import fastifySwagger from "@fastify/swagger";
import fastifySwaggerUi from "@fastify/swagger-ui";
import { buildEnvOptions } from "./config/env.js";
import sentryPlugin from "./plugins/sentry.js";
import supabasePlugin from "./plugins/supabase.js";
import authPlugin from "./plugins/auth.js";
import designRoutes from "./routes/designs/index.js";
import templateRoutes from "./routes/templates/index.js";
import placeholderImageRoutes from "./routes/placeholder-images/index.js";
import userRoutes from "./routes/users/index.js";
import cardRoutes from "./routes/cards/index.js";
import sendRoutes from "./routes/sends/index.js";
import stickerRoutes from "./routes/stickers/index.js";
import optOutRoutes from "./routes/opt-outs/index.js";

export async function buildApp(envOverrides?: Record<string, string>) {
  const app = Fastify({
    logger: {
      level: process.env.LOG_LEVEL ?? "info",
    },
  }).withTypeProvider<TypeBoxTypeProvider>();

  // Allow empty body on DELETE requests (Content-Type: application/json with no body)
  app.addContentTypeParser("application/json", { parseAs: "string" }, (req, body, done) => {
    if (typeof body === "string" && body.length === 0) {
      done(null, undefined);
    } else {
      try {
        done(null, JSON.parse(body as string));
      } catch (err) {
        done(err as Error, undefined);
      }
    }
  });

  // Config
  await app.register(fastifyEnv, buildEnvOptions(envOverrides));

  // Error tracking (must come right after config so all later hooks are covered)
  await app.register(sentryPlugin);

  // Swagger
  await app.register(fastifySwagger, {
    openapi: {
      info: {
        title: "Hilsen API",
        version: "1.0.0",
      },
      components: {
        securitySchemes: {
          bearerAuth: {
            type: "http",
            scheme: "bearer",
            bearerFormat: "JWT",
          },
        },
      },
    },
  });
  await app.register(fastifySwaggerUi, {
    routePrefix: "/docs",
  });

  // CORS
  await app.register(fastifyCors);

  // Multipart (for template uploads)
  await app.register(fastifyMultipart, {
    limits: { fileSize: 10 * 1024 * 1024 }, // 10MB per file
  });

  // Plugins
  await app.register(supabasePlugin);
  await app.register(authPlugin);

  // Health check
  app.get("/health", async () => {
    return { status: "ok" };
  });

  // Routes
  await app.register(designRoutes, { prefix: "/designs" });
  await app.register(templateRoutes, { prefix: "/templates" });
  await app.register(placeholderImageRoutes, { prefix: "/placeholder-images" });
  await app.register(userRoutes, { prefix: "/users" });
  await app.register(cardRoutes, { prefix: "/cards" });
  await app.register(sendRoutes);
  await app.register(stickerRoutes, { prefix: "/stickers" });
  await app.register(optOutRoutes);

  return app;
}
