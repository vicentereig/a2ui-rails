# typed: strict
# frozen_string_literal: true

module A2UI
  # Evidence span for UI decision making - tracks why components/layouts were chosen
  class UIDecisionEvidence < T::Struct
    const :decision_type, UIDecisionType, description: 'Category of decision'
    const :component_id, T.nilable(String), default: nil, description: 'ID of component this decision affects'
    const :choice, String, description: 'What was chosen (e.g., "Card", "Column layout", "path binding")'
    const :rationale, String, description: 'Why this choice was made (1-2 sentences)'
    const :alternatives_considered, T::Array[String], default: [], description: 'Other options that were considered'
  end
end
