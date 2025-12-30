# typed: strict
# frozen_string_literal: true

module A2UI
  module Components
    class Text < Base
      extend T::Sig

      sig { params(component: A2UI::TextComponent, surface_id: String, data: T::Hash[String, T.untyped]).void }
      def initialize(component:, surface_id:, data: {})
        @component = component
        super(surface_id: surface_id, data: data)
      end

      sig { returns(String) }
      def tag_name
        case @component.usage_hint
        when A2UI::TextUsageHint::H1 then 'h1'
        when A2UI::TextUsageHint::H2 then 'h2'
        when A2UI::TextUsageHint::H3 then 'h3'
        when A2UI::TextUsageHint::H4 then 'h4'
        when A2UI::TextUsageHint::H5 then 'h5'
        when A2UI::TextUsageHint::Caption then 'span'
        else 'p'
        end
      end

      sig { returns(String) }
      def css_class
        case @component.usage_hint
        when A2UI::TextUsageHint::H1 then 'text-4xl font-bold'
        when A2UI::TextUsageHint::H2 then 'text-3xl font-bold'
        when A2UI::TextUsageHint::H3 then 'text-2xl font-semibold'
        when A2UI::TextUsageHint::H4 then 'text-xl font-semibold'
        when A2UI::TextUsageHint::H5 then 'text-lg font-medium'
        when A2UI::TextUsageHint::Caption then 'text-sm text-gray-500'
        else 'text-base'
        end
      end

      sig { returns(String) }
      def content
        resolve_value(@component.content)
      end

      sig { returns(String) }
      def component_id
        @component.id
      end
    end
  end
end
