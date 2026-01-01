# typed: strict
# frozen_string_literal: true

module A2UI
  module Components
    class Select < Base
      extend T::Sig

      sig { params(component: A2UI::SelectComponent, surface_id: String, data: T::Hash[String, T.untyped]).void }
      def initialize(component:, surface_id:, data: {})
        @component = component
        super(surface_id: surface_id, data: data)
      end

      sig { returns(String) }
      def component_id
        @component.id
      end

      sig { returns(String) }
      def current_value
        get_path(@component.value.path).to_s
      end

      sig { returns(T::Array[T::Hash[String, String]]) }
      def options
        opts = get_path(@component.options_path.path)
        return [] unless opts.is_a?(Array)

        opts.map do |opt|
          case opt
          when Hash
            { 'value' => opt['value'].to_s, 'label' => opt['label'].to_s }
          else
            { 'value' => opt.to_s, 'label' => opt.to_s }
          end
        end
      end

      sig { returns(String) }
      def label
        @component.label
      end

      sig { returns(String) }
      def placeholder
        @component.placeholder
      end

      sig { returns(T::Hash[Symbol, String]) }
      def stimulus_attrs
        binding_attrs(@component.value.path)
      end
    end
  end
end
