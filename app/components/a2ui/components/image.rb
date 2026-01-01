# typed: strict
# frozen_string_literal: true

module A2UI
  module Components
    class Image < Base
      extend T::Sig

      sig { params(component: A2UI::ImageComponent, surface_id: String, data: T::Hash[String, T.untyped]).void }
      def initialize(component:, surface_id:, data: {})
        @component = component
        super(surface_id: surface_id, data: data)
      end

      sig { returns(String) }
      def component_id
        @component.id
      end

      sig { returns(String) }
      def src
        resolve_value(@component.src)
      end

      sig { returns(String) }
      def alt
        @component.alt
      end

      sig { returns(String) }
      def fit_class
        case @component.fit
        when A2UI::ImageFit::Cover then 'object-cover'
        when A2UI::ImageFit::Fill then 'object-fill'
        when A2UI::ImageFit::ScaleDown then 'object-scale-down'
        when A2UI::ImageFit::None then 'object-none'
        else 'object-contain'
        end
      end
    end
  end
end
