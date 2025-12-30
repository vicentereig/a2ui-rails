# typed: strict
# frozen_string_literal: true

module A2UI
  module Components
    # Maps A2UI component structs to ViewComponent instances
    class Renderer
      extend T::Sig

      sig do
        params(
          component: A2UI::Component,
          surface_id: String,
          components_lookup: T::Hash[String, A2UI::Component],
          data: T::Hash[String, T.untyped]
        ).returns(ViewComponent::Base)
      end
      def self.for(component, surface_id:, components_lookup:, data: {})
        case component
        when A2UI::TextComponent
          Text.new(component: component, surface_id: surface_id, data: data)
        when A2UI::ButtonComponent
          Button.new(component: component, surface_id: surface_id, data: data)
        when A2UI::TextFieldComponent
          TextField.new(component: component, surface_id: surface_id, data: data)
        when A2UI::RowComponent
          Row.new(component: component, surface_id: surface_id, components_lookup: components_lookup, data: data)
        when A2UI::ColumnComponent
          Column.new(component: component, surface_id: surface_id, components_lookup: components_lookup, data: data)
        when A2UI::CardComponent
          Card.new(component: component, surface_id: surface_id, components_lookup: components_lookup, data: data)
        when A2UI::CheckBoxComponent
          CheckBox.new(component: component, surface_id: surface_id, data: data)
        when A2UI::DividerComponent
          Divider.new(component: component, surface_id: surface_id, data: data)
        else
          Unsupported.new(component: component, surface_id: surface_id, data: data)
        end
      end

      sig do
        params(
          surface: A2UI::Surface
        ).returns(T.nilable(ViewComponent::Base))
      end
      def self.render_surface(surface)
        return nil unless surface.root_id

        root = surface.components[surface.root_id]
        return nil unless root

        self.for(
          root,
          surface_id: surface.id,
          components_lookup: surface.components,
          data: surface.data
        )
      end
    end
  end
end
