# typed: strict
# frozen_string_literal: true

module A2UI
  class TextFieldComponent < T::Struct
    const :id, String
    const :value, PathReference, description: 'Path to bound value in data model'
    const :input_type, InputType, default: InputType::Text
    const :label, String, default: ''
    const :placeholder, String, default: ''
    const :is_required, T::Boolean, default: false, description: 'Whether the field is required'
  end
end
