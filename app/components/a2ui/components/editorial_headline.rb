# typed: strict
# frozen_string_literal: true

module A2UI
  module Components
    class EditorialHeadline < Base
      extend T::Sig

      sig { params(component: A2UI::EditorialHeadlineComponent, surface_id: String, data: T::Hash[String, T.untyped]).void }
      def initialize(component:, surface_id:, data: {})
        @component = component
        super(surface_id: surface_id, data: data)
      end

      sig { returns(String) }
      def component_id
        @component.id
      end

      sig { returns(String) }
      def content
        resolve_value(@component.content)
      end
    end
  end
end
