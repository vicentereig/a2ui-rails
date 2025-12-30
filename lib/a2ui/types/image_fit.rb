# typed: strict
# frozen_string_literal: true

module A2UI
  class ImageFit < T::Enum
    enums do
      Contain = new('contain')
      Cover = new('cover')
      Fill = new('fill')
      ScaleDown = new('scale_down')
      None = new('none')
    end
  end
end
