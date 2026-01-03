# typed: strict
# frozen_string_literal: true

module A2UI
  module Components
    class EditorialInsight < Base
      extend T::Sig

      sig { params(component: A2UI::EditorialInsightComponent, surface_id: String, data: T::Hash[String, T.untyped]).void }
      def initialize(component:, surface_id:, data: {})
        @component = component
        super(surface_id: surface_id, data: data)
      end

      sig { returns(String) }
      def component_id
        @component.id
      end

      sig { returns(String) }
      def what
        @component.what
      end

      sig { returns(String) }
      def so_what
        @component.so_what
      end

      sig { returns(String) }
      def now_what
        @component.now_what
      end
    end
  end
end
