# typed: strict
# frozen_string_literal: true

module A2UI
  class ContextBinding < T::Struct
    const :key, String, description: 'Key name in the action context'
    const :path, String, description: 'JSON Pointer to extract value from'
  end
end
