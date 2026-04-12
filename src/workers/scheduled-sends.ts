import { type SupabaseClient } from "@supabase/supabase-js";
import { processScheduledSends, type SendsWorkerConfig } from "../services/sends.service.js";

const POLL_INTERVAL_MS = 60_000; // 1 minute

export function startScheduledSendsWorker(supabase: SupabaseClient, config: SendsWorkerConfig) {
  // Run immediately on startup to catch sends that came due while server was down
  processScheduledSends(supabase, config)
    .then((processed) => {
      if (processed.length > 0) {
        console.log(`[scheduled-sends] Startup: processed ${processed.length} scheduled sends`);
      }
    })
    .catch((err) => {
      console.error("[scheduled-sends] Startup error:", err);
    });

  const timer = setInterval(async () => {
    try {
      const processed = await processScheduledSends(supabase, config);
      if (processed.length > 0) {
        console.log(`[scheduled-sends] Processed ${processed.length} scheduled sends`);
      }
    } catch (err) {
      console.error("[scheduled-sends] Error processing scheduled sends:", err);
    }
  }, POLL_INTERVAL_MS);

  return () => clearInterval(timer);
}
