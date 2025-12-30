# typed: strict
# frozen_string_literal: true

module A2UI
  class DividerComponent < T::Struct
    const :id, String
    const :orientation, Orientation, default: Orientation::Horizontal
  end
end
