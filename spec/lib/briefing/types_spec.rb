# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Briefing Types' do
  describe Briefing::DataSource do
    it 'has health source' do
      expect(Briefing::DataSource::Health.serialize).to eq('health')
    end

    it 'has activity source' do
      expect(Briefing::DataSource::Activity.serialize).to eq('activity')
    end

    it 'has performance source' do
      expect(Briefing::DataSource::Performance.serialize).to eq('performance')
    end
  end

  describe Briefing::EvidenceSpan do
    it 'captures data point influence' do
      evidence = Briefing::EvidenceSpan.new(
        source: Briefing::DataSource::Health,
        metric: 'HRV',
        value: '42ms',
        influence: 'Below baseline indicates accumulated fatigue'
      )

      expect(evidence.source).to eq(Briefing::DataSource::Health)
      expect(evidence.metric).to eq('HRV')
      expect(evidence.value).to eq('42ms')
      expect(evidence.influence).to eq('Below baseline indicates accumulated fatigue')
    end
  end

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
        suggestion_type: Briefing::SuggestionType::Intensity
      )

      expect(suggestion.title).to eq('Today')
      expect(suggestion.body).to eq('Good day for tempo or intervals.')
      expect(suggestion.suggestion_type).to eq(Briefing::SuggestionType::Intensity)
    end

    it 'supports evidence spans' do
      evidence = [
        Briefing::EvidenceSpan.new(
          source: Briefing::DataSource::Performance,
          metric: 'Training Load',
          value: '1.1 ratio',
          influence: 'Optimal acute/chronic ratio supports high intensity'
        )
      ]

      suggestion = Briefing::Suggestion.new(
        title: 'Push hard today',
        body: 'Your body is ready for intensity.',
        suggestion_type: Briefing::SuggestionType::Intensity,
        evidence: evidence
      )

      expect(suggestion.evidence.length).to eq(1)
      expect(suggestion.evidence.first.metric).to eq('Training Load')
    end
  end

  describe Briefing::StatusSummary do
    it 'supports evidence spans' do
      evidence = [
        Briefing::EvidenceSpan.new(
          source: Briefing::DataSource::Health,
          metric: 'Sleep',
          value: '5.2h',
          influence: 'Below 6h threshold triggers recovery warning'
        ),
        Briefing::EvidenceSpan.new(
          source: Briefing::DataSource::Health,
          metric: 'HRV',
          value: '38ms',
          influence: 'Down 20% from 7-day average'
        )
      ]

      status = Briefing::StatusSummary.new(
        headline: 'Watch fatigue levels',
        summary: 'Sleep deprivation affecting recovery.',
        sentiment: Briefing::Sentiment::Warning,
        evidence: evidence
      )

      expect(status.evidence.length).to eq(2)
      expect(status.evidence.first.source).to eq(Briefing::DataSource::Health)
      expect(status.evidence.last.influence).to include('20%')
    end
  end

  describe Briefing::BriefingOutput do
    it 'contains greeting, status, and suggestions' do
      status = Briefing::StatusSummary.new(
        headline: 'Ready to perform',
        summary: 'Your recovery metrics look good.',
        sentiment: Briefing::Sentiment::Positive,
        metrics: [
          Briefing::MetricItem.new(label: 'Sleep', value: '7.5h'),
          Briefing::MetricItem.new(label: 'HRV', value: '52ms')
        ]
      )

      output = Briefing::BriefingOutput.new(
        greeting: 'Good morning',
        status: status,
        suggestions: [
          Briefing::Suggestion.new(
            title: 'Today',
            body: 'Push yourself',
            suggestion_type: Briefing::SuggestionType::Intensity
          )
        ]
      )

      expect(output.greeting).to eq('Good morning')
      expect(output.status.headline).to eq('Ready to perform')
      expect(output.suggestions.length).to eq(1)
    end
  end
end
