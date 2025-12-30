# typed: strict
# frozen_string_literal: true

module A2UI
  class ValidateData < DSPy::Signature
    description 'Validate data model against rules.'

    input do
      const :data, String, description: 'Data model as JSON'
      const :rules, String, description: 'Validation rules'
    end

    output do
      const :valid, T::Boolean
      const :issues, T::Array[ValidationIssue], default: []
    end
  end
end
