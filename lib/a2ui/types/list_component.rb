# typed: strict
# frozen_string_literal: true

module A2UI
  class ListComponent < T::Struct
    const :id, String
    const :children, Children
    const :orientation, Orientation, default: Orientation::Vertical
  end
end
