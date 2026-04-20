// eslint-disable-next-line @typescript-eslint/no-unused-vars
import { type FastifyInstance } from "fastify";

export interface EnvConfig {
  PORT: number;
  HOST: string;
  LOG_LEVEL: string;
  SUPABASE_URL: string;
  SUPABASE_SERVICE_ROLE_KEY: string;
  SUPABASE_JWT_SECRET: string;
  TWILIO_ACCOUNT_SID: string;
  TWILIO_AUTH_TOKEN: string;
  TWILIO_SENDER_ID: string;
  APP_BASE_URL: string;
  DIRECTUS_URL: string;
  DIRECTUS_TOKEN: string;
  SENTRY_DSN?: string;
  SENTRY_ENVIRONMENT?: string;
  GIT_SHA?: string;
}

declare module "fastify" {
  interface FastifyInstance {
    config: EnvConfig;
  }
}

export const envSchema = {
  type: "object" as const,
  required: [
    "SUPABASE_URL",
    "SUPABASE_SERVICE_ROLE_KEY",
    "SUPABASE_JWT_SECRET",
    "TWILIO_ACCOUNT_SID",
    "TWILIO_AUTH_TOKEN",
    "TWILIO_SENDER_ID",
    "APP_BASE_URL",
    "DIRECTUS_URL",
    "DIRECTUS_TOKEN",
  ],
  properties: {
    PORT: {
      type: "number" as const,
      default: 3001,
    },
    HOST: {
      type: "string" as const,
      default: "0.0.0.0",
    },
    LOG_LEVEL: {
      type: "string" as const,
      default: "info",
    },
    SUPABASE_URL: {
      type: "string" as const,
    },
    SUPABASE_SERVICE_ROLE_KEY: {
      type: "string" as const,
    },
    SUPABASE_JWT_SECRET: {
      type: "string" as const,
    },
    TWILIO_ACCOUNT_SID: {
      type: "string" as const,
    },
    TWILIO_AUTH_TOKEN: {
      type: "string" as const,
    },
    TWILIO_SENDER_ID: {
      type: "string" as const,
    },
    APP_BASE_URL: {
      type: "string" as const,
    },
    DIRECTUS_URL: {
      type: "string" as const,
    },
    DIRECTUS_TOKEN: {
      type: "string" as const,
    },
    SENTRY_DSN: {
      type: "string" as const,
    },
    SENTRY_ENVIRONMENT: {
      type: "string" as const,
    },
    GIT_SHA: {
      type: "string" as const,
    },
  },
};

export const envOptions = {
  confKey: "config",
  schema: envSchema,
  dotenv: true,
  data: undefined as Record<string, string> | undefined,
};

export function buildEnvOptions(overrides?: Record<string, string>) {
  return {
    ...envOptions,
    ...(overrides ? { data: overrides } : {}),
  };
}
