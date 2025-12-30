# typed: strict
# frozen_string_literal: true

module A2UI
  class NumberValue < T::Struct
    const :key, String
    const :number, Float
  end
end
