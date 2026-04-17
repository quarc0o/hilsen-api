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

      // Look up user by supabase_id
      let { data: user, error } = await fastify.supabase
        .from("users")
        .select("id")
        .eq("supabase_id", supabaseId)
        .single();

      // If no user record exists, auto-create one for this authenticated user
      if (error || !user) {
        // Get the phone number from Supabase auth to match lazy users
        const { data: authUser } = await fastify.supabase.auth.admin.getUserById(supabaseId);
        const rawPhone = authUser?.user?.phone ?? null;
        const phone = rawPhone ? rawPhone.replace(/^\+/, "") : null;

        // Check if a lazy user (created via invite) exists with this phone
        if (phone) {
          const { data: lazyUser } = await fastify.supabase
            .from("users")
            .select("id")
            .eq("phone_number", phone)
            .is("supabase_id", null)
            .single();

          if (lazyUser) {
            // Link the lazy user to this Supabase account
            const { data: linked, error: linkError } = await fastify.supabase
              .from("users")
              .update({ supabase_id: supabaseId })
              .eq("id", lazyUser.id)
              .select("id")
              .single();

            if (!linkError && linked) {
              request.userId = linked.id;
              request.supabaseId = supabaseId;
              return;
            }
          }
        }

        // No lazy user — create a new user record
        const { data: newUser, error: createError } = await fastify.supabase
          .from("users")
          .insert({ supabase_id: supabaseId, phone_number: phone })
          .select("id")
          .single();

        if (createError || !newUser) {
          fastify.log.error({ createError }, "Failed to auto-create user record");
          reply.code(401).send({ error: "User not found" });
          return;
        }

        user = newUser;
      }

      request.userId = user.id;
      request.supabaseId = supabaseId;
    });

    fastify.decorateRequest("userId", "");
    fastify.decorateRequest("supabaseId", "");
  },
  { name: "auth", dependencies: ["supabase"] },
);
