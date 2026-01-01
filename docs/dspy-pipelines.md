# DSPy Pipelines

This document describes the DSPy pipeline architecture used in A2UI Rails and the Briefing system, including concurrency patterns using the `async` gem.

## A2UI Pipelines

### Pipeline Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           A2UI DSPy Pipelines                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ CREATE SURFACE                                                       │   │
│  │                                                                      │   │
│  │   "Create a booking form"  ───▶  GenerateUI (ChainOfThought)        │   │
│  │         + surface_id                      │                          │   │
│  │         + available_data           ┌──────┴──────┐                   │   │
│  │                                    ▼             ▼                   │   │
│  │                              root_id      components[]               │   │
│  │                              "form-1"     [Column, TextField,        │   │
│  │                                            TextField, Button]        │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ UPDATE SURFACE                                                       │   │
│  │                                                                      │   │
│  │   "Add phone field"        ───▶  UpdateUI (ChainOfThought)          │   │
│  │         + current_components              │                          │   │
│  │         + current_data             ┌──────┴──────┐                   │   │
│  │                                    ▼             ▼                   │   │
│  │                              streams[]    new_components[]           │   │
│  │                              [{action:    [TextFieldComponent]       │   │
│  │                                "after",                              │   │
│  │                                target:                               │   │
│  │                                "email"}]                             │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ HANDLE ACTION                                                        │   │
│  │                                                                      │   │
│  │   UserAction{name,context} ───▶  HandleAction (ChainOfThought)      │   │
│  │         + business_rules                  │                          │   │
│  │         + current_data            ┌───────┼───────┐                  │   │
│  │                                   ▼       ▼       ▼                  │   │
│  │                            response   streams  data_updates          │   │
│  │                            _type      []       [{path: "/booking",   │   │
│  │                            :update_ui          entries: [...]}]      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Signals (Inputs)

- `request` — Natural language describing what to build/change
- `available_data` / `current_data` — JSON data model the UI binds to
- `current_components` — Existing component tree for incremental updates
- `business_rules` — Domain constraints for action handling

### Decisions (LLM Reasoning via ChainOfThought)

1. **Component Selection** — Which component types fit the request?
2. **Layout Structure** — How to arrange components (Row vs Column, nesting)?
3. **Data Binding** — Which JSON Pointer paths connect to which fields?
4. **Action Mapping** — What context to capture when buttons are clicked?
5. **Stream Operations** — For updates: append, replace, or remove?

### Outputs (Structured)

- `components[]` — Flat adjacency list of typed component structs
- `root_id` — Entry point for rendering the tree
- `streams[]` — Turbo Stream operations (action + target + content)
- `data_updates[]` — Mutations to apply to the data model

## Briefing Pipeline

### Pipeline Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Briefing DSPy Pipeline                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ DATA FETCHING (Async Parallel)                                       │   │
│  │                                                                      │   │
│  │   Garmin Connection                                                  │   │
│  │         │                                                            │   │
│  │         ├──▶ DailyHealth Query ──┬──▶ for_date()                    │   │
│  │         │                        ├──▶ sleep_trend()                  │   │
│  │         │                        └──▶ recovery_status()              │   │
│  │         │                                                            │   │
│  │         ├──▶ Activities Query ───┬──▶ recent()                       │   │
│  │         │                        └──▶ week_stats()                   │   │
│  │         │                                                            │   │
│  │         └──▶ Performance Query ──┬──▶ latest()                       │   │
│  │                                  ├──▶ training_load_status()         │   │
│  │                                  ├──▶ vo2max_trend()                 │   │
│  │                                  └──▶ race_predictions()             │   │
│  │                                                                      │   │
│  │   All 9 queries run concurrently via Async::Barrier                  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ CONTEXT BUILDING                                                     │   │
│  │                                                                      │   │
│  │   Query Results ───▶ ContextBuilder ───▶ health_context             │   │
│  │                                     ───▶ activity_context            │   │
│  │                                     ───▶ performance_context         │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ BRIEFING GENERATION                                                  │   │
│  │                                                                      │   │
│  │   Contexts + user_name  ───▶  DailyBriefing (ChainOfThought)        │   │
│  │   + date                              │                              │   │
│  │                                ┌──────┼──────┐                       │   │
│  │                                ▼      ▼      ▼                       │   │
│  │                          greeting  insights  suggestions             │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ STREAMING OUTPUT                                                     │   │
│  │                                                                      │   │
│  │   Results ───▶ BriefingChannel ───▶ broadcast_insight()             │   │
│  │                                ───▶ broadcast_suggestion()           │   │
│  │                                ───▶ broadcast_complete()             │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Async Concurrency Patterns

### When Async Helps

| Scenario | Benefit | Implementation |
|----------|---------|----------------|
| Multiple data queries | 9 queries → 1 batch | `Async::Barrier` |
| Batch surface creation | N surfaces in parallel | `SurfaceManager#create_batch` |
| Multi-section dashboards | Independent UI sections | Parallel `UIGenerator` calls |
| LLM calls (HTTP I/O) | Non-blocking I/O | Automatic with `async` |

### When Async Doesn't Help

| Scenario | Reason |
|----------|--------|
| Single surface creation | Only one LLM call |
| Sequential UI updates | Each update depends on previous state |
| Action handling | Single request-response cycle |

### Implementation Examples

#### Parallel Data Fetching (Briefing)

```ruby
require 'async'

Sync do
  barrier = Async::Barrier.new
  results = {}

  barrier.async { results[:daily_health] = health_query.for_date(date) }
  barrier.async { results[:sleep_trend] = health_query.sleep_trend(days: 7) }
  barrier.async { results[:recovery_status] = health_query.recovery_status(date) }
  barrier.async { results[:recent_activities] = activities_query.recent(limit: 5) }
  barrier.async { results[:week_stats] = activities_query.week_stats(date) }
  barrier.async { results[:performance_metrics] = performance_query.latest }
  barrier.async { results[:training_load] = performance_query.training_load_status }
  barrier.async { results[:vo2max_trend] = performance_query.vo2max_trend }
  barrier.async { results[:race_predictions] = performance_query.race_predictions }

  barrier.wait
  results
end
```

#### Batch Surface Creation (A2UI)

```ruby
require 'async'

def create_batch(requests)
  Sync do
    barrier = Async::Barrier.new
    surfaces = []

    requests.each do |req|
      barrier.async do
        surface = create(
          surface_id: req[:surface_id],
          request: req[:request],
          data: req[:data] || '{}'
        )
        surfaces << surface
      end
    end

    barrier.wait
    surfaces
  end
end
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Your Rails App                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  DSPy Signatures          DSPy Modules         Controllers   │
│  ┌─────────────┐         ┌─────────────┐      ┌───────────┐ │
│  │ GenerateUI  │────────▶│ UIGenerator │─────▶│ Surfaces  │ │
│  │ UpdateUI    │         │ UIUpdater   │      │ Actions   │ │
│  │ HandleAction│         │ ActionHndlr │      └───────────┘ │
│  │ DailyBrief. │         │ BriefingGen │                    │
│  └─────────────┘         └─────────────┘            │       │
│         │                       │                   │       │
│         ▼                       ▼                   ▼       │
│  ┌─────────────────────────────────────────────────────────┐│
│  │              A2UI::Components::Renderer                 ││
│  │         Maps Component structs → ViewComponents         ││
│  └─────────────────────────────────────────────────────────┘│
│                            │                                 │
│                            ▼                                 │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                 Turbo Streams / Frames                  ││
│  │                 ActionCable Channels                    ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## End-to-End Data Flow

The streaming architecture uses Server-Sent Events (SSE) for real-time updates:

1. **Server Stream**: Server sends JSONL stream over SSE
2. **Client Buffering**: Client parses `surfaceUpdate` and `dataModelUpdate` messages
3. **Render Signal**: Server sends `beginRendering` to trigger UI build
4. **Client-Side Rendering**: Client walks component tree, resolves bindings, instantiates widgets
5. **User Interaction**: Client constructs `userAction` payload on button clicks
6. **Event Handling**: `userAction` sent via A2A message to server
7. **Dynamic Updates**: Server processes event, sends new updates over original SSE stream
