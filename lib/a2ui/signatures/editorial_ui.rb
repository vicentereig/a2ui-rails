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
      Transform editorial narrative content into A2UI visual components.

      You are designing the layout for a daily editorial briefing about personal health and fitness.
      The input contains pre-interpreted narratives (prose, not raw numbers) about:
      - Health patterns: sleep quality, recovery state, stress context
      - Activity patterns: training volume, intensity, consistency
      - Performance trends: fitness trajectory, aerobic state, training readiness
      - Detected anomalies: hidden patterns worth highlighting

      Create a visually engaging layout using these component types:
      - TextComponent: For headlines (h1), section headers (h2/h3), and body text
      - CardComponent: To group related content with visual elevation
      - ColumnComponent: For vertical stacking with configurable gaps
      - RowComponent: For horizontal layouts
      - DividerComponent: To separate sections

      LAYOUT GUIDELINES:
      1. Start with a striking headline (h1) that captures the day's key insight
      2. Use the "What / So What / Now What" structure as three distinct sections
      3. Each section should be in a Card with a subtle header
      4. Include 2-3 supporting metrics as compact info blocks
      5. Keep the overall layout clean and scannable

      Component IDs should be descriptive (e.g., "headline", "what-card", "metric-sleep").
      Use ExplicitChildren with ids array for ColumnComponent/RowComponent children.
      Use LiteralValue with value string for TextComponent content.
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
