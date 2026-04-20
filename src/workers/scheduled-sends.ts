import { type SupabaseClient } from "@supabase/supabase-js";
import { processScheduledSends, type SendsWorkerConfig } from "../services/sends.service.js";
import { captureWithTags } from "../lib/sentry.js";

const POLL_INTERVAL_MS = 60_000; // 1 minute

function reportFailure(err: unknown, phase: string) {
  console.error(`[scheduled-sends] ${phase} error:`, err);
  captureWithTags(err, { worker: "scheduled-sends", phase });
}

export function startScheduledSendsWorker(supabase: SupabaseClient, config: SendsWorkerConfig) {
  // Run immediately on startup to catch sends that came due while server was down
  processScheduledSends(supabase, config)
    .then((processed) => {
      if (processed.length > 0) {
        console.log(`[scheduled-sends] Startup: processed ${processed.length} scheduled sends`);
      }
    })
    .catch((err) => reportFailure(err, "startup"));

  const timer = setInterval(async () => {
    try {
      const processed = await processScheduledSends(supabase, config);
      if (processed.length > 0) {
        console.log(`[scheduled-sends] Processed ${processed.length} scheduled sends`);
      }
    } catch (err) {
      reportFailure(err, "tick");
    }
  }, POLL_INTERVAL_MS);

  return {
    stop: () => clearInterval(timer),
    flush: () => {
      processScheduledSends(supabase, config).catch((err) => reportFailure(err, "flush"));
    },
  };
}
