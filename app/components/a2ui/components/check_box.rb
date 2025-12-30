# typed: strict
# frozen_string_literal: true

module A2UI
  module Components
    class CheckBox < Base
      extend T::Sig

      sig { params(component: A2UI::CheckBoxComponent, surface_id: String, data: T::Hash[String, T.untyped]).void }
      def initialize(component:, surface_id:, data: {})
        @component = component
        super(surface_id: surface_id, data: data)
      end

      sig { returns(String) }
      def component_id
        @component.id
      end

      sig { returns(String) }
      def label
        @component.label
      end

      sig { returns(T::Boolean) }
      def checked?
        value = get_path(@component.checked.path)
        value == true || value == 'true'
      end

      sig { returns(String) }
      def field_name
        @component.checked.path.tr('/', '_').delete_prefix('_')
      end

      sig { returns(T::Hash[Symbol, String]) }
      def stimulus_attrs
        binding_attrs(@component.checked.path)
      end
    end
  end
end
