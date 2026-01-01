# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Briefing Types' do
  describe Briefing::Sentiment do
    it 'has positive sentiment' do
      expect(Briefing::Sentiment::Positive.serialize).to eq('positive')
    end

    it 'has neutral sentiment' do
      expect(Briefing::Sentiment::Neutral.serialize).to eq('neutral')
    end

    it 'has warning sentiment' do
      expect(Briefing::Sentiment::Warning.serialize).to eq('warning')
    end
  end

  describe Briefing::SuggestionType do
    it 'has general type' do
      expect(Briefing::SuggestionType::General.serialize).to eq('general')
    end

    it 'has recovery type' do
      expect(Briefing::SuggestionType::Recovery.serialize).to eq('recovery')
    end

    it 'has intensity type' do
      expect(Briefing::SuggestionType::Intensity.serialize).to eq('intensity')
    end
  end

  describe Briefing::InsightBlock do
    it 'can be constructed with required fields' do
      insight = Briefing::InsightBlock.new(
        icon: '😴',
        headline: 'Sleep Recovery',
        narrative: 'You slept well last night.',
        sentiment: Briefing::Sentiment::Positive
      )

      expect(insight.icon).to eq('😴')
      expect(insight.headline).to eq('Sleep Recovery')
      expect(insight.narrative).to eq('You slept well last night.')
      expect(insight.sentiment).to eq(Briefing::Sentiment::Positive)
    end

    it 'supports metrics array' do
      metrics = [
        Briefing::MetricItem.new(label: '7.5', value: 'hours'),
        Briefing::MetricItem.new(label: '85', value: 'score')
      ]

      insight = Briefing::InsightBlock.new(
        icon: '😴',
        headline: 'Sleep',
        narrative: 'Good sleep',
        sentiment: Briefing::Sentiment::Positive,
        metrics: metrics
      )

      expect(insight.metrics.length).to eq(2)
      expect(insight.metrics.first.label).to eq('7.5')
    end
  end

  describe Briefing::MetricItem do
    it 'can be constructed with label and value' do
      metric = Briefing::MetricItem.new(label: '7.5', value: 'hours')

      expect(metric.label).to eq('7.5')
      expect(metric.value).to eq('hours')
    end

    it 'supports optional trend' do
      metric = Briefing::MetricItem.new(
        label: '52',
        value: 'ms HRV',
        trend: Briefing::TrendDirection::Up
      )

      expect(metric.trend).to eq(Briefing::TrendDirection::Up)
    end
  end

  describe Briefing::Suggestion do
    it 'can be constructed with required fields' do
      suggestion = Briefing::Suggestion.new(
        title: 'Today',
        body: 'Good day for tempo or intervals.',
        icon: '🏃',
        suggestion_type: Briefing::SuggestionType::Intensity
      )

      expect(suggestion.title).to eq('Today')
      expect(suggestion.body).to eq('Good day for tempo or intervals.')
      expect(suggestion.icon).to eq('🏃')
      expect(suggestion.suggestion_type).to eq(Briefing::SuggestionType::Intensity)
    end

    it 'defaults icon to lightbulb' do
      suggestion = Briefing::Suggestion.new(
        title: 'Tip',
        body: 'Remember to hydrate.',
        suggestion_type: Briefing::SuggestionType::General
      )

      expect(suggestion.icon).to eq('💡')
    end
  end

  describe Briefing::BriefingOutput do
    it 'contains greeting, insights, and suggestions' do
      output = Briefing::BriefingOutput.new(
        greeting: 'Good morning',
        insights: [
          Briefing::InsightBlock.new(
            icon: '😴',
            headline: 'Sleep',
            narrative: 'Well rested',
            sentiment: Briefing::Sentiment::Positive
          )
        ],
        suggestions: [
          Briefing::Suggestion.new(
            title: 'Today',
            body: 'Push yourself',
            suggestion_type: Briefing::SuggestionType::Intensity
          )
        ]
      )

      expect(output.greeting).to eq('Good morning')
      expect(output.insights.length).to eq(1)
      expect(output.suggestions.length).to eq(1)
    end
  end
end
