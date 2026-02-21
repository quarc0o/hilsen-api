import fp from "fastify-plugin";
import fastifyJwt from "@fastify/jwt";
import { type FastifyInstance, type FastifyRequest, type FastifyReply } from "fastify";

declare module "fastify" {
  interface FastifyInstance {
    authenticate: (request: FastifyRequest, reply: FastifyReply) => Promise<void>;
  }
}

declare module "@fastify/jwt" {
  interface FastifyJWT {
    payload: {
      sub: string;
      role?: string;
      aud?: string;
    };
    user: {
      sub: string;
      role?: string;
      aud?: string;
    };
  }
}

declare module "fastify" {
  interface FastifyRequest {
    userId: string;
    supabaseId: string;
  }
}

export default fp(
  async function authPlugin(fastify: FastifyInstance) {
    await fastify.register(fastifyJwt, {
      secret: fastify.config.SUPABASE_JWT_SECRET,
    });

    fastify.decorate("authenticate", async function (request: FastifyRequest, reply: FastifyReply) {
      try {
        await request.jwtVerify();
      } catch {
        reply.code(401).send({ error: "Unauthorized" });
        return;
      }

      const supabaseId = request.user.sub;

      const { data: user, error } = await fastify.supabase
        .from("users")
        .select("id")
        .eq("supabase_id", supabaseId)
        .single();

      if (error || !user) {
        reply.code(401).send({ error: "User not found" });
        return;
      }

      request.userId = user.id;
      request.supabaseId = supabaseId;
    });

    fastify.decorateRequest("userId", "");
    fastify.decorateRequest("supabaseId", "");
  },
  { name: "auth", dependencies: ["supabase"] },
);
