# typed: strict
# frozen_string_literal: true

module A2UI
  # Generates A2UI components for editorial briefings
  #
  # Unlike GenerateUI which takes natural language requests, this signature
  # takes structured narrative inputs (pre-interpreted health, activity, and
  # performance patterns) and produces a visual component layout.
  #
  # The LLM acts as a layout designer, transforming prose narratives into
  # a component hierarchy suitable for the editorial briefing format.
  class EditorialUI < DSPy::Signature
    description <<~DESC
      Create an editorial briefing layout using specialized editorial components.

      AVAILABLE COMPONENTS:
      - EditorialPageComponent: Root container with tone (positive/neutral/warning)
      - EditorialHeadlineComponent: Main headline (serif font, large, 8-12 words)
      - EditorialInsightComponent: The What/So What/Now What prose body
      - EditorialMetricsRowComponent: Container for 2-3 metrics
      - EditorialMetricComponent: Single metric with label, value, trend, context
      - EditorialDividerComponent: Horizontal rule between sections
      - ColumnComponent: For vertical stacking (use gap: 0 for editorial spacing)

      REQUIRED STRUCTURE:
      1. EditorialPageComponent (root, id: "editorial-root", set tone based on content)
         2. ColumnComponent (id: "content-column", gap: 0)
            3. EditorialHeadlineComponent (id: "headline")
            4. EditorialInsightComponent (id: "insight")
            5. EditorialDividerComponent (id: "divider")
            6. EditorialMetricsRowComponent (id: "metrics-row")
               - EditorialMetricComponent (id: "metric-1")
               - EditorialMetricComponent (id: "metric-2")
               - EditorialMetricComponent (id: "metric-3") [optional]

      CONTENT GUIDELINES:
      - HEADLINE: 8-12 words capturing the day's key insight. NO NUMBERS in headline.
      - INSIGHT: what = observable pattern, so_what = why it matters, now_what = action.
        All prose narratives. NO NUMBERS in the insight text.
      - METRICS: 2-3 metrics that support the headline. Numbers go HERE only.
        Use trend (up/down/stable) and context for additional detail.

      TONE: Set EditorialPageComponent.tone based on overall assessment:
      - positive: strong recovery, good sleep, productive training
      - warning: concerning patterns, recovery debt, overreaching
      - neutral: mixed signals, maintenance phase

      Use ExplicitChildren with ids array for container children.
      Use LiteralValue with value string for EditorialHeadlineComponent content.
    DESC

    input do
      const :surface_id, String,
        description: 'Surface identifier for the editorial briefing'
      const :date, String,
        description: 'Briefing date (YYYY-MM-DD)'
      const :health, Briefing::HealthNarrative,
        description: 'Pre-interpreted health patterns (prose, not numbers)'
      const :activity, Briefing::ActivityNarrative,
        description: 'Pre-interpreted activity patterns (prose, not numbers)'
      const :performance, Briefing::PerformanceNarrative,
        description: 'Pre-interpreted performance trends (prose, not numbers)'
      const :detected_patterns, T::Array[Briefing::DetectedPattern], default: [],
        description: 'Anomalies and hidden patterns worth highlighting'
    end

    output do
      const :root_id, String,
        description: 'ID of the root component (usually a ColumnComponent)'
      const :components, T::Array[Component],
        description: 'All components in the layout (adjacency list)'
      const :initial_data, T::Array[DataUpdate], default: [],
        description: 'Initial data bindings (typically empty for editorial)'
    end
  end
end
