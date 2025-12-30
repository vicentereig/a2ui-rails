# typed: strict
# frozen_string_literal: true

module A2UI
  module Components
    class Card < Base
      extend T::Sig

      sig do
        params(
          component: A2UI::CardComponent,
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
      def title
        @component.title
      end

      sig { returns(T.nilable(A2UI::Component)) }
      def child
        @components_lookup[@component.child_id]
      end

      sig { returns(String) }
      def css_class
        shadow = case @component.elevation
                 when 0 then ''
                 when 1 then 'shadow'
                 when 2 then 'shadow-md'
                 when 3 then 'shadow-lg'
                 else 'shadow-xl'
                 end

        "bg-white rounded-lg p-4 #{shadow}"
      end

      sig { returns(T::Hash[String, A2UI::Component]) }
      attr_reader :components_lookup
    end
  end
end
