import { buildApp } from "../../src/app.js";
import jwt from "jsonwebtoken";

const TEST_JWT_SECRET = "test-jwt-secret-for-testing-only";

const TEST_ENV: Record<string, string> = {
  PORT: "0",
  HOST: "127.0.0.1",
  LOG_LEVEL: "silent",
  SUPABASE_URL: "http://localhost:54321",
  SUPABASE_SERVICE_ROLE_KEY: "test-service-role-key",
  SUPABASE_JWT_SECRET: TEST_JWT_SECRET,
  TWILIO_ACCOUNT_SID: "AC-test-account-sid",
  TWILIO_AUTH_TOKEN: "test-auth-token",
  TWILIO_SENDER_ID: "Hilsen",
  APP_BASE_URL: "http://localhost:3001",
  DIRECTUS_URL: "https://directus.quarcoo.no",
};

export async function createTestApp(envOverrides?: Record<string, string>) {
  const app = await buildApp({ ...TEST_ENV, ...envOverrides });
  return app;
}

export function createTestToken(payload: { sub: string; role?: string; aud?: string }) {
  return jwt.sign(
    {
      sub: payload.sub,
      role: payload.role ?? "authenticated",
      aud: payload.aud ?? "authenticated",
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 3600,
    },
    TEST_JWT_SECRET,
  );
}
