# typed: strict
# frozen_string_literal: true

module A2UI
  class ColumnComponent < T::Struct
    const :id, String
    const :children, Children
    const :distribution, Distribution, default: Distribution::Start
    const :alignment, Alignment, default: Alignment::Stretch
    const :gap, Integer, default: 8
  end
end
