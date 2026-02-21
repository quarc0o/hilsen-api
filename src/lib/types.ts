import { type FastifyRequest, type FastifyReply } from "fastify";

export type PreHandler = (request: FastifyRequest, reply: FastifyReply) => Promise<void>;

export async function requireAdmin(request: FastifyRequest, reply: FastifyReply) {
  const role = request.user?.role;
  if (role !== "service_role") {
    reply.code(403).send({ error: "Admin access required" });
  }
}
