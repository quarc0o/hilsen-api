import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { createTestApp } from "../helpers/setup.js";
import { type FastifyInstance } from "fastify";

describe("Template routes", () => {
  let app: FastifyInstance;

  beforeAll(async () => {
    app = await createTestApp();
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
  });

  describe("GET /templates", () => {
    it("should respond to the route", async () => {
      const response = await app.inject({
        method: "GET",
        url: "/templates",
      });

      // Route is registered and responds (500 expected without real Supabase)
      expect(response.statusCode).not.toBe(404);
    });
  });

  describe("GET /templates/categories", () => {
    it("should respond to the route", async () => {
      const response = await app.inject({
        method: "GET",
        url: "/templates/categories",
      });

      expect(response.statusCode).not.toBe(404);
    });
  });

  describe("GET /templates/:slug", () => {
    it("should respond to the route", async () => {
      const response = await app.inject({
        method: "GET",
        url: "/templates/non-existent-slug",
      });

      expect(response.statusCode).not.toBe(404);
    });
  });

  describe("GET /health", () => {
    it("should return 200 with status ok", async () => {
      const response = await app.inject({
        method: "GET",
        url: "/health",
      });

      expect(response.statusCode).toBe(200);
      expect(JSON.parse(response.body)).toEqual({ status: "ok" });
    });
  });
});
