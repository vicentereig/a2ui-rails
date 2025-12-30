# typed: strict
# frozen_string_literal: true

module A2UI
  module Components
    class TextField < Base
      extend T::Sig

      sig { params(component: A2UI::TextFieldComponent, surface_id: String, data: T::Hash[String, T.untyped]).void }
      def initialize(component:, surface_id:, data: {})
        @component = component
        super(surface_id: surface_id, data: data)
      end

      sig { returns(String) }
      def component_id
        @component.id
      end

      sig { returns(String) }
      def input_type
        case @component.input_type
        when A2UI::InputType::Number then 'number'
        when A2UI::InputType::Date then 'date'
        when A2UI::InputType::Email then 'email'
        when A2UI::InputType::Tel then 'tel'
        when A2UI::InputType::Url then 'url'
        else 'text'
        end
      end

      sig { returns(T::Boolean) }
      def textarea?
        @component.input_type == A2UI::InputType::Longtext
      end

      sig { returns(String) }
      def current_value
        get_path(@component.value.path).to_s
      end

      sig { returns(String) }
      def field_name
        @component.value.path.tr('/', '_').delete_prefix('_')
      end

      sig { returns(String) }
      def label
        @component.label
      end

      sig { returns(String) }
      def placeholder
        @component.placeholder
      end

      sig { returns(T::Boolean) }
      def required?
        @component.required
      end

      sig { returns(T::Hash[Symbol, String]) }
      def stimulus_attrs
        binding_attrs(@component.value.path)
      end
    end
  end
end
