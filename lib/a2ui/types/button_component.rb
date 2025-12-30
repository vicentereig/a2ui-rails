# typed: strict
# frozen_string_literal: true

module A2UI
  class ButtonComponent < T::Struct
    const :id, String
    const :label, Value, description: 'Button label text'
    const :action, Action
    const :disabled, T::Boolean, default: false
    const :variant, String, default: 'primary', description: 'primary, secondary, or danger'
  end
end
