# typed: strict
# frozen_string_literal: true

module A2UI
  class Orientation < T::Enum
    enums do
      Horizontal = new('horizontal')
      Vertical = new('vertical')
    end
  end
end
