# typed: strict
# frozen_string_literal: true

module A2UI
  module Components
    class List < Base
      extend T::Sig

      sig { params(component: A2UI::ListComponent, surface_id: String, renderer: Renderer, data: T::Hash[String, T.untyped]).void }
      def initialize(component:, surface_id:, renderer:, data: {})
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
          # For data-driven, return empty - use data_driven_items instead
          []
        else
          []
        end
      end

      sig { returns(T::Boolean) }
      def data_driven?
        @component.children.is_a?(A2UI::DataDrivenChildren)
      end

      sig { returns(T.nilable(String)) }
      def template_id
        return nil unless data_driven?

        @component.children.template_id
      end

      sig { returns(T::Array[T::Hash[String, T.untyped]]) }
      def data_driven_items
        return [] unless data_driven?

        children = @component.children
        return [] unless children.is_a?(A2UI::DataDrivenChildren)

        path = children.path
        items = resolve_path(path, @data)
        items.is_a?(Array) ? items : []
      end

      private

      sig { params(path: String, obj: T.untyped).returns(T.untyped) }
      def resolve_path(path, obj)
        return obj if path.nil? || path == '' || path == '/'

        parts = path.split('/').reject(&:empty?)
        parts.reduce(obj) { |current, part| current.is_a?(Hash) ? current[part] : nil }
      end

      sig { returns(Renderer) }
      attr_reader :renderer
    end
  end
end
