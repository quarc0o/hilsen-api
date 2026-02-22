import Fastify from "fastify";
import { TypeBoxTypeProvider } from "@fastify/type-provider-typebox";
import fastifyEnv from "@fastify/env";
import fastifyCors from "@fastify/cors";
import fastifySwagger from "@fastify/swagger";
import fastifySwaggerUi from "@fastify/swagger-ui";
import { buildEnvOptions } from "./config/env.js";
import supabasePlugin from "./plugins/supabase.js";
import authPlugin from "./plugins/auth.js";
import templateRoutes from "./routes/templates/index.js";
import userRoutes from "./routes/users/index.js";
import cardRoutes from "./routes/cards/index.js";
import sendRoutes from "./routes/sends/index.js";
import conversationRoutes from "./routes/conversations/index.js";
import adminTemplateRoutes from "./routes/admin/templates/index.js";

export async function buildApp(envOverrides?: Record<string, string>) {
  const app = Fastify({
    logger: {
      level: process.env.LOG_LEVEL ?? "info",
    },
  }).withTypeProvider<TypeBoxTypeProvider>();

  // Config
  await app.register(fastifyEnv, buildEnvOptions(envOverrides));

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

  // Plugins
  await app.register(supabasePlugin);
  await app.register(authPlugin);

  // Health check
  app.get("/health", async () => {
    return { status: "ok" };
  });

  // Routes
  await app.register(templateRoutes, { prefix: "/templates" });
  await app.register(userRoutes, { prefix: "/users" });
  await app.register(cardRoutes, { prefix: "/cards" });
  await app.register(sendRoutes);
  await app.register(conversationRoutes, { prefix: "/conversations" });
  await app.register(adminTemplateRoutes, { prefix: "/admin/templates" });

  return app;
}
