# typed: strict
# frozen_string_literal: true

module A2UI
  module Components
    class EditorialDivider < Base
      extend T::Sig

      sig { params(component: A2UI::EditorialDividerComponent, surface_id: String, data: T::Hash[String, T.untyped]).void }
      def initialize(component:, surface_id:, data: {})
        @component = component
        super(surface_id: surface_id, data: data)
      end

      sig { returns(String) }
      def component_id
        @component.id
      end
    end
  end
end
