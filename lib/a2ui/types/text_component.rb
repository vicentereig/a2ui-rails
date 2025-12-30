# typed: strict
# frozen_string_literal: true

module A2UI
  class TextComponent < T::Struct
    const :id, String
    const :content, Value, description: 'Text content'
    const :usage_hint, TextUsageHint, default: TextUsageHint::Body
  end
end
