# typed: strict
# frozen_string_literal: true

module A2UI
  module Components
    class Button < Base
      extend T::Sig

      sig { params(component: A2UI::ButtonComponent, surface_id: String, data: T::Hash[String, T.untyped]).void }
      def initialize(component:, surface_id:, data: {})
        @component = component
        super(surface_id: surface_id, data: data)
      end

      sig { returns(String) }
      def label
        resolve_value(@component.label)
      end

      sig { returns(String) }
      def component_id
        @component.id
      end

      sig { returns(T::Boolean) }
      def disabled?
        @component.disabled
      end

      sig { returns(String) }
      def css_class
        base = 'px-4 py-2 rounded-md font-medium transition-colors focus:outline-none focus:ring-2'

        variant = case @component.variant
                  when 'secondary' then 'bg-gray-200 text-gray-800 hover:bg-gray-300 focus:ring-gray-400'
                  when 'danger' then 'bg-red-600 text-white hover:bg-red-700 focus:ring-red-400'
                  else 'bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-400'
                  end

        disabled = @component.disabled ? 'opacity-50 cursor-not-allowed' : ''

        [base, variant, disabled].reject(&:empty?).join(' ')
      end

      sig { returns(T::Hash[Symbol, String]) }
      def stimulus_attrs
        action_attrs(@component.action)
      end
    end
  end
end
