# typed: strict
# frozen_string_literal: true

module A2UI
  module Components
    class EditorialPage < Base
      extend T::Sig

      sig do
        params(
          component: A2UI::EditorialPageComponent,
          surface_id: String,
          components_lookup: T::Hash[String, A2UI::Component],
          data: T::Hash[String, T.untyped]
        ).void
      end
      def initialize(component:, surface_id:, components_lookup:, data: {})
        @component = component
        @components_lookup = components_lookup
        super(surface_id: surface_id, data: data)
      end

      sig { returns(String) }
      def component_id
        @component.id
      end

      sig { returns(String) }
      def tone
        @component.tone.serialize
      end

      sig { returns(T::Array[String]) }
      def child_ids
        case @component.children
        when A2UI::ExplicitChildren then @component.children.ids
        else []
        end
      end

      sig { returns(T::Hash[String, A2UI::Component]) }
      attr_reader :components_lookup
    end
  end
end
