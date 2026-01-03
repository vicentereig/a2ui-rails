# typed: strict
# frozen_string_literal: true

module A2UI
  # Editorial page component - renders with .editorial-page styling
  # Root container for editorial briefings with tone indicator
  class EditorialPageComponent < T::Struct
    const :id, String
    const :tone, Briefing::Sentiment, default: Briefing::Sentiment::Neutral,
      description: 'Overall tone (positive, neutral, warning)'
    const :children, Children, description: 'ExplicitChildren with content component IDs'
  end
end
