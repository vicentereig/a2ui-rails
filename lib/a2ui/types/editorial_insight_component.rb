# typed: strict
# frozen_string_literal: true

module A2UI
  # Editorial insight component - renders with .editorial-insight styling
  # The What/So What/Now What prose body
  class EditorialInsightComponent < T::Struct
    const :id, String
    const :what, String, description: 'Observable pattern from data (1-2 sentences, no numbers)'
    const :so_what, String, description: 'Why this matters - the interpretation (1-2 sentences, no numbers)'
    const :now_what, String, description: 'Actionable recommendation (1 sentence)'
  end
end
