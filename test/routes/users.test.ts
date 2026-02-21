import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { createTestApp, createTestToken } from "../helpers/setup.js";
import { type FastifyInstance } from "fastify";

describe("User routes", () => {
  let app: FastifyInstance;

  beforeAll(async () => {
    app = await createTestApp();
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
  });

  describe("GET /users/me", () => {
    it("should return 401 without a token", async () => {
      const response = await app.inject({
        method: "GET",
        url: "/users/me",
      });

      expect(response.statusCode).toBe(401);
    });

    it("should return 401 with an invalid token", async () => {
      const response = await app.inject({
        method: "GET",
        url: "/users/me",
        headers: {
          authorization: "Bearer invalid-token",
        },
      });

      expect(response.statusCode).toBe(401);
    });

    it("should accept a valid token format", async () => {
      const token = createTestToken({ sub: "test-supabase-id" });
      const response = await app.inject({
        method: "GET",
        url: "/users/me",
        headers: {
          authorization: `Bearer ${token}`,
        },
      });

      // Will be 401 (user not found in DB) since we don't have a real Supabase
      // but the JWT itself was accepted (not a JWT validation error)
      expect(response.statusCode).toBe(401);
      const body = JSON.parse(response.body);
      expect(body.error).toBe("User not found");
    });
  });

  describe("PATCH /users/me", () => {
    it("should return 401 without a token", async () => {
      const response = await app.inject({
        method: "PATCH",
        url: "/users/me",
        payload: { display_name: "Test" },
      });

      expect(response.statusCode).toBe(401);
    });
  });

  describe("DELETE /users/me", () => {
    it("should return 401 without a token", async () => {
      const response = await app.inject({
        method: "DELETE",
        url: "/users/me",
      });

      expect(response.statusCode).toBe(401);
    });
  });
});
