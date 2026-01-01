# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Briefing::DailyBriefing do
  describe 'signature' do
    it 'has a description' do
      expect(Briefing::DailyBriefing.description).to include('daily health')
    end

    it 'defines input fields' do
      input_props = Briefing::DailyBriefing.input_schema.props
      expect(input_props).to include(:user_name)
      expect(input_props).to include(:date)
      expect(input_props).to include(:health_context)
      expect(input_props).to include(:activity_context)
      expect(input_props).to include(:performance_context)
    end

    it 'defines output fields' do
      output_props = Briefing::DailyBriefing.output_schema.props
      expect(output_props).to include(:greeting)
      expect(output_props).to include(:status)
      expect(output_props).to include(:suggestions)
    end
  end
end

RSpec.describe Briefing::DailyBriefingGenerator do
  let(:generator) { described_class.new }

  describe '#initialize' do
    it 'creates a ChainOfThought predictor' do
      expect(generator.instance_variable_get(:@predictor)).to be_a(DSPy::ChainOfThought)
    end
  end

  describe '#forward', :vcr do
    let(:user_name) { 'Vicente' }
    let(:date) { '2024-12-31' }
    let(:health_context) do
      <<~CONTEXT
        Sleep: 7.5 hours, score 85/100 (good)
        HRV: 52ms (balanced, within baseline)
        Resting HR: 48 bpm (normal)
        Body Battery: Started at 75, now at 45
        Stress: Average 28 (low)
        Steps: 8,234 / 10,000 goal
      CONTEXT
    end
    let(:activity_context) do
      <<~CONTEXT
        Yesterday: Rest day, no recorded activities
        Week total: 3 runs, 28km, 3:15 total time
        Recent: 10km tempo run 2 days ago (4:45/km pace)
      CONTEXT
    end
    let(:performance_context) do
      <<~CONTEXT
        VO2 Max: 52 ml/kg/min (excellent for age)
        Training Readiness: 78 (optimal)
        Training Status: Productive
        Acute/Chronic Load Ratio: 1.1 (optimal range)
        Load Focus: High aerobic
        Race predictions: 5K: 19:45, 10K: 41:30
      CONTEXT
    end

    it 'generates a briefing with greeting' do
      result = generator.call(
        user_name: user_name,
        date: date,
        health_context: health_context,
        activity_context: activity_context,
        performance_context: performance_context
      )

      expect(result.greeting).to be_a(String)
      expect(result.greeting).not_to be_empty
    end

    it 'generates status summary' do
      result = generator.call(
        user_name: user_name,
        date: date,
        health_context: health_context,
        activity_context: activity_context,
        performance_context: performance_context
      )

      expect(result.status).to be_a(Briefing::StatusSummary)
      expect(result.status.headline).not_to be_empty
      expect(result.status.summary).not_to be_empty
    end

    it 'generates suggestions array' do
      result = generator.call(
        user_name: user_name,
        date: date,
        health_context: health_context,
        activity_context: activity_context,
        performance_context: performance_context
      )

      expect(result.suggestions).to be_an(Array)
      expect(result.suggestions).not_to be_empty
      expect(result.suggestions.first).to be_a(Briefing::Suggestion)
    end

    it 'generates status with valid sentiment' do
      result = generator.call(
        user_name: user_name,
        date: date,
        health_context: health_context,
        activity_context: activity_context,
        performance_context: performance_context
      )

      expect(result.status.sentiment).to be_a(Briefing::Sentiment)
    end

    it 'generates suggestions with valid types' do
      result = generator.call(
        user_name: user_name,
        date: date,
        health_context: health_context,
        activity_context: activity_context,
        performance_context: performance_context
      )

      result.suggestions.each do |suggestion|
        expect(suggestion.suggestion_type).to be_a(Briefing::SuggestionType)
      end
    end
  end
end
