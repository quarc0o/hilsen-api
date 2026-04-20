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

      expect(response.statusCode).not.toBe(404);
    });
  });

  describe("GET /templates/:id", () => {
    it("should respond to the route", async () => {
      const response = await app.inject({
        method: "GET",
        url: "/templates/non-existent-id",
      });

      expect(response.statusCode).not.toBe(404);
    });
  });
});
