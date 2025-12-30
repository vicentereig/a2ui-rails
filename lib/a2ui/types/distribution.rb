# typed: strict
# frozen_string_literal: true

module A2UI
  class Distribution < T::Enum
    enums do
      Start = new('start')
      Center = new('center')
      End = new('end')
      SpaceBetween = new('space_between')
      SpaceAround = new('space_around')
      SpaceEvenly = new('space_evenly')
    end
  end
end
