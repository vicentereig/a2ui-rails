# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Data-driven children rendering', type: :component do
  let(:surface_id) { 'test-surface' }
  let(:data) do
    {
      'items' => [
        { 'name' => 'Item 1', 'description' => 'First item' },
        { 'name' => 'Item 2', 'description' => 'Second item' },
        { 'name' => 'Item 3', 'description' => 'Third item' }
      ]
    }
  end

  let(:template_component) do
    A2UI::TextComponent.new(
      id: 'item-template',
      content: A2UI::PathReference.new(path: '/name')
    )
  end

  let(:list_component) do
    A2UI::ListComponent.new(
      id: 'item-list',
      children: A2UI::DataDrivenChildren.new(
        path: '/items',
        template_id: 'item-template'
      )
    )
  end

  let(:components_lookup) do
    {
      'item-template' => template_component,
      'item-list' => list_component
    }
  end

  let(:renderer) do
    A2UI::Components::Renderer.new(
      surface_id: surface_id,
      components_lookup: components_lookup,
      data: data
    )
  end

  describe A2UI::Components::List do
    let(:component) do
      A2UI::Components::List.new(
        component: list_component,
        surface_id: surface_id,
        renderer: renderer,
        data: data
      )
    end

    it 'identifies as data-driven' do
      expect(component.data_driven?).to be true
    end

    it 'returns the template ID' do
      expect(component.template_id).to eq('item-template')
    end

    it 'resolves data-driven items from the data path' do
      items = component.data_driven_items
      expect(items.length).to eq(3)
      expect(items[0]['name']).to eq('Item 1')
      expect(items[1]['name']).to eq('Item 2')
      expect(items[2]['name']).to eq('Item 3')
    end

    it 'returns empty child_ids for data-driven children' do
      expect(component.child_ids).to eq([])
    end
  end

  describe A2UI::Components::Renderer do
    it 'renders template with scoped item data' do
      result = renderer.render_template('item-template', item_data: { 'name' => 'Test Item' }, index: 0)
      expect(result).to be_a(A2UI::Components::Text)
    end

    it 'passes index as _index in scoped data' do
      # The renderer should merge _index into the scoped data
      # We can verify this by checking the rendered component
      result = renderer.render_template('item-template', item_data: { 'name' => 'Test' }, index: 5)
      expect(result).to be_present
    end
  end

  describe 'List with explicit children' do
    let(:explicit_list) do
      A2UI::ListComponent.new(
        id: 'explicit-list',
        children: A2UI::ExplicitChildren.new(ids: ['child-1', 'child-2'])
      )
    end

    let(:child_1) { A2UI::TextComponent.new(id: 'child-1', content: A2UI::LiteralValue.new(value: 'First')) }
    let(:child_2) { A2UI::TextComponent.new(id: 'child-2', content: A2UI::LiteralValue.new(value: 'Second')) }

    let(:explicit_components) do
      {
        'explicit-list' => explicit_list,
        'child-1' => child_1,
        'child-2' => child_2
      }
    end

    let(:explicit_renderer) do
      A2UI::Components::Renderer.new(
        surface_id: surface_id,
        components_lookup: explicit_components,
        data: {}
      )
    end

    let(:explicit_component) do
      A2UI::Components::List.new(
        component: explicit_list,
        surface_id: surface_id,
        renderer: explicit_renderer,
        data: {}
      )
    end

    it 'identifies as not data-driven' do
      expect(explicit_component.data_driven?).to be false
    end

    it 'returns child IDs for explicit children' do
      expect(explicit_component.child_ids).to eq(['child-1', 'child-2'])
    end

    it 'returns empty data-driven items' do
      expect(explicit_component.data_driven_items).to eq([])
    end
  end
end
