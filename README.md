# hilsen-api

Fastify + TypeScript backend for Hilsen. Handles cards, designs, templates, stickers, placeholder images, users, and scheduled SMS sends.

## Stack

- **Fastify 5** with TypeBox type provider
- **Supabase** (Postgres, Auth, Storage) — JWT-based auth
- **Twilio** — SMS delivery
- **Directus** — media/asset management
- **Sentry** — error tracking
- **Vitest** — tests
- Hosted on **Dokploy**, DB on **Supabase**

## Requirements

- Node 20+
- A `.env` (or `.env.stage`) with the vars declared in [`src/config/env.ts`](src/config/env.ts).

Required env vars:

```
SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY
SUPABASE_JWT_SECRET
TWILIO_ACCOUNT_SID
TWILIO_AUTH_TOKEN
TWILIO_SENDER_ID
APP_BASE_URL
DIRECTUS_URL
DIRECTUS_TOKEN
```

Optional: `PORT`, `HOST`, `LOG_LEVEL`, `DIRECTUS_UPLOAD_FOLDER_ID`, `SENTRY_DSN`, `SENTRY_ENVIRONMENT`, `GIT_SHA`, `POSTHOG_*`.

## Scripts

| Command | Description |
| --- | --- |
| `npm run dev` | Start dev server with watch mode (`.env`) |
| `npm run dev:stage` | Dev server using `.env.stage` |
| `npm run build` | Compile TypeScript to `dist/` |
| `npm start` | Run compiled server |
| `npm test` | Run Vitest suite once |
| `npm run test:watch` | Vitest in watch mode |
| `npm run lint` / `lint:fix` | ESLint |
| `npm run format` | Prettier |
| `npm run gen:token` | Generate a dev JWT (see `scripts/gen-token.ts`) |

## Project layout

```
src/
  app.ts            # Fastify app builder (plugins, routes, swagger)
  server.ts         # Entrypoint: boots app + scheduled-sends worker
  config/env.ts     # Env schema (via @fastify/env)
  plugins/          # Fastify plugins (auth, supabase, etc.)
  routes/           # Route modules: cards, designs, sends, stickers, templates, users, placeholder-images
  services/         # Business logic
  workers/          # Background workers (scheduled sends)
  lib/              # Shared helpers
supabase/
  migrations/       # SQL migrations applied via CI
  functions/        # Edge functions
bruno/              # Bruno API collection for manual testing
```

## API docs

Swagger UI is mounted when the server is running — visit `/docs` on the running instance.

## Database migrations

Migrations live in `supabase/migrations/`. They're applied automatically by `.github/workflows/migrate.yml`:

- **Staging**: push to `master` → CI runs `supabase db push` against the staging project.
- **Production**: tag a release (`vX.Y.Z`) → CI runs `supabase db push` against the production project.

## Deployment

Dokploy deploys the API:

- **Staging** tracks `master`.
- **Production** tracks version tags.

## Testing locally

```bash
npm install
cp .env.example .env   # if present, otherwise create one
npm run dev
```

Use the Bruno collection in `bruno/` to exercise endpoints.
