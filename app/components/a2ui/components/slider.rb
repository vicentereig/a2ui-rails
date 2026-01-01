# typed: strict
# frozen_string_literal: true

module A2UI
  module Components
    class Slider < Base
      extend T::Sig

      sig { params(component: A2UI::SliderComponent, surface_id: String, data: T::Hash[String, T.untyped]).void }
      def initialize(component:, surface_id:, data: {})
        @component = component
        super(surface_id: surface_id, data: data)
      end

      sig { returns(String) }
      def component_id
        @component.id
      end

      sig { returns(Float) }
      def current_value
        val = get_path(@component.value.path)
        val.is_a?(Numeric) ? val.to_f : @component.min
      end

      sig { returns(Float) }
      def min
        @component.min
      end

      sig { returns(Float) }
      def max
        @component.max
      end

      sig { returns(Float) }
      def step
        @component.step
      end

      sig { returns(String) }
      def label
        @component.label
      end

      sig { returns(T::Hash[Symbol, String]) }
      def stimulus_attrs
        binding_attrs(@component.value.path)
      end
    end
  end
end
