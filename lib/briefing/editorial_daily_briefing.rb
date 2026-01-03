# typed: strict
# frozen_string_literal: true

module Briefing
  # Editorial-style daily briefing using What/So What/Now What framework
  #
  # This signature generates a short editorial that uncovers hidden patterns
  # in health data, rather than just describing visible metrics.
  class EditorialDailyBriefing < DSPy::Signature
    description <<~DESC
      Generate a short editorial briefing that uncovers hidden patterns in health data.

      Focus on what the data DOESN'T obviously show—contradictions, paradoxes, and
      emerging patterns that require interpretation. Use the What/So What/Now What
      framework to structure the insight.

      The headline should be compelling and reveal the core insight, not just
      describe the data. Write like a health journalist, not a dashboard.
    DESC

    input do
      const :date, String,
        description: 'Briefing date (YYYY-MM-DD)'
      const :health_summary, String,
        description: '7-day health data: sleep, HRV, recovery, stress patterns'
      const :activity_summary, String,
        description: '7-day activity data: workouts, volume, intensity'
      const :performance_summary, String,
        description: 'Current fitness metrics: VO2 Max, training status, trends'
      const :detected_anomalies, String,
        description: 'Pre-detected anomalies and contradictions in the data'
    end

    output do
      const :briefing, EditorialBriefingOutput,
        description: 'The editorial briefing with headline, insight, and supporting metrics'
    end
  end
end
