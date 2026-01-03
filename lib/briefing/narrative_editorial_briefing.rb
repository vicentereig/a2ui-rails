# typed: strict
# frozen_string_literal: true

module Briefing
  # Narrative editorial briefing using What/So What/Now What framework
  #
  # This signature receives pre-interpreted narrative context (not raw numbers)
  # and generates prose-only output. Numbers belong in supporting_metrics only.
  class NarrativeEditorialBriefing < DSPy::Signature
    description <<~DESC
      Generate an editorial briefing as a health journalist would write it.

      CRITICAL: Your narrative output must contain NO NUMBERS.
      - Numbers belong ONLY in the supporting_metrics field
      - The headline, what, so_what, and now_what fields are PROSE ONLY

      Bad examples (DO NOT write like this):
      - "Your HRV averaged 52ms this week" (contains number)
      - "Sleep score of 85/100 indicates..." (contains number)
      - "You ran 42km across 4 sessions" (contains numbers)
      - "VO2 Max improved by 2 points" (contains number)

      Good examples (write like this):
      - "Your nervous system is finding its rhythm after last week's strain"
      - "Sleep quality has been consistently restorative"
      - "Training volume was moderate with good distribution"
      - "Aerobic fitness continues its upward climb"

      Write like a thoughtful coach interpreting patterns, not a dashboard reporting data.
      Focus on what the patterns MEAN, not what the numbers ARE.
    DESC

    input do
      const :date, String,
        description: 'Briefing date (YYYY-MM-DD)'
      const :health, HealthNarrative,
        description: 'Pre-interpreted health patterns (already in narrative form)'
      const :activity, ActivityNarrative,
        description: 'Pre-interpreted activity patterns (already in narrative form)'
      const :performance, PerformanceNarrative,
        description: 'Pre-interpreted performance trends (already in narrative form)'
      const :detected_patterns, T::Array[DetectedPattern], default: [],
        description: 'Hidden patterns and contradictions worth highlighting'
    end

    output do
      const :headline, String,
        description: 'Compelling headline revealing the insight (8-12 words, NO NUMBERS)'
      const :insight, NarrativeInsight,
        description: 'The What/So What/Now What analysis (all prose, NO NUMBERS)'
      const :supporting_metrics, T::Array[SupportingMetric],
        description: 'The 2-3 key numbers that support your narrative (numbers go HERE)'
      const :tone, Sentiment
    end
  end
end
