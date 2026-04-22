import { type EnvConfig } from "../config/env.js";

export interface PostHogConfig {
  host: string;
  projectId: string;
  apiKey: string;
}

export function getPostHogConfig(env: EnvConfig): PostHogConfig | null {
  if (!env.POSTHOG_PROJECT_ID || !env.POSTHOG_PERSONAL_API_KEY) return null;
  return {
    host: env.POSTHOG_HOST ?? "https://eu.posthog.com",
    projectId: env.POSTHOG_PROJECT_ID,
    apiKey: env.POSTHOG_PERSONAL_API_KEY,
  };
}

// Best-effort GDPR delete for a PostHog person by distinct_id.
// Returns true on success, false on failure (caller decides how to react).
export async function deletePostHogPerson(
  config: PostHogConfig,
  distinctId: string,
): Promise<{ ok: true } | { ok: false; status?: number; body?: string; error?: unknown }> {
  const url = `${config.host.replace(/\/$/, "")}/api/projects/${config.projectId}/persons/bulk_delete/`;
  try {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        authorization: `Bearer ${config.apiKey}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({ distinct_ids: [distinctId], delete_events: true }),
    });
    if (!response.ok) {
      const body = await response.text().catch(() => "");
      return { ok: false, status: response.status, body };
    }
    return { ok: true };
  } catch (error) {
    return { ok: false, error };
  }
}
