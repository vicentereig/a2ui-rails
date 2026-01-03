# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GenerateEditorialBriefingJob, type: :job do
  let(:user_id) { 'user_123' }
  let(:date) { '2024-12-31' }
  let(:parsed_date) { Date.parse(date) }
  let(:surface_id) { "editorial-#{user_id}-#{date}" }

  let(:mock_connection) { double('Garmin::Connection', close: nil) }
  let(:mock_health_query) { double('Garmin::Queries::DailyHealth') }
  let(:mock_activities_query) { double('Garmin::Queries::Activities') }
  let(:mock_performance_query) { double('Garmin::Queries::Performance') }

  let(:mock_daily_health) do
    Garmin::DailyHealth.new(
      date: parsed_date,
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

  let(:mock_activities) { [] }
  let(:mock_week_stats) { nil }
  let(:mock_performance) { nil }
  let(:mock_training_status) { nil }
  let(:mock_vo2max_trend) { nil }

  # A2UI components for the editorial UI
  let(:mock_components) do
    [
      A2UI::ColumnComponent.new(
        id: 'root',
        children: A2UI::ExplicitChildren.new(ids: ['headline', 'content']),
        gap: 16
      ),
      A2UI::TextComponent.new(
        id: 'headline',
        content: A2UI::LiteralValue.new(value: 'Sleep Excellence Unlocks Training Potential'),
        usage_hint: A2UI::TextUsageHint::H1
      ),
      A2UI::TextComponent.new(
        id: 'content',
        content: A2UI::LiteralValue.new(value: 'Your recovery is looking strong.'),
        usage_hint: A2UI::TextUsageHint::Body
      )
    ]
  end

  # A2UI generator result - struct with root_id and components
  let(:mock_generator_result) do
    # Using a simple struct to simulate the DSPy output
    Struct.new(:root_id, :components, :initial_data, keyword_init: true).new(
      root_id: 'root',
      components: mock_components,
      initial_data: []
    )
  end

  let(:mock_generator) { double('A2UI::EditorialUIGenerator') }

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

    # Health queries - return array for 7-day queries
    allow(mock_health_query).to receive(:recent).and_return([mock_daily_health])
    allow(mock_health_query).to receive(:sleep_trend).and_return(mock_sleep_trend)
    allow(mock_health_query).to receive(:recovery_status).and_return(nil)

    # Activity queries
    allow(mock_activities_query).to receive(:recent).and_return(mock_activities)
    allow(mock_activities_query).to receive(:week_stats).and_return(mock_week_stats)

    # Performance queries
    allow(mock_performance_query).to receive(:latest).and_return(mock_performance)
    allow(mock_performance_query).to receive(:training_status_summary).and_return(mock_training_status)
    allow(mock_performance_query).to receive(:vo2max_trend).and_return(mock_vo2max_trend)

    # Stub A2UI generator
    allow(A2UI::EditorialUIGenerator).to receive(:new).and_return(mock_generator)
    allow(mock_generator).to receive(:call).and_return(mock_generator_result)
    allow(mock_generator).to receive(:token_usage).and_return({
      input_tokens: 500,
      output_tokens: 150,
      model: 'anthropic/claude-3-haiku'
    })
  end

  describe '#perform' do
    context 'with valid Garmin data' do
      it 'does not broadcast an error' do
        allow(BriefingChannel).to receive(:broadcast_token_usage)
        allow(BriefingChannel).to receive(:broadcast_complete)
        allow(BriefingChannel).to receive(:broadcast_a2ui_editorial)

        expect(BriefingChannel).not_to receive(:broadcast_error)

        described_class.new.perform(user_id: user_id, date: date)
      end

      it 'broadcasts A2UI editorial to the user channel' do
        allow(BriefingChannel).to receive(:broadcast_token_usage)
        allow(BriefingChannel).to receive(:broadcast_complete)
        allow(BriefingChannel).to receive(:broadcast_error)

        expect(BriefingChannel).to receive(:broadcast_a2ui_editorial)
          .with(user_id, an_instance_of(A2UI::Surface))

        described_class.new.perform(user_id: user_id, date: date)
      end

      it 'broadcasts token usage' do
        expect(BriefingChannel).to receive(:broadcast_token_usage)
          .with(user_id, hash_including(
            model: 'anthropic/claude-3-haiku',
            input_tokens: 500,
            output_tokens: 150
          ))

        allow(BriefingChannel).to receive(:broadcast_a2ui_editorial)
        allow(BriefingChannel).to receive(:broadcast_complete)

        described_class.new.perform(user_id: user_id, date: date)
      end

      it 'broadcasts completion when done' do
        allow(BriefingChannel).to receive(:broadcast_a2ui_editorial)
        allow(BriefingChannel).to receive(:broadcast_token_usage)

        expect(BriefingChannel).to receive(:broadcast_complete)
          .with(user_id)

        described_class.new.perform(user_id: user_id, date: date)
      end

      it 'calls the A2UI generator with narrative context' do
        allow(BriefingChannel).to receive(:broadcast_a2ui_editorial)
        allow(BriefingChannel).to receive(:broadcast_token_usage)
        allow(BriefingChannel).to receive(:broadcast_complete)

        expect(mock_generator).to receive(:call).with(
          hash_including(
            surface_id: surface_id,
            date: date,
            health: an_instance_of(Briefing::HealthNarrative),
            activity: an_instance_of(Briefing::ActivityNarrative),
            performance: an_instance_of(Briefing::PerformanceNarrative),
            detected_patterns: an_instance_of(Array)
          )
        ).and_return(mock_generator_result)

        described_class.new.perform(user_id: user_id, date: date)
      end

      it 'saves the briefing record with A2UI surface output' do
        allow(BriefingChannel).to receive(:broadcast_a2ui_editorial)
        allow(BriefingChannel).to receive(:broadcast_token_usage)
        allow(BriefingChannel).to receive(:broadcast_complete)
        allow(BriefingChannel).to receive(:broadcast_error)

        expect {
          described_class.new.perform(user_id: user_id, date: date)
        }.to change(BriefingRecord, :count).by(1)

        record = BriefingRecord.last
        expect(record.user_id).to eq(user_id)
        expect(record.date).to eq(parsed_date)
        expect(record.briefing_type).to eq('editorial')
        expect(record.model).to eq('anthropic/claude-3-haiku')
        expect(record.input_tokens).to eq(500)
        expect(record.output_tokens).to eq(150)

        # Verify A2UI surface format in output
        output = record.output.deep_symbolize_keys
        expect(output[:surface_id]).to eq(surface_id)
        expect(output[:root_id]).to eq('root')
        expect(output[:components]).to be_an(Array)
        expect(output[:components].size).to eq(3)
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

    context 'when A2UI generator fails' do
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
