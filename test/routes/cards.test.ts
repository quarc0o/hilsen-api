import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { createTestApp, createTestToken } from "../helpers/setup.js";
import { type FastifyInstance } from "fastify";

describe("Card routes", () => {
  let app: FastifyInstance;
  const token = createTestToken({ sub: "test-supabase-id" });

  beforeAll(async () => {
    app = await createTestApp();
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
  });

  describe("POST /cards", () => {
    it("should return 401 without a token", async () => {
      const response = await app.inject({
        method: "POST",
        url: "/cards",
        payload: { design_id: "00000000-0000-0000-0000-000000000000" },
      });

      expect(response.statusCode).toBe(401);
    });
  });

  describe("GET /cards/mine", () => {
    it("should return 401 without a token", async () => {
      const response = await app.inject({
        method: "GET",
        url: "/cards/mine",
      });

      expect(response.statusCode).toBe(401);
    });
  });

  describe("GET /cards/:id", () => {
    it("should return 401 without a token", async () => {
      const response = await app.inject({
        method: "GET",
        url: "/cards/00000000-0000-0000-0000-000000000000",
      });

      expect(response.statusCode).toBe(401);
    });
  });

  describe("PATCH /cards/:id", () => {
    it("should return 401 without a token", async () => {
      const response = await app.inject({
        method: "PATCH",
        url: "/cards/00000000-0000-0000-0000-000000000000",
        payload: { body: "Updated" },
      });

      expect(response.statusCode).toBe(401);
    });
  });

  describe("DELETE /cards/:id", () => {
    it("should return 401 without a token", async () => {
      const response = await app.inject({
        method: "DELETE",
        url: "/cards/00000000-0000-0000-0000-000000000000",
      });

      expect(response.statusCode).toBe(401);
    });
  });
});
