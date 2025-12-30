# typed: strict
# frozen_string_literal: true

module A2UI
  class SliderComponent < T::Struct
    const :id, String
    const :value, PathReference, description: 'Path to numeric value'
    const :min, Float, default: 0.0
    const :max, Float, default: 100.0
    const :step, Float, default: 1.0
    const :label, String, default: ''
  end
end
