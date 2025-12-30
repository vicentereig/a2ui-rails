# typed: strict
# frozen_string_literal: true

module A2UI
  class ImageComponent < T::Struct
    const :id, String
    const :src, Value, description: 'Image URL'
    const :alt, String, default: ''
    const :fit, ImageFit, default: ImageFit::Contain
  end
end
