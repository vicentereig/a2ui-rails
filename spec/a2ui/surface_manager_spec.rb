# frozen_string_literal: true

require 'spec_helper'

RSpec.describe A2UI::SurfaceManager do
  before(:all) do
    DSPy.configure do |c|
      c.lm = DSPy::LM.new('openai/gpt-4o-mini', api_key: ENV.fetch('OPENAI_API_KEY', 'test-key'))
    end
  end

  describe A2UI::Surface do
    subject(:surface) { A2UI::Surface.new('test-surface') }

    it 'initializes with empty state' do
      expect(surface.id).to eq('test-surface')
      expect(surface.root_id).to be_nil
      expect(surface.components).to be_empty
      expect(surface.data).to be_empty
    end

    it 'stores components by ID' do
      components = [
        A2UI::TextComponent.new(
          id: 'title',
          content: A2UI::LiteralValue.new(value: 'Hello')
        ),
        A2UI::ButtonComponent.new(
          id: 'btn',
          label: A2UI::LiteralValue.new(value: 'Click'),
          action: A2UI::Action.new(name: 'click')
        )
      ]

      surface.set_components('title', components)

      expect(surface.root_id).to eq('title')
      expect(surface.components['title']).to be_a(A2UI::TextComponent)
      expect(surface.components['btn']).to be_a(A2UI::ButtonComponent)
    end

    it 'applies data updates' do
      updates = [
        A2UI::DataUpdate.new(
          path: '/user',
          entries: [
            A2UI::StringValue.new(key: 'name', string: 'Alice'),
            A2UI::NumberValue.new(key: 'age', number: 30.0)
          ]
        )
      ]

      surface.apply_data_updates(updates)

      expect(surface.get_data('/user')).to eq({ 'name' => 'Alice', 'age' => 30.0 })
    end

    it 'handles nested data values' do
      updates = [
        A2UI::DataUpdate.new(
          path: '/config',
          entries: [
            A2UI::ObjectValue.new(
              key: 'settings',
              entries: [
                A2UI::BooleanValue.new(key: 'dark_mode', boolean: true),
                A2UI::StringValue.new(key: 'theme', string: 'ocean')
              ]
            )
          ]
        )
      ]

      surface.apply_data_updates(updates)

      config = surface.get_data('/config')
      expect(config['settings']['dark_mode']).to be true
      expect(config['settings']['theme']).to eq('ocean')
    end

    it 'serializes data to JSON' do
      surface.apply_data_updates([
        A2UI::DataUpdate.new(
          path: '/form',
          entries: [A2UI::StringValue.new(key: 'email', string: 'test@example.com')]
        )
      ])

      json = surface.to_json
      expect(JSON.parse(json)).to eq({ '/form' => { 'email' => 'test@example.com' } })
    end
  end

  describe 'full workflow', :vcr do
    subject(:manager) { A2UI::SurfaceManager.new }

    it 'creates and retrieves a surface' do
      surface = manager.create(
        surface_id: 'demo',
        request: 'Create a hello world message'
      )

      expect(surface).to be_a(A2UI::Surface)
      expect(surface.id).to eq('demo')
      expect(surface.root_id).not_to be_nil
      expect(surface.components).not_to be_empty

      retrieved = manager.get('demo')
      expect(retrieved).to eq(surface)
    end

    it 'updates an existing surface' do
      manager.create(
        surface_id: 'updatable',
        request: 'Create a simple text element'
      )

      result = manager.update(
        surface_id: 'updatable',
        request: 'Add a button below the text'
      )

      expect(result.streams).to be_an(Array)
    end

    it 'handles user actions' do
      manager.create(
        surface_id: 'actionable',
        request: 'Create a counter with increment button',
        data: '{"count": 0}'
      )

      action = A2UI::UserAction.new(
        name: 'increment',
        surface_id: 'actionable',
        source_id: 'inc-btn',
        context: { 'current' => '0' }
      )

      result = manager.handle_action(action: action)

      expect(result.response_type).to be_a(A2UI::ActionResponseType)
    end

    it 'deletes a surface' do
      manager.create(
        surface_id: 'temporary',
        request: 'Create a temp element'
      )

      expect(manager.get('temporary')).not_to be_nil

      manager.delete('temporary')

      expect(manager.get('temporary')).to be_nil
    end
  end
end
