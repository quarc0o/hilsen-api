import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { createTestApp, createTestToken } from "../helpers/setup.js";
import { type FastifyInstance } from "fastify";

describe("Admin template routes", () => {
  let app: FastifyInstance;
  const token = createTestToken({ sub: "test-supabase-id" });
  const adminToken = createTestToken({ sub: "admin-supabase-id", role: "service_role" });

  beforeAll(async () => {
    app = await createTestApp();
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
  });

  describe("POST /admin/templates", () => {
    it("should return 401 without a token", async () => {
      const response = await app.inject({
        method: "POST",
        url: "/admin/templates",
        payload: {
          slug: "test",
          title: "Test",
          body_template: "Hello {name}",
          category: "general",
        },
      });

      expect(response.statusCode).toBe(401);
    });
  });

  describe("PATCH /admin/templates/:id", () => {
    it("should return 401 without a token", async () => {
      const response = await app.inject({
        method: "PATCH",
        url: "/admin/templates/00000000-0000-0000-0000-000000000000",
        payload: { title: "Updated" },
      });

      expect(response.statusCode).toBe(401);
    });
  });

  describe("DELETE /admin/templates/:id", () => {
    it("should return 401 without a token", async () => {
      const response = await app.inject({
        method: "DELETE",
        url: "/admin/templates/00000000-0000-0000-0000-000000000000",
      });

      expect(response.statusCode).toBe(401);
    });
  });
});
