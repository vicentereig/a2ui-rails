# typed: strict
# frozen_string_literal: true

module A2UI
  class SelectComponent < T::Struct
    const :id, String
    const :value, PathReference, description: 'Path to selected value'
    const :options_path, PathReference, description: 'Path to array of {value, label} options'
    const :label, String, default: ''
    const :placeholder, String, default: 'Select...'
  end
end
