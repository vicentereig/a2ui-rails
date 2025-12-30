# frozen_string_literal: true

require 'spec_helper'

RSpec.describe A2UI::GenerateUI do
  before(:all) do
    # Configure DSPy - users would choose their provider
    # Uncomment one of these and add the corresponding gem:
    # gem 'dspy-openai'
    # gem 'dspy-anthropic'
    # gem 'dspy-gemini'

    DSPy.configure do |c|
      c.lm = DSPy::LM.new('openai/gpt-4o-mini', api_key: ENV.fetch('OPENAI_API_KEY', 'test-key'))
    end
  end

  describe 'signature structure' do
    it 'has correct input schema' do
      schema = A2UI::GenerateUI.input_json_schema

      expect(schema[:properties]).to have_key(:request)
      expect(schema[:properties]).to have_key(:surface_id)
      expect(schema[:properties]).to have_key(:available_data)
      expect(schema[:required]).to include('request', 'surface_id')
    end

    it 'has correct output schema with Component union' do
      schema = A2UI::GenerateUI.output_json_schema

      expect(schema[:properties]).to have_key(:root_id)
      expect(schema[:properties]).to have_key(:components)
      expect(schema[:properties]).to have_key(:initial_data)
    end
  end

  describe 'UI generation', :vcr do
    let(:generator) { A2UI::UIGenerator.new }

    it 'generates a booking form' do
      result = generator.call(
        request: 'Create a simple booking form with guest count and date fields',
        surface_id: 'booking'
      )

      expect(result.root_id).to be_a(String)
      expect(result.root_id).not_to be_empty
      expect(result.components).to be_an(Array)
      expect(result.components).not_to be_empty

      # Should generate multiple components
      expect(result.components.size).to be >= 2
    end

    it 'generates components with valid IDs' do
      result = generator.call(
        request: 'Create a card with a title and a button',
        surface_id: 'card-demo'
      )

      ids = result.components.map(&:id)
      expect(ids).not_to be_empty
      expect(ids.uniq.size).to eq(ids.size) # All IDs unique
    end

    it 'binds form fields to data paths' do
      result = generator.call(
        request: 'Create a form with name and email text fields',
        surface_id: 'contact-form',
        available_data: '{"contact": {"name": "", "email": ""}}'
      )

      text_fields = result.components.select { |c| c.is_a?(A2UI::TextFieldComponent) }
      expect(text_fields).not_to be_empty

      text_fields.each do |field|
        expect(field.value).to be_a(A2UI::PathReference)
        expect(field.value.path).to start_with('/')
      end
    end
  end
end
