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
        when A2UI::SelectComponent
          Select.new(component: component, surface_id: surface_id, data: data)
        when A2UI::SliderComponent
          Slider.new(component: component, surface_id: surface_id, data: data)
        when A2UI::IconComponent
          Icon.new(component: component, surface_id: surface_id, data: data)
        when A2UI::ImageComponent
          Image.new(component: component, surface_id: surface_id, data: data)
        when A2UI::ListComponent
          renderer = new(surface_id: surface_id, components_lookup: components_lookup, data: data)
          List.new(component: component, surface_id: surface_id, data: data, renderer: renderer)
        # Editorial components
        when A2UI::EditorialHeadlineComponent
          EditorialHeadline.new(component: component, surface_id: surface_id, data: data)
        when A2UI::EditorialInsightComponent
          EditorialInsight.new(component: component, surface_id: surface_id, data: data)
        when A2UI::EditorialMetricComponent
          EditorialMetric.new(component: component, surface_id: surface_id, data: data)
        when A2UI::EditorialMetricsRowComponent
          EditorialMetricsRow.new(component: component, surface_id: surface_id, components_lookup: components_lookup, data: data)
        when A2UI::EditorialDividerComponent
          EditorialDivider.new(component: component, surface_id: surface_id, data: data)
        when A2UI::EditorialPageComponent
          EditorialPage.new(component: component, surface_id: surface_id, components_lookup: components_lookup, data: data)
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

      # Instance-based API for rendering child components
      sig do
        params(
          surface_id: String,
          components_lookup: T::Hash[String, A2UI::Component],
          data: T::Hash[String, T.untyped]
        ).void
      end
      def initialize(surface_id:, components_lookup:, data: {})
        @surface_id = surface_id
        @components_lookup = components_lookup
        @data = data
      end

      sig { params(id: String).returns(T.nilable(ViewComponent::Base)) }
      def render_by_id(id)
        component = @components_lookup[id]
        return nil unless component

        self.class.for(
          component,
          surface_id: @surface_id,
          components_lookup: @components_lookup,
          data: @data
        )
      end

      # Render a template component with scoped item data
      # Used for data-driven children where each item needs its own data context
      sig { params(id: String, item_data: T::Hash[String, T.untyped], index: Integer).returns(T.nilable(ViewComponent::Base)) }
      def render_template(id, item_data:, index:)
        component = @components_lookup[id]
        return nil unless component

        # Merge the item data at root level for path resolution
        # Paths in the template like "/name" will resolve to item_data["name"]
        scoped_data = item_data.merge('_index' => index)

        self.class.for(
          component,
          surface_id: @surface_id,
          components_lookup: @components_lookup,
          data: scoped_data
        )
      end
    end
  end
end
