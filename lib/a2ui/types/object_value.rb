# typed: strict
# frozen_string_literal: true

module A2UI
  class ObjectValue < T::Struct
    const :key, String
    const :entries, T::Hash[String, T.untyped], default: {}, description: 'Nested key-value pairs as JSON-like hash'
  end
end
