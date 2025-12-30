# typed: strict
# frozen_string_literal: true

module A2UI
  class CheckBoxComponent < T::Struct
    const :id, String
    const :checked, PathReference, description: 'Path to boolean in data model'
    const :label, String, default: ''
  end
end
