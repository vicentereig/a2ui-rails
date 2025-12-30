# typed: strict
# frozen_string_literal: true

module A2UI
  class LiteralValue < T::Struct
    const :value, String, description: 'The literal string value'
  end
end
