# typed: strict
# frozen_string_literal: true

module A2UI
  class ScreenSize < T::Enum
    enums do
      Mobile = new('mobile')
      Tablet = new('tablet')
      Desktop = new('desktop')
    end
  end
end
