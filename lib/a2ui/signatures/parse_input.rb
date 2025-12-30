# typed: strict
# frozen_string_literal: true

module A2UI
  class ParseInput < DSPy::Signature
    description 'Convert natural language to data updates.'

    input do
      const :text, String, description: 'User natural language input'
      const :target_path, String, description: 'Path to update'
      const :expected_schema, String, default: '', description: 'Expected structure hint'
    end

    output do
      const :updates, T::Array[DataUpdate]
      const :confidence, Float, description: '0.0-1.0 confidence score'
      const :needs_clarification, T::Boolean
      const :question, String, default: '', description: 'Clarification question if needed'
    end
  end
end
