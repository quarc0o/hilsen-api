import * as Sentry from "@sentry/node";
import type { Event } from "@sentry/node";

export interface SentryInitOptions {
  dsn: string | undefined;
  environment: string | undefined;
  release: string;
}

const SENSITIVE_HEADER_KEYS = new Set(["authorization", "cookie"]);
const SENSITIVE_BODY_KEYS = new Set([
  "message",
  "greeting",
  "phone",
  "recipient_phone",
  "recipient_name",
  "sender_name",
  "to",
]);
const JWT_REGEX = /eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/g;
const PHONE_STANDALONE_REGEX = /^\+?\d{8,}$/;
// Aggressively scrub long digit sequences from strings — catches phones embedded
// in error messages. Over-filters things like 8+ digit IDs; acceptable trade-off.
const PHONE_INLINE_REGEX = /\+?\d{8,}/g;

let initialized = false;

export function initSentry(options: SentryInitOptions): boolean {
  if (initialized) return true;
  if (!options.dsn) return false;

  Sentry.init({
    dsn: options.dsn,
    environment: options.environment,
    release: options.release,
    tracesSampleRate: 0,
    sendDefaultPii: false,
    beforeSend: scrubEvent,
  });

  initialized = true;
  return true;
}

export function isSentryEnabled(): boolean {
  return initialized;
}

export function captureWithTags(
  err: unknown,
  tags: Record<string, string | number | undefined>,
): void {
  if (!initialized) return;
  Sentry.withScope((scope) => {
    for (const [key, value] of Object.entries(tags)) {
      if (value !== undefined) scope.setTag(key, String(value));
    }
    Sentry.captureException(err);
  });
}

function scrubEvent(event: Event): Event | null {
  if (event.request?.headers) event.request.headers = scrubHeaders(event.request.headers);
  if (event.request?.data !== undefined) event.request.data = scrubValue(event.request.data);
  if (typeof event.request?.query_string === "string") {
    event.request.query_string = scrubString(event.request.query_string);
  }
  if (event.extra) event.extra = scrubValue(event.extra) as Record<string, unknown>;
  if (event.contexts) event.contexts = scrubValue(event.contexts) as typeof event.contexts;
  if (event.breadcrumbs) {
    for (const crumb of event.breadcrumbs) {
      if (crumb.data) crumb.data = scrubValue(crumb.data) as Record<string, unknown>;
      if (crumb.message) crumb.message = scrubString(crumb.message);
    }
  }
  if (event.exception?.values) {
    for (const exc of event.exception.values) {
      if (exc.value) exc.value = scrubString(exc.value);
    }
  }
  if (event.message) event.message = scrubString(event.message);
  return event;
}

function scrubHeaders(headers: Record<string, string>): Record<string, string> {
  const out: Record<string, string> = {};
  for (const [key, value] of Object.entries(headers)) {
    if (SENSITIVE_HEADER_KEYS.has(key.toLowerCase())) continue;
    out[key] = scrubString(value);
  }
  return out;
}

function scrubValue(value: unknown): unknown {
  if (value === null || value === undefined) return value;
  if (typeof value === "string") return scrubString(value);
  if (Array.isArray(value)) return value.map(scrubValue);
  if (typeof value === "object") {
    const out: Record<string, unknown> = {};
    for (const [key, val] of Object.entries(value as Record<string, unknown>)) {
      if (SENSITIVE_BODY_KEYS.has(key.toLowerCase())) {
        out[key] = "[Filtered]";
        continue;
      }
      out[key] = scrubValue(val);
    }
    return out;
  }
  return value;
}

function scrubString(value: string): string {
  if (PHONE_STANDALONE_REGEX.test(value)) return "[Filtered]";
  return value.replace(JWT_REGEX, "[Filtered]").replace(PHONE_INLINE_REGEX, "[Filtered]");
}
