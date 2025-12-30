# typed: strict
# frozen_string_literal: true

module A2UI
  module Components
    class Column < Base
      extend T::Sig

      sig do
        params(
          component: A2UI::ColumnComponent,
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
      def css_class
        classes = ['flex', 'flex-col']
        classes << distribution_class
        classes << alignment_class
        classes << "gap-#{[@component.gap / 4, 1].max}"
        classes.join(' ')
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

      private

      sig { returns(String) }
      def distribution_class
        case @component.distribution
        when A2UI::Distribution::Center then 'justify-center'
        when A2UI::Distribution::End then 'justify-end'
        when A2UI::Distribution::SpaceBetween then 'justify-between'
        when A2UI::Distribution::SpaceAround then 'justify-around'
        when A2UI::Distribution::SpaceEvenly then 'justify-evenly'
        else 'justify-start'
        end
      end

      sig { returns(String) }
      def alignment_class
        case @component.alignment
        when A2UI::Alignment::Start then 'items-start'
        when A2UI::Alignment::Center then 'items-center'
        when A2UI::Alignment::End then 'items-end'
        else 'items-stretch'
        end
      end
    end
  end
end
