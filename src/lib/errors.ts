import { type FastifyReply } from "fastify";

export function notFound(reply: FastifyReply, message = "Not found") {
  return reply.code(404).send({ error: message });
}

export function forbidden(reply: FastifyReply, message = "Forbidden") {
  return reply.code(403).send({ error: message });
}

export function badRequest(reply: FastifyReply, message = "Bad request") {
  return reply.code(400).send({ error: message });
}

export function unauthorized(reply: FastifyReply, message = "Unauthorized") {
  return reply.code(401).send({ error: message });
}

export function conflict(reply: FastifyReply, message = "Conflict") {
  return reply.code(409).send({ error: message });
}
