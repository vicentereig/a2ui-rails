# Garmin Parquet Compatibility Plan

## Context
- Current Garmin integration assumes a single DuckDB file (`garmin.duckdb`) and SQL tables like `activities`, `daily_health`, `performance_metrics`.
- The new `garmin-cli` stores data in time-partitioned Parquet files under the Garmin data directory and recommends querying via DuckDB globs.
- `garmin-cli` (new) storage layout (from `../garmin-cli/README.md`):
  - Base dir (macOS): `~/Library/Application Support/garmin`
  - Parquet datasets:
    - `activities/*.parquet` (weekly partitions)
    - `daily_health/*.parquet` (monthly partitions)
    - `performance_metrics/*.parquet` (monthly partitions)
    - `track_points/*.parquet` (daily partitions, not used by current Rails code)
    - `profiles.parquet` (single file, not used yet)
  - Also a `sync.db` SQLite file (for sync state, not the analytics tables).
- Current Rails Garmin code reads from `Garmin::Connection.default_db_path`:
  - `lib/garmin/connection.rb` → `~/Library/Application Support/garmin/garmin.duckdb`
  - Queries in `lib/garmin/queries/*.rb` assume SQL tables (e.g., `SELECT * FROM activities`).
- Current Garmin usage in Rails:
  - `app/jobs/generate_briefing_job.rb` reads Garmin queries: `DailyHealth`, `Activities`, `Performance`.
  - `lib/briefing/context_builder.rb` expects data from those models for the LLM briefing.
- Known target update: keep the public Ruby API for queries similar, but swap implementation to DuckDB parquet scans.

## Reference Snippets (from `../garmin-cli/README.md`)
```sql
-- activities
SELECT * FROM '~/Library/Application Support/garmin/activities/*.parquet'
ORDER BY start_time_local DESC
LIMIT 10;

-- daily health
SELECT * FROM '~/Library/Application Support/garmin/daily_health/*.parquet'
WHERE date >= '2025-01-01'
ORDER BY date;

-- performance
SELECT date, training_status, training_readiness, vo2max
FROM '~/Library/Application Support/garmin/performance_metrics/*.parquet'
WHERE date >= '2025-12-01'
ORDER BY date DESC;
```

## Proposed Configuration (to avoid hard-coding)
- Introduce `GARMIN_DATA_PATH` (base directory) env var with fallback to `Garmin::Connection.default_data_path`.
- Keep `GARMIN_DB_PATH` only if we need backward compatibility with legacy DuckDB file.

## Files to Update (likely)
- `lib/garmin/connection.rb`
- `lib/garmin/queries/activities.rb`
- `lib/garmin/queries/daily_health.rb`
- `lib/garmin/queries/performance.rb`
- `docs/001-data-explorer-design.md` (update storage access section)
- `README.md` (if it mentions DuckDB file or CLI usage)

## Review Findings Snapshot (carry-forward)
- Critical: Stimulus controller method name collision + payload mismatch:
  - `app/javascript/controllers/a2ui_action_controller.js` defines a `dispatch` method and then calls `this.dispatch(...)`, which recurses because it overrides Stimulus’s built-in `dispatch`. Also sends `action` in payload, while server expects `action_name`. Server requires `action_name` in `app/controllers/a2ui/actions_controller.rb` and `app/channels/a2ui/surface_channel.rb`.
  - Docs also show the wrong payload key (`docs/a2ui-turbo-mapping.md`).
- High: Data model is stored by JSON-pointer keys instead of nested hashes:
  - `lib/a2ui/modules/surface.rb` stores data as `@data[update.path] = ...`, but renderers and bindings use JSON-pointer traversal expecting nested hashes (`app/components/a2ui/components/base.rb`, `app/javascript/controllers/a2ui_data_controller.js`). This breaks value resolution/bindings and `app/views/a2ui/_surface.html.erb` ships a mismatched model.
- High: `SurfaceManager` stored in session:
  - `app/controllers/a2ui/surfaces_controller.rb` / `app/controllers/a2ui/actions_controller.rb` persist `SurfaceManager` in session. Cookie store cannot serialize it; server-side stores are still brittle. Also `SurfaceManager#update`/`#handle_action` `fetch` raises on missing surfaces.
- High: ActionCable and HTTP use different in-memory surface stores:
  - `app/channels/a2ui/surface_channel.rb` has its own manager, so it won’t see surfaces created via HTTP.
- Medium: Server applies `data_updates` but doesn’t push model updates to the client data controller, so client data can drift.
- Medium: `SurfacesController#render_components` treats `stream_op.target` as a surface id (likely wrong; targets are component/container ids), leading to empty data lookups.
- Medium: Garmin queries use string interpolation into SQL; if args are user-controlled, this is SQL injection risk.
- Low: `Garmin::Connection#close` doesn’t close underlying DuckDB handles.

## Plan (Progress Tracking)
- [x] Inspect the new `garmin-cli` Parquet layout and schema to confirm required columns for activities, daily health, and performance metrics.
- [x] Refactor `Garmin::Connection` to target a Parquet base path (env-configurable) and provide DuckDB helpers for parquet glob queries or view creation.
- [x] Rewrite `Garmin::Queries` (activities/daily_health/performance) to query Parquet globs instead of DuckDB tables, keeping filtering/ordering compatible.
- [x] Update docs/config (README + design notes + env vars) to reflect parquet storage and new configuration.
- [x] Add/adjust tests for parquet query paths (unit-level with stubs or fixture parquet if available).
