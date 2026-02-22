import fp from "fastify-plugin";
import fastifyJwt from "@fastify/jwt";
import { createPublicKey } from "node:crypto";
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
    // Fetch JWKS from Supabase to detect signing algorithm
    // Newer Supabase versions sign JWTs with ES256 instead of HS256
    let jwtSecret: string | { public: string; private: string } = fastify.config.SUPABASE_JWT_SECRET;
    try {
      const jwksUrl = `${fastify.config.SUPABASE_URL}/auth/v1/.well-known/jwks.json`;
      const response = await fetch(jwksUrl);
      const jwks = (await response.json()) as { keys?: Array<{ alg?: string }> };
      const es256Jwk = jwks.keys?.find((k) => k.alg === "ES256");
      if (es256Jwk) {
        const publicPem = createPublicKey({ key: es256Jwk, format: "jwk" }).export({
          type: "spki",
          format: "pem",
        }) as string;
        jwtSecret = { public: publicPem, private: fastify.config.SUPABASE_JWT_SECRET };
        fastify.log.info("Using ES256 public key from Supabase JWKS for JWT verification");
      }
    } catch {
      fastify.log.warn("Could not fetch JWKS from Supabase — using HS256 for JWT verification");
    }

    await fastify.register(fastifyJwt, {
      secret: jwtSecret,
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
