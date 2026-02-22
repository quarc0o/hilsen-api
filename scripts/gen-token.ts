import jwt from "jsonwebtoken";
import { config } from "dotenv";

config();

const sub = process.argv[2];

if (!sub) {
  console.error("Usage: npx tsx scripts/gen-token.ts <supabase-user-uid>");
  process.exit(1);
}

const secret = process.env.SUPABASE_JWT_SECRET;

if (!secret) {
  console.error("SUPABASE_JWT_SECRET not found in .env");
  process.exit(1);
}

const token = jwt.sign({ sub, role: "authenticated", aud: "authenticated" }, secret, {
  expiresIn: "7d",
});

console.log(token);
