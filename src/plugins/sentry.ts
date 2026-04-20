import fp from "fastify-plugin";
import * as Sentry from "@sentry/node";
import { randomUUID } from "node:crypto";
import { createRequire } from "node:module";
import type { FastifyError, FastifyInstance, FastifyRequest } from "fastify";
import { initSentry, isSentryEnabled } from "../lib/sentry.js";

const require = createRequire(import.meta.url);
const pkg = require("../../package.json") as { version: string };

declare module "fastify" {
  interface FastifyRequest {
    requestId: string;
    captureException: (err: unknown, tags?: Record<string, string | number | undefined>) => void;
  }
}

export default fp(
  async function sentryPlugin(fastify: FastifyInstance) {
    const enabled = initSentry({
      dsn: fastify.config.SENTRY_DSN,
      environment: fastify.config.SENTRY_ENVIRONMENT,
      release: buildRelease(fastify.config.GIT_SHA),
    });

    fastify.decorateRequest("requestId", "");

    fastify.addHook("onRequest", async (request, reply) => {
      const incoming = request.headers["x-request-id"];
      const requestId =
        typeof incoming === "string" && incoming.length > 0 ? incoming : randomUUID();
      request.requestId = requestId;
      reply.header("x-request-id", requestId);
    });

    if (!enabled) {
      fastify.decorateRequest("captureException", noop);
      fastify.log.info("Sentry disabled (no DSN configured)");
      return;
    }

    fastify.log.info({ environment: fastify.config.SENTRY_ENVIRONMENT }, "Sentry initialized");

    fastify.decorateRequest(
      "captureException",
      function (
        this: FastifyRequest,
        err: unknown,
        tags: Record<string, string | number | undefined> = {},
      ) {
        captureWithRequestScope(this, err, tags);
      },
    );

    fastify.setErrorHandler((err: FastifyError, request, reply) => {
      const statusCode = err.statusCode ?? 500;
      if (statusCode >= 500) {
        captureWithRequestScope(request, err);
      }
      reply.send(err);
    });
  },
  { name: "sentry", dependencies: ["@fastify/env"] },
);

function captureWithRequestScope(
  request: FastifyRequest,
  err: unknown,
  tags: Record<string, string | number | undefined> = {},
): void {
  Sentry.withScope((scope) => {
    scope.setTag("request_id", request.requestId);
    scope.setTag("route", request.routeOptions?.url ?? "unknown");
    if (request.userId) scope.setUser({ id: request.userId });
    for (const [key, value] of Object.entries(tags)) {
      if (value !== undefined) scope.setTag(key, String(value));
    }
    Sentry.captureException(err);
  });
}

function buildRelease(gitSha: string | undefined): string {
  const sha = gitSha ? gitSha.slice(0, 7) : undefined;
  return sha ? `hilsen-api@${pkg.version}+${sha}` : `hilsen-api@${pkg.version}`;
}

function noop(): void {}

export { isSentryEnabled };
