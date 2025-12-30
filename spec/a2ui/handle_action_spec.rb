# frozen_string_literal: true

require 'spec_helper'

RSpec.describe A2UI::HandleAction do
  before(:all) do
    DSPy.configure do |c|
      c.lm = DSPy::LM.new('openai/gpt-4o-mini', api_key: ENV.fetch('OPENAI_API_KEY', 'test-key'))
    end
  end

  describe 'signature structure' do
    it 'has UserAction input struct' do
      schema = A2UI::HandleAction.input_json_schema

      expect(schema[:properties]).to have_key(:action)
      expect(schema[:properties]).to have_key(:current_data)
      expect(schema[:properties]).to have_key(:business_rules)
    end

    it 'has ActionResponseType enum in output' do
      schema = A2UI::HandleAction.output_json_schema

      expect(schema[:properties]).to have_key(:response_type)
      expect(schema[:properties]).to have_key(:streams)
      expect(schema[:properties]).to have_key(:components)
    end
  end

  describe 'action handling', :vcr do
    let(:handler) { A2UI::ActionHandler.new }

    it 'processes a submit action' do
      action = A2UI::UserAction.new(
        name: 'submit_booking',
        surface_id: 'booking',
        source_id: 'submit-btn',
        context: { 'guests' => '2', 'date' => '2025-01-15' }
      )

      result = handler.call(
        action: action,
        current_data: '{"booking": {"guests": "2", "date": "2025-01-15"}}',
        business_rules: 'Maximum 10 guests per booking'
      )

      expect(result.response_type).to be_a(A2UI::ActionResponseType)
      expect([
        A2UI::ActionResponseType::UpdateUI,
        A2UI::ActionResponseType::Navigate,
        A2UI::ActionResponseType::NoOp
      ]).to include(result.response_type)
    end

    it 'returns streams for UI updates' do
      action = A2UI::UserAction.new(
        name: 'add_guest',
        surface_id: 'booking',
        source_id: 'add-btn',
        context: {}
      )

      result = handler.call(
        action: action,
        current_data: '{"guests": 1}'
      )

      if result.response_type == A2UI::ActionResponseType::UpdateUI
        expect(result.streams).to be_an(Array)
        result.streams.each do |stream|
          expect(stream).to be_a(A2UI::StreamOp)
          expect(stream.action).to be_a(A2UI::StreamAction)
        end
      end
    end
  end
end
