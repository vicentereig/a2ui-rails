# typed: strict
# frozen_string_literal: true

module A2UI
  class IconComponent < T::Struct
    const :id, String
    const :name, String, description: 'Material icon name (e.g., check, close, menu)'
    const :size, Integer, default: 24
  end
end
