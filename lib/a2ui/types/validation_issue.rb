# typed: strict
# frozen_string_literal: true

module A2UI
  class ValidationIssue < T::Struct
    const :path, String, description: 'JSON Pointer to invalid field'
    const :message, String
    const :code, String, description: 'Machine-readable code like required, invalid_format'
  end
end
