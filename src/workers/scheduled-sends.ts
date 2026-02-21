import { type SupabaseClient } from "@supabase/supabase-js";
import { processScheduledSends } from "../services/sends.service.js";

const POLL_INTERVAL_MS = 60_000; // 1 minute

export function startScheduledSendsWorker(supabase: SupabaseClient) {
  const timer = setInterval(async () => {
    try {
      const processed = await processScheduledSends(supabase);
      if (processed.length > 0) {
        console.log(`[scheduled-sends] Processed ${processed.length} scheduled sends`);
      }
    } catch (err) {
      console.error("[scheduled-sends] Error processing scheduled sends:", err);
    }
  }, POLL_INTERVAL_MS);

  return () => clearInterval(timer);
}
