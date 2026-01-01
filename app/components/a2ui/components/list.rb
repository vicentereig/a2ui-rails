# typed: strict
# frozen_string_literal: true

module A2UI
  module Components
    class List < Base
      extend T::Sig

      sig { params(component: A2UI::ListComponent, surface_id: String, data: T::Hash[String, T.untyped], renderer: Renderer).void }
      def initialize(component:, surface_id:, data: {}, renderer:)
        @component = component
        @renderer = renderer
        super(surface_id: surface_id, data: data)
      end

      sig { returns(String) }
      def component_id
        @component.id
      end

      sig { returns(T::Boolean) }
      def vertical?
        @component.orientation == A2UI::Orientation::Vertical
      end

      sig { returns(String) }
      def orientation_class
        vertical? ? 'flex-col space-y-2' : 'flex-row space-x-2'
      end

      sig { returns(T::Array[String]) }
      def child_ids
        case @component.children
        when A2UI::ExplicitChildren
          @component.children.ids
        when A2UI::DataDrivenChildren
          # Data-driven children would resolve from the data path
          []
        else
          []
        end
      end

      sig { returns(Renderer) }
      attr_reader :renderer
    end
  end
end
