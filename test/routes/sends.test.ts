import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { createTestApp, createTestToken } from "../helpers/setup.js";
import { type FastifyInstance } from "fastify";

describe("Send routes", () => {
  let app: FastifyInstance;
  const token = createTestToken({ sub: "test-supabase-id" });

  beforeAll(async () => {
    app = await createTestApp();
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
  });

  describe("POST /cards/:id/send", () => {
    it("should return 401 without a token", async () => {
      const response = await app.inject({
        method: "POST",
        url: "/cards/00000000-0000-0000-0000-000000000000/send",
        payload: { recipient_phones: ["+1234567890"] },
      });

      expect(response.statusCode).toBe(401);
    });
  });

  describe("GET /sends/mine", () => {
    it("should return 401 without a token", async () => {
      const response = await app.inject({
        method: "GET",
        url: "/sends/mine",
      });

      expect(response.statusCode).toBe(401);
    });
  });

  describe("GET /sends/:id", () => {
    it("should return 401 without a token", async () => {
      const response = await app.inject({
        method: "GET",
        url: "/sends/00000000-0000-0000-0000-000000000000",
      });

      expect(response.statusCode).toBe(401);
    });
  });
});
