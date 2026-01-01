# Daily Briefing Schema

This document describes the input and output schema for the AI-generated daily health briefing.

## Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         DailyBriefing Signature                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  INPUT                              OUTPUT                                  │
│  ─────                              ──────                                  │
│  • user_name: String                • greeting: String                      │
│  • date: String                     • insights: InsightBlock[]              │
│  • health_context: String           • suggestions: Suggestion[]             │
│  • activity_context: String                                                 │
│  • performance_context: String                                              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Input Schema

| Field | Type | Description |
|-------|------|-------------|
| `user_name` | String | Name of the user for personalization |
| `date` | String | Date of the briefing (YYYY-MM-DD) |
| `health_context` | String | Summary of sleep, HRV, stress, and recovery data |
| `activity_context` | String | Summary of recent activities and training |
| `performance_context` | String | Summary of fitness metrics and training status |

### Example Input

```json
{
  "user_name": "Runner",
  "date": "2024-12-31",
  "health_context": "Sleep: 7.5h (score 85), HRV: 52ms (balanced), Stress: 28 avg, Body Battery: 75→45",
  "activity_context": "Recent: 5km run (28:30), Week: 3 activities, 15km total",
  "performance_context": "VO2max: 48, Training load: optimal, Recovery: 24h"
}
```

## Output Schema

### Root Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `greeting` | String | Yes | Warm personalized greeting |
| `insights` | InsightBlock[] | Yes | Meaningful health/fitness insights |
| `suggestions` | Suggestion[] | Yes | Actionable suggestions |

### InsightBlock

Represents a single insight about the user's health or fitness.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `icon` | String | Yes | - | Single emoji icon for the category |
| `headline` | String | Yes | - | Compelling headline that captures attention |
| `narrative` | String | Yes | - | Clear explanation connecting data to meaning |
| `sentiment` | Sentiment | Yes | - | Overall sentiment |
| `metrics` | MetricItem[] | No | `[]` | Key metrics to display inline |

### MetricItem

A single metric with optional trend indicator.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `label` | String | Yes | - | Short label (e.g., "Sleep", "HRV") |
| `value` | String | Yes | - | Value with unit (e.g., "7.5h", "52ms") |
| `trend` | TrendDirection | No | `null` | Optional trend direction |

### Suggestion

An actionable recommendation for the user.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `title` | String | Yes | - | Direct action-oriented title |
| `body` | String | Yes | - | Specific actionable advice with clear next steps |
| `icon` | String | No | `"💡"` | Single emoji icon |
| `suggestion_type` | SuggestionType | Yes | - | Category of suggestion |

## Enums

### Sentiment

Controls the visual styling of insight blocks.

| Value | Description |
|-------|-------------|
| `positive` | Good news, achievements, improvements |
| `neutral` | Informational, no action needed |
| `warning` | Needs attention, potential issue |

### SuggestionType

Categorizes suggestions for filtering/grouping.

| Value | Description |
|-------|-------------|
| `general` | General health/wellness advice |
| `recovery` | Rest and recovery recommendations |
| `intensity` | Training intensity guidance |

### TrendDirection

Shows metric trends over time.

| Value | Description |
|-------|-------------|
| `up` | Increasing trend (↑) |
| `down` | Decreasing trend (↓) |
| `stable` | No significant change (→) |

## Example Output

```json
{
  "greeting": "Good morning, Runner!",
  "insights": [
    {
      "icon": "😴",
      "headline": "Solid Recovery Night",
      "narrative": "Your sleep quality supported good recovery.",
      "sentiment": "positive",
      "metrics": [
        { "label": "Sleep", "value": "7.5h", "trend": "stable" },
        { "label": "Score", "value": "85", "trend": "up" },
        { "label": "HRV", "value": "52ms" }
      ]
    },
    {
      "icon": "⚡",
      "headline": "Training Load Balanced",
      "narrative": "Your weekly volume is in the optimal range.",
      "sentiment": "positive",
      "metrics": [
        { "label": "Week", "value": "15km" },
        { "label": "Load", "value": "optimal" }
      ]
    },
    {
      "icon": "💓",
      "headline": "Stress Well Managed",
      "narrative": "Low average stress indicates good balance.",
      "sentiment": "neutral",
      "metrics": [
        { "label": "Avg", "value": "28" },
        { "label": "Battery", "value": "45", "trend": "down" }
      ]
    }
  ],
  "suggestions": [
    {
      "title": "Push Today",
      "body": "Your recovery supports a harder workout.",
      "icon": "🏃",
      "suggestion_type": "intensity"
    },
    {
      "title": "Hydrate Well",
      "body": "Drink extra water to support your training.",
      "icon": "💧",
      "suggestion_type": "general"
    }
  ]
}
```

## Component Mapping

Use this schema to design UI components:

| Schema Type | Component | Props |
|-------------|-----------|-------|
| Root | `BriefingCard` | greeting, children |
| InsightBlock | `InsightCard` | icon, headline, narrative, sentiment, metrics |
| MetricItem | `MetricPill` | label, value, trend |
| Suggestion | `SuggestionCard` | title, body, icon, type |

### Suggested Visual Hierarchy

```
┌─────────────────────────────────────────────┐
│ 👋 Good morning, Runner!                    │  ← greeting
├─────────────────────────────────────────────┤
│                                             │
│ 😴 Solid Recovery Night                     │  ← InsightBlock
│ Your sleep quality supported good recovery. │
│ ┌─────────┐ ┌─────────┐ ┌─────────┐        │
│ │Sleep 7.5h│ │Score 85↑│ │HRV 52ms │        │  ← MetricItem[]
│ └─────────┘ └─────────┘ └─────────┘        │
│                                             │
│ ⚡ Training Load Balanced                   │  ← InsightBlock
│ Your weekly volume is in the optimal range. │
│ ┌─────────┐ ┌───────────┐                  │
│ │Week 15km │ │Load optimal│                  │  ← MetricItem[]
│ └─────────┘ └───────────┘                  │
│                                             │
├─────────────────────────────────────────────┤
│ 🏃 Push Today                               │  ← Suggestion
│ Your recovery supports a harder workout.    │
│                                             │
│ 💧 Hydrate Well                             │  ← Suggestion
│ Drink extra water to support your training. │
└─────────────────────────────────────────────┘
```

## JSON Schema

See [briefing-schema.json](./briefing-schema.json) for the complete JSON Schema definition.
