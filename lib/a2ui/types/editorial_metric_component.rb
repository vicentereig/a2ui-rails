# typed: strict
# frozen_string_literal: true

module A2UI
  # Editorial metric component - renders with .editorial-metric styling
  # A single metric with label, value, optional trend and context
  class EditorialMetricComponent < T::Struct
    const :id, String
    const :label, String, description: 'Metric label (e.g., "HRV", "Sleep Score")'
    const :value, String, description: 'Formatted value with unit (e.g., "52ms", "85/100")'
    const :trend, T.nilable(Briefing::TrendDirection), default: nil,
      description: 'Trend direction (up, down, stable)'
    const :context, T.nilable(String), default: nil,
      description: 'Optional context (e.g., "up from 48ms last week")'
  end
end
