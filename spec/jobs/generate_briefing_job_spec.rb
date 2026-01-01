# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GenerateBriefingJob, type: :job do
  let(:user_id) { 'user_123' }
  let(:date) { '2024-12-31' }

  let(:mock_connection) { double('Garmin::Connection', close: nil) }
  let(:mock_health_query) { double('Garmin::Queries::DailyHealth') }
  let(:mock_activities_query) { double('Garmin::Queries::Activities') }
  let(:mock_performance_query) { double('Garmin::Queries::Performance') }

  let(:mock_daily_health) do
    Garmin::DailyHealth.new(
      date: Date.parse(date),
      steps: 8234,
      step_goal: 10_000,
      total_calories: 2450,
      resting_hr: 48,
      sleep_seconds: 27_000,
      deep_sleep_seconds: 5400,
      light_sleep_seconds: 14_400,
      rem_sleep_seconds: 7200,
      sleep_score: 85,
      avg_stress: 28,
      max_stress: 65,
      body_battery_start: 75,
      body_battery_end: 45,
      hrv_weekly_avg: 55,
      hrv_last_night: 52,
      hrv_status: 'BALANCED'
    )
  end

  let(:mock_sleep_trend) do
    Garmin::SleepTrend.new(
      avg_sleep_score: 82.0,
      avg_sleep_hours: 7.2,
      trend_direction: :stable,
      consecutive_good_nights: 3
    )
  end

  let(:mock_recovery_status) do
    Garmin::RecoveryStatus.new(
      body_battery: 45,
      hrv_status: 'BALANCED',
      resting_hr: 48,
      stress_level: 28,
      readiness: :ready
    )
  end

  let(:mock_activities) { [] }
  let(:mock_week_stats) { nil }
  let(:mock_performance) { nil }
  let(:mock_training_load) { nil }
  let(:mock_vo2max_trend) { nil }
  let(:mock_race_predictions) { nil }

  let(:mock_status) do
    Briefing::StatusSummary.new(
      headline: 'Ready to perform',
      summary: 'Your recovery metrics look good.',
      sentiment: Briefing::Sentiment::Positive,
      metrics: [
        Briefing::MetricItem.new(label: 'Sleep', value: '7.5h'),
        Briefing::MetricItem.new(label: 'HRV', value: '52ms')
      ]
    )
  end

  let(:mock_suggestion) do
    Briefing::Suggestion.new(
      title: 'Today',
      body: 'Push yourself today.',
      suggestion_type: Briefing::SuggestionType::Intensity
    )
  end

  let(:mock_briefing_output) do
    double('BriefingOutput',
      greeting: 'Good morning',
      status: mock_status,
      suggestions: [mock_suggestion]
    )
  end

  let(:mock_generator) { double('Briefing::DailyBriefingGenerator') }

  before do
    # Stub Garmin connection
    allow(Garmin::Connection).to receive(:new).and_return(mock_connection)
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(anything).and_return(true)

    # Stub connection methods for async data fetching
    allow(mock_connection).to receive(:dataset_available?).with('daily_health').and_return(true)
    allow(mock_connection).to receive(:dataset_available?).with('activities').and_return(true)
    allow(mock_connection).to receive(:dataset_available?).with('performance_metrics').and_return(true)
    allow(mock_connection).to receive(:parquet?).and_return(false)

    # Stub queries
    allow(Garmin::Queries::DailyHealth).to receive(:new).and_return(mock_health_query)
    allow(Garmin::Queries::Activities).to receive(:new).and_return(mock_activities_query)
    allow(Garmin::Queries::Performance).to receive(:new).and_return(mock_performance_query)

    allow(mock_health_query).to receive(:for_date).and_return(mock_daily_health)
    allow(mock_health_query).to receive(:sleep_trend).and_return(mock_sleep_trend)
    allow(mock_health_query).to receive(:recovery_status).and_return(mock_recovery_status)

    allow(mock_activities_query).to receive(:recent).and_return(mock_activities)
    allow(mock_activities_query).to receive(:week_stats).and_return(mock_week_stats)

    allow(mock_performance_query).to receive(:latest).and_return(mock_performance)
    allow(mock_performance_query).to receive(:training_status_summary).and_return(mock_training_load)
    allow(mock_performance_query).to receive(:vo2max_trend).and_return(mock_vo2max_trend)
    allow(mock_performance_query).to receive(:race_predictions).and_return(mock_race_predictions)

    # Stub DSPy generator
    allow(Briefing::DailyBriefingGenerator).to receive(:new).and_return(mock_generator)
    allow(mock_generator).to receive(:call).and_return(mock_briefing_output)
  end

  describe '#perform' do
    context 'with valid Garmin data' do
      it 'broadcasts status to the user channel' do
        expect(BriefingChannel).to receive(:broadcast_status)
          .with(user_id, mock_status)

        allow(BriefingChannel).to receive(:broadcast_suggestion)
        allow(BriefingChannel).to receive(:broadcast_complete)

        described_class.new.perform(user_id: user_id, date: date)
      end

      it 'broadcasts suggestions to the user channel' do
        expect(BriefingChannel).to receive(:broadcast_suggestion)
          .with(user_id, mock_suggestion)

        allow(BriefingChannel).to receive(:broadcast_status)
        allow(BriefingChannel).to receive(:broadcast_complete)

        described_class.new.perform(user_id: user_id, date: date)
      end

      it 'broadcasts completion when done' do
        allow(BriefingChannel).to receive(:broadcast_status)
        allow(BriefingChannel).to receive(:broadcast_suggestion)

        expect(BriefingChannel).to receive(:broadcast_complete)
          .with(user_id)

        described_class.new.perform(user_id: user_id, date: date)
      end

      it 'calls the DSPy generator with correct context' do
        allow(BriefingChannel).to receive(:broadcast_status)
        allow(BriefingChannel).to receive(:broadcast_suggestion)
        allow(BriefingChannel).to receive(:broadcast_complete)

        expect(mock_generator).to receive(:call).with(
          hash_including(
            user_name: 'Runner',
            date: date,
            health_context: a_string_including('7.5 hours'),
            activity_context: String,
            performance_context: String
          )
        ).and_return(mock_briefing_output)

        described_class.new.perform(user_id: user_id, date: date)
      end
    end

    context 'when Garmin database is not found' do
      before do
        allow(File).to receive(:exist?).with(anything).and_return(false)
        allow(File).to receive(:directory?).with(anything).and_return(false)
      end

      it 'broadcasts an error message' do
        expect(BriefingChannel).to receive(:broadcast_error)
          .with(user_id, /database|connection/i)

        described_class.new.perform(user_id: user_id, date: date)
      end
    end

    context 'when DSPy call fails' do
      before do
        allow(mock_generator).to receive(:call).and_raise(StandardError, 'LLM error')
      end

      it 'broadcasts an error message' do
        expect(BriefingChannel).to receive(:broadcast_error)
          .with(user_id, /error|occurred/i)

        described_class.new.perform(user_id: user_id, date: date)
      end
    end
  end

  describe 'job configuration' do
    it 'is queued on the default queue' do
      expect(described_class.new.queue_name).to eq('default')
    end
  end
end
