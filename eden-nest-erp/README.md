# Eden Nest ERP

The Operating System for Farm-to-Consumer Agriculture Businesses.

Multi-tenant ERP starting point for Eden Nest Farm, built to grow from a single-farm
operation into a full SaaS product. See `docs/erd.md` for the complete architecture,
security, and roadmap blueprint this scaffold implements.

## Stack
- **Frontend:** Next.js (App Router) + TypeScript + Tailwind — `apps/web`
- **Database/Auth:** Supabase (Postgres + RLS + GoTrue) — `packages/db`
- **Shared logic:** `packages/domain` (pure business rules, framework-free)
- **API layer:** `packages/api` (tRPC routers, one per module)
- **UI kit:** `packages/ui` (shared components)

## Quickstart

```bash
pnpm install
cp .env.example .env.local        # fill in Supabase project keys
supabase link --project-ref <ref>
supabase db push                  # applies packages/db/migrations
pnpm dev                          # starts apps/web on localhost:3000
```

## Monorepo layout
See `docs/erd.md` §5 for the full folder structure rationale. Modules are independent:
each owns its own domain folder, API router, and migration files.

## Security
Row Level Security is enabled on every tenant table from the first migration.
Never accept `company_id` from client input — it is always derived from the
authenticated session. See `docs/erd.md` §3 and §12.5 before opening a PR.
