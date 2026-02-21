import fp from "fastify-plugin";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { type FastifyInstance } from "fastify";

declare module "fastify" {
  interface FastifyInstance {
    supabase: SupabaseClient;
  }
}

export default fp(
  async function supabasePlugin(fastify: FastifyInstance) {
    const client = createClient(
      fastify.config.SUPABASE_URL,
      fastify.config.SUPABASE_SERVICE_ROLE_KEY,
    );

    fastify.decorate("supabase", client);
  },
  { name: "supabase" },
);
