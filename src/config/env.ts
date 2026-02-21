// eslint-disable-next-line @typescript-eslint/no-unused-vars
import { type FastifyInstance } from "fastify";

export interface EnvConfig {
  PORT: number;
  HOST: string;
  LOG_LEVEL: string;
  SUPABASE_URL: string;
  SUPABASE_SERVICE_ROLE_KEY: string;
  SUPABASE_JWT_SECRET: string;
}

declare module "fastify" {
  interface FastifyInstance {
    config: EnvConfig;
  }
}

export const envSchema = {
  type: "object" as const,
  required: ["SUPABASE_URL", "SUPABASE_SERVICE_ROLE_KEY", "SUPABASE_JWT_SECRET"],
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
