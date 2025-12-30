# typed: strict
# frozen_string_literal: true

module A2UI
  class BooleanValue < T::Struct
    const :key, String
    const :boolean, T::Boolean
  end
end
