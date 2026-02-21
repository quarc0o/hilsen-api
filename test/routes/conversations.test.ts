import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { createTestApp, createTestToken } from "../helpers/setup.js";
import { type FastifyInstance } from "fastify";

describe("Conversation routes", () => {
  let app: FastifyInstance;
  const token = createTestToken({ sub: "test-supabase-id" });

  beforeAll(async () => {
    app = await createTestApp();
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
  });

  describe("GET /conversations", () => {
    it("should return 401 without a token", async () => {
      const response = await app.inject({
        method: "GET",
        url: "/conversations",
      });

      expect(response.statusCode).toBe(401);
    });
  });

  describe("GET /conversations/:id/messages", () => {
    it("should return 401 without a token", async () => {
      const response = await app.inject({
        method: "GET",
        url: "/conversations/00000000-0000-0000-0000-000000000000/messages",
      });

      expect(response.statusCode).toBe(401);
    });
  });

  describe("POST /conversations/:id/messages", () => {
    it("should return 401 without a token", async () => {
      const response = await app.inject({
        method: "POST",
        url: "/conversations/00000000-0000-0000-0000-000000000000/messages",
        payload: { content: "Hello!" },
      });

      expect(response.statusCode).toBe(401);
    });
  });
});
