# Hierarchical Briefings

## Overview

Time-based navigation system for briefings with hierarchical rollups. Each zoom level summarizes the level below it, requiring persistence and cascade generation.

## Hierarchy

```
Year     → summarizes 4 quarters
Quarter  → summarizes 3 months
Month    → summarizes 4-5 weeks
Week     → summarizes 7 days
Day      → raw Garmin metrics (current implementation)
```

## Features

1. **Persistence** - Store input/output payloads for each briefing
2. **Navigation** - Move through time at any zoom level
3. **Zoom** - Switch between day/week/month/quarter/year views
4. **Refresh** - Regenerate any briefing with current data/prompts
5. **Versioning** - Track when briefings were generated

## Database Schema

```ruby
create_table :briefings do |t|
  t.date :start_date, null: false
  t.string :period_type, null: false  # day, week, month, quarter, year
  t.string :status, null: false, default: 'pending'

  # DSPy payloads - what went in and what came out
  t.jsonb :input_payload   # null until generated
  t.jsonb :output_payload  # null until generated

  t.integer :version, default: 1
  t.datetime :generated_at
  t.timestamps

  t.index [:start_date, :period_type], unique: true
  t.index :status
end
```

### Status Values

- `pending` - Never generated
- `generating` - Job in progress
- `complete` - Ready to view
- `stale` - Marked for refresh (children updated since generation)

## Payload Structures

### Day Level (raw metrics)

```ruby
# input_payload
{
  user_name: "Vicente",
  date: "2025-01-01",
  health_context: "Sleep 7.2h, HRV 48ms, Body Battery 65...",
  activity_context: "10km run at 5:30/km, Zone 2 training...",
  performance_context: "VO2 Max 52, Training Status: Productive..."
}

# output_payload
{
  greeting: "Good morning, Vicente.",
  status: {
    headline: "Recovery On Track",
    metrics: [
      { label: "Sleep", value: "7.2h", trend: "up" },
      { label: "HRV", value: "48ms", trend: "stable" },
      { label: "Body Battery", value: "65", trend: "up" }
    ],
    summary: "Solid recovery overnight with improved sleep quality...",
    sentiment: "positive"
  },
  suggestions: [
    { title: "Zone 2 Today", body: "Your recovery supports a moderate effort...", suggestion_type: "intensity" },
    { title: "Hydrate Early", body: "Start hydration before your afternoon run...", suggestion_type: "general" }
  ]
}
```

### Week Level (aggregates days)

```ruby
# input_payload
{
  user_name: "Vicente",
  period: "2025-W01",
  period_start: "2024-12-30",
  period_end: "2025-01-05",
  daily_briefings: [
    {
      date: "2024-12-30",
      status: { headline: "...", summary: "...", sentiment: "positive" },
      suggestions: [...]
    },
    # ... 6 more days
  ]
}

# output_payload - Weekly summary synthesized from daily outputs
{
  greeting: "Here's your week in review.",
  status: {
    headline: "Strong Training Week",
    metrics: [
      { label: "Avg Sleep", value: "7.1h", trend: "up" },
      { label: "Total Distance", value: "45km" },
      { label: "Recovery Days", value: "2" }
    ],
    summary: "Consistent training load with adequate recovery...",
    sentiment: "positive"
  },
  suggestions: [
    { title: "Maintain Volume", body: "This week's load is sustainable...", suggestion_type: "intensity" }
  ]
}
```

### Month/Quarter/Year Levels

Same pattern - input contains child period briefings, output is synthesized summary.

## Cascade Generation

When requesting a briefing that doesn't exist, generate dependencies first:

```
Request: "Show Week 1 briefing"
         │
         ▼
    Week 1 exists? ─── YES ──→ Display
         │
         NO
         ▼
    Find required days (Mon-Sun)
         │
         ▼
    [Mon ✓] [Tue ✓] [Wed ✗] [Thu ✗] [Fri ✓] [Sat ✗] [Sun ✗]
         │
         ▼
    Generate missing: Wed, Thu, Sat, Sun
         │
         ▼
    Generate Week 1 from all 7 day outputs
         │
         ▼
    Save & Display
```

## Generator Service

```ruby
module Briefing
  class Generator
    def call(start_date:, period_type:)
      briefing = find_or_initialize(start_date, period_type)
      return briefing if briefing.complete?

      briefing.update!(status: :generating)

      # 1. Ensure children exist (recursive)
      children = generate_children(start_date, period_type)

      # 2. Build input payload
      input = build_input(start_date, period_type, children)

      # 3. Run appropriate DSPy pipeline
      output = run_pipeline(period_type, input)

      # 4. Save and return
      briefing.update!(
        input_payload: input,
        output_payload: output,
        status: :complete,
        generated_at: Time.current
      )

      briefing
    end

    private

    def generate_children(start_date, period_type)
      return [] if period_type == 'day'

      child_dates(start_date, period_type).map do |date|
        call(start_date: date, period_type: child_type(period_type))
      end
    end

    def child_type(period_type)
      { 'week' => 'day', 'month' => 'week', 'quarter' => 'month', 'year' => 'quarter' }[period_type]
    end

    def child_dates(start_date, period_type)
      case period_type
      when 'week'
        (0..6).map { |i| start_date + i.days }
      when 'month'
        # Week start dates within the month
      when 'quarter'
        # Month start dates within the quarter
      when 'year'
        # Quarter start dates within the year
      end
    end
  end
end
```

## DSPy Signatures Needed

### Existing
- `Briefing::DailyBriefing` - Day level (current)

### New
- `Briefing::WeeklyBriefing` - Synthesize from 7 daily outputs
- `Briefing::MonthlyBriefing` - Synthesize from ~4 weekly outputs
- `Briefing::QuarterlyBriefing` - Synthesize from 3 monthly outputs
- `Briefing::YearlyBriefing` - Synthesize from 4 quarterly outputs

Each higher level should:
- Identify trends across the period
- Highlight standout days/weeks
- Provide longer-term perspective
- Adjust suggestion scope (weekly goals vs daily tasks)

## UI Components

### Navigation

```
Day view:    ◀ Mon  Tue  [Wed]  Thu  Fri ▶     [Week ↑]
Week view:   ◀ W1   W2   [W3]   W4  ▶          [Month ↑] [Day ↓]
Month view:  ◀ Jan  Feb  [Mar]  Apr ▶          [Quarter ↑] [Week ↓]
```

### States

1. **No briefing** → "Generate Briefing" button
2. **Generating** → Progress indicator
   - Day: Streaming output (current behavior)
   - Week+: Job progress ("Generating day 3/7...")
3. **Complete** → Show briefing + "Refresh" action
4. **Stale** → Warning badge: "3 days updated since generated"

### Staleness Detection

A parent briefing is stale when any child was generated after it:

```ruby
class Briefing < ApplicationRecord
  def stale?
    return false unless complete?

    children.any? { |child| child.generated_at > self.generated_at }
  end
end
```

## Implementation Order

### Phase 1: Persistence (Day Level)
1. [ ] Create `briefings` migration
2. [ ] Create `Briefing` model with status enum
3. [ ] Update `GenerateBriefingJob` to persist input/output
4. [ ] Update UI to show saved briefings
5. [ ] Add "Refresh" action for regeneration

### Phase 2: Day Navigation
1. [ ] Add date parameter to briefings controller
2. [ ] Navigation UI component (prev/next day)
3. [ ] Generate on-demand for missing days
4. [ ] Handle days with missing Garmin data

### Phase 3: Week Rollup
1. [ ] Create `Briefing::WeeklyBriefing` signature
2. [ ] Week input builder (aggregates daily outputs)
3. [ ] Cascade generation logic
4. [ ] Week navigation UI
5. [ ] Zoom in/out between day and week

### Phase 4: Month/Quarter/Year
1. [ ] Monthly signature and generation
2. [ ] Quarterly signature and generation
3. [ ] Yearly signature and generation
4. [ ] Full navigation hierarchy

### Phase 5: Polish
1. [ ] Staleness detection and warnings
2. [ ] Bulk regeneration (refresh week = refresh all days + week)
3. [ ] Background job queue for large regenerations
4. [ ] Caching and performance optimization

## Open Questions

1. **Week boundaries** - ISO weeks (Mon-Sun) or calendar display weeks?
2. **Missing data** - How to handle days with no Garmin data in rollups?
3. **Regeneration scope** - Refresh week = just week, or cascade to days too?
4. **Historical limit** - How far back can users navigate?
5. **Storage cost** - Compress old payloads? Archive after N months?

## Related Files

- `lib/briefing/daily_briefing.rb` - Current day-level signature
- `lib/briefing/types.rb` - Shared output types
- `app/jobs/generate_briefing_job.rb` - Current generation job
- `app/channels/briefing_channel.rb` - Streaming updates
