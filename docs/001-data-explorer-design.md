# 001: Data Explorer Design Decisions

**Date**: 2025-12-31
**Status**: In Progress

## Context

Building a demo Rails app to showcase A2UI with real data. Need to choose a domain, data source, and interaction model.

## Decision: Garmin Health Data Explorer

### Options Considered

1. **Mock data** (products, orders) - Easy but not compelling
2. **CSV upload** - Generic but requires user effort
3. **Plausible Analytics** - Good API, but metrics-focused
4. **Garmin Connect via garmin-cli** - Rich, personal, multi-dimensional

### Choice: Garmin

**Reasoning**:
- Already have `garmin-cli` with Parquet storage + DuckDB query access
- Rich data: activities, sleep, stress, HRV, training load, VO2 max
- Time-series nature enables trends and correlations
- Personal data is more engaging than mock data

### Data Access

Evaluated two approaches:

| Approach | Pros | Cons |
|----------|------|------|
| Shell to `garmin-cli --format json` | Simple, no new deps | Subprocess overhead, limited queries |
| Direct DuckDB via `duckdb` gem | Fast, SQL flexibility | New dependency |

**Choice**: Direct DuckDB for queries, CLI for sync operations.

```ruby
# Query garmin-cli Parquet data via DuckDB
data_path = File.expand_path("~/Library/Application Support/garmin")
conn = DuckDB::Database.open.connect
conn.query("SELECT * FROM '#{data_path}/activities/*.parquet' LIMIT 1")
```

**Storage expectation (current)**:
- Only Parquet datasets + `sync.db` under `~/Library/Application Support/garmin`.
- Legacy `garmin.duckdb` is not used or required.

### Data Model (from garmin-cli)

Key Parquet datasets:
- `activities/*.parquet` - runs, rides, walks with pace, HR, elevation
- `daily_health/*.parquet` - steps, sleep, stress, body battery, HRV
- `performance_metrics/*.parquet` - VO2 max, training load, race predictions
- `weight_entries/*.parquet` - weight, BMI, body composition
- `track_points/*.parquet` - GPS time-series (high volume)

All datasets include `raw_json` for unmapped API fields.

### Current Local Inventory (2026-01-01)

Parquet datasets present locally:
- `daily_health/*.parquet`
- `performance_metrics/*.parquet`
- `track_points/*.parquet`

Parquet dataset currently missing:
- `activities/*.parquet`

Non-parquet file present:
- `sync.db`

## Decision: Narrative Briefing, Not Dashboard

### Problem with Dashboards

User feedback: "not a dashboard/widget theater"

Dashboards present raw metrics without synthesis:
- Step count: 8,432
- Sleep score: 79
- Body battery: 91
- Training load: 487

This requires the user to do the cognitive work of:
1. Understanding what each number means
2. Comparing to baselines
3. Identifying what's notable
4. Deciding what to do

### Alternative: Coach's Voice

A coach doesn't show you numbers — they tell you what the numbers mean:

> "You slept well and your body battery is fully charged. Good day for a harder workout. Your training load is in a productive zone — keep this balance."

### Implementation

The LLM synthesizes, not just formats:
- Compares to personal baselines ("faster than your November average")
- Identifies patterns ("third good night in a row")
- Correlates signals ("HRV stable + body battery high = ready for intensity")
- Recommends actions ("good day for tempo or intervals")

## Decision: Minimal Component Set

### Google A2UI Gallery Review

Reviewed 30+ components from Google's A2UI gallery. Relevant for health:
- Step Counter
- Workout Summary
- Stats Card
- User Profile (for athlete stats)

But these are still "widget" thinking.

### Chosen Components for Briefing

| Component | Purpose |
|-----------|---------|
| `Briefing` | Container with greeting, date, user context |
| `InsightBlock` | Icon + headline + 1-2 lines narrative |
| `MetricInline` | Numbers in prose: "7h 23m · Score 79" |
| `Suggestion` | Actionable recommendation with rationale |

### Example Output

```
┌─────────────────────────────────────────────────┐
│ Good morning, Vicente                           │
│ Tuesday, December 31                            │
├─────────────────────────────────────────────────┤
│ 🔋 Ready for intensity                          │
│ Body battery recharged to 91 overnight.         │
│ HRV stable at 52ms. You can push today.         │
├─────────────────────────────────────────────────┤
│ 😴 Solid sleep                                  │
│ 7h 23m · Score 79 · Deep 1h 48m                 │
│ Third good night in a row.                      │
├─────────────────────────────────────────────────┤
│ 🏃 Yesterday: 5.2 mi run                        │
│ 45:12 at 8:41/mi · HR avg 148                   │
│ Faster than your November average.              │
├─────────────────────────────────────────────────┤
│ 💡 Today                                        │
│ Good day for tempo or intervals.                │
│ Your body can handle the load.                  │
└─────────────────────────────────────────────────┘
```

## Decision: Agent Execution Model

### Requirements

1. Non-blocking UI (user sees immediate feedback)
2. Agent can take time to reason (LLM calls)
3. Real-time updates as agent works
4. Persistence across requests

### Architecture

```
Request Thread                    Background Job
─────────────────                 ──────────────────────
1. Parse intent (fast)
2. Return "Analyzing..." card
3. Enqueue AgentJob ─────────────▶ 4. Query DuckDB over Parquet
                                   5. ChainOfThought reasoning
                                   6. Generate components
                                   7. Broadcast via ActionCable
                                        │
Client ◀─────────────────────────────────
        Turbo Stream updates
```

### Tech Stack

- **Rails 8.1** defaults
- **Solid Queue** for background jobs
- **ActionCable** for real-time broadcasts
- **Turbo Streams** for UI updates
- **SQLite** for app data (surfaces, sessions)
- **DuckDB** for Garmin Parquet data (read-only)

## Open Questions

1. **Async gem**: Could parts of the agent run in-request with cooperative concurrency? Or does the job boundary make more sense?

2. **Surface persistence**: Store generated surfaces in SQLite? Or regenerate on each request?

3. **Caching**: Cache Garmin queries? Cache LLM responses?

## References

- [Google A2UI](https://github.com/google/A2UI)
- [garmin-cli](https://github.com/vicentereig/garmin-cli)
- [Parquet export issue](https://github.com/vicentereig/garmin-cli/issues/1)
