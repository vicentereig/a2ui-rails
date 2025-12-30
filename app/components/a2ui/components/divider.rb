# typed: strict
# frozen_string_literal: true

module A2UI
  module Components
    class Divider < Base
      extend T::Sig

      sig { params(component: A2UI::DividerComponent, surface_id: String, data: T::Hash[String, T.untyped]).void }
      def initialize(component:, surface_id:, data: {})
        @component = component
        super(surface_id: surface_id, data: data)
      end

      sig { returns(String) }
      def component_id
        @component.id
      end

      sig { returns(T::Boolean) }
      def horizontal?
        @component.orientation == A2UI::Orientation::Horizontal
      end

      sig { returns(String) }
      def css_class
        if horizontal?
          'border-t border-gray-200 my-4'
        else
          'border-l border-gray-200 mx-4 self-stretch'
        end
      end
    end
  end
end
