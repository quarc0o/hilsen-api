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
// Treats `persons_found === 0` as a failure so callers can surface a warning
// when the identity mapping is off (e.g. client identified with a different id).
export async function deletePostHogPerson(
  config: PostHogConfig,
  distinctId: string,
): Promise<
  | { ok: true; personsDeleted: number }
  | { ok: false; status?: number; body?: string; error?: unknown }
> {
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
    const rawBody = await response.text().catch(() => "");
    if (!response.ok) {
      return { ok: false, status: response.status, body: rawBody };
    }
    const parsed = safeParseJson(rawBody) as { persons_found?: number; persons_deleted?: number };
    const personsDeleted = parsed?.persons_deleted ?? 0;
    if (personsDeleted === 0) {
      return { ok: false, status: response.status, body: rawBody };
    }
    return { ok: true, personsDeleted };
  } catch (error) {
    return { ok: false, error };
  }
}

function safeParseJson(body: string): unknown {
  try {
    return JSON.parse(body);
  } catch {
    return null;
  }
}
