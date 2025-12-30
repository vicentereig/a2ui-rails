# typed: strict
# frozen_string_literal: true

module A2UI
  class Alignment < T::Enum
    enums do
      Start = new('start')
      Center = new('center')
      End = new('end')
      Stretch = new('stretch')
    end
  end
end
