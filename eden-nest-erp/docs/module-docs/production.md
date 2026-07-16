# Module: Production

## Purpose
Tracks daily egg production per farm unit (flock/coop), capturing both
inputs (bird count, breed, feed, mortality) and outputs (eggs produced,
broken eggs, quality grade), per `docs/erd.md` §2.

## Database tables owned
- `production` — one row per farm unit per day
- References `farm_units`, `users` (created_by)

## API endpoints
- `GET /api/production` — list logs, filterable by farm/date range
- `POST /api/production` — create a new daily log

## Key business rules
- **Production percentage** = eggs produced ÷ bird count × 100
  (see `packages/domain/production/calculations.ts`)
- **Quality grade** auto-assigned from broken-egg ratio:
  - ≤ 2.5% broken → Grade A
  - 2.5–5% broken → Grade B
  - \> 5% broken → Grade C
- A production log cannot be created for a `farm_unit_id` the signed-in
  user's company doesn't own — enforced by RLS on `farm_units.farm_id →
  farms.company_id`.

## Owned by
Farm Management domain team. Changes to the grading thresholds must be
reflected in both this file and the Quality Control module docs, since
Quality Control's rejection-rate alerting uses the same thresholds.
