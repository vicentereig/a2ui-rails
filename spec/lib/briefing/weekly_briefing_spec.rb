# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Briefing::WeeklyBriefingGenerator do
  describe '.build_daily_summaries' do
    it 'builds summaries from BriefingRecord entries' do
      records = [
        double(
          'BriefingRecord',
          date: Date.new(2025, 12, 23),
          output: {
            'status' => {
              'headline' => 'Good recovery day',
              'sentiment' => 'positive',
              'metrics' => [
                { 'label' => 'Sleep', 'value' => '7.5h' },
                { 'label' => 'HRV', 'value' => '52ms' }
              ]
            }
          }
        ),
        double(
          'BriefingRecord',
          date: Date.new(2025, 12, 24),
          output: {
            'status' => {
              'headline' => 'Watch fatigue levels',
              'sentiment' => 'warning',
              'metrics' => [
                { 'label' => 'Sleep', 'value' => '5.2h' }
              ]
            }
          }
        )
      ]

      summaries = described_class.build_daily_summaries(records)

      expect(summaries.length).to eq(2)
      expect(summaries[0].date).to eq('2025-12-23')
      expect(summaries[0].headline).to eq('Good recovery day')
      expect(summaries[0].sentiment).to eq('positive')
      expect(summaries[0].key_metrics).to eq('Sleep: 7.5h, HRV: 52ms')

      expect(summaries[1].date).to eq('2025-12-24')
      expect(summaries[1].headline).to eq('Watch fatigue levels')
      expect(summaries[1].sentiment).to eq('warning')
      expect(summaries[1].key_metrics).to eq('Sleep: 5.2h')
    end

    it 'handles records with missing output' do
      records = [
        double('BriefingRecord', date: Date.new(2025, 12, 23), output: nil)
      ]

      summaries = described_class.build_daily_summaries(records)

      expect(summaries.length).to eq(1)
      expect(summaries[0].headline).to eq('No data')
      expect(summaries[0].sentiment).to eq('neutral')
      expect(summaries[0].key_metrics).to eq('No metrics')
    end
  end

  describe Briefing::WeeklyBriefing do
    it 'has a description' do
      expect(Briefing::WeeklyBriefing.description).to include('weekly')
    end

    it 'has the expected input fields' do
      input_props = Briefing::WeeklyBriefing.input_schema.props

      expect(input_props).to include(:user_name)
      expect(input_props).to include(:week_start)
      expect(input_props).to include(:week_end)
      expect(input_props).to include(:daily_summaries)
    end

    it 'has the expected output fields' do
      output_props = Briefing::WeeklyBriefing.output_schema.props

      expect(output_props).to include(:week_range)
      expect(output_props).to include(:status)
      expect(output_props).to include(:suggestions)
    end
  end

  describe Briefing::DailySummary do
    it 'creates a valid struct' do
      summary = Briefing::DailySummary.new(
        date: '2025-12-23',
        headline: 'Good day',
        sentiment: 'positive',
        key_metrics: 'Sleep: 7h, HRV: 55ms'
      )

      expect(summary.date).to eq('2025-12-23')
      expect(summary.headline).to eq('Good day')
      expect(summary.sentiment).to eq('positive')
      expect(summary.key_metrics).to eq('Sleep: 7h, HRV: 55ms')
    end
  end

  describe Briefing::WeeklyTrend do
    it 'creates a valid struct' do
      trend = Briefing::WeeklyTrend.new(
        metric: 'Sleep',
        direction: Briefing::TrendDirection::Up,
        summary: 'Sleep improved throughout the week'
      )

      expect(trend.metric).to eq('Sleep')
      expect(trend.direction).to eq(Briefing::TrendDirection::Up)
      expect(trend.summary).to eq('Sleep improved throughout the week')
    end
  end

  describe Briefing::WeeklyStatusSummary do
    it 'creates a valid struct with defaults' do
      status = Briefing::WeeklyStatusSummary.new(
        headline: 'Strong week',
        summary: 'Good progress across all metrics.',
        sentiment: Briefing::Sentiment::Positive
      )

      expect(status.headline).to eq('Strong week')
      expect(status.trends).to eq([])
    end
  end

  describe Briefing::WeeklySuggestion do
    it 'creates a valid struct' do
      suggestion = Briefing::WeeklySuggestion.new(
        title: 'Focus on recovery',
        body: 'Prioritize sleep quality next week.',
        priority: 1
      )

      expect(suggestion.title).to eq('Focus on recovery')
      expect(suggestion.priority).to eq(1)
    end
  end
end
