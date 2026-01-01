# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Garmin::Signals do
  describe Garmin::Signals::SignalPriority do
    it 'serializes priority levels' do
      expect(Garmin::Signals::SignalPriority::Low.serialize).to eq('low')
      expect(Garmin::Signals::SignalPriority::Medium.serialize).to eq('medium')
      expect(Garmin::Signals::SignalPriority::High.serialize).to eq('high')
      expect(Garmin::Signals::SignalPriority::Urgent.serialize).to eq('urgent')
    end
  end

  describe Garmin::Signals::ChangeType do
    it 'serializes change types' do
      expect(Garmin::Signals::ChangeType::NewActivity.serialize).to eq('new_activity')
      expect(Garmin::Signals::ChangeType::DailyMetrics.serialize).to eq('daily_metrics')
      expect(Garmin::Signals::ChangeType::SleepData.serialize).to eq('sleep_data')
      expect(Garmin::Signals::ChangeType::PerformanceUpdate.serialize).to eq('performance_update')
      expect(Garmin::Signals::ChangeType::ThresholdCrossed.serialize).to eq('threshold_crossed')
    end
  end

  describe Garmin::Signals::DataSignal do
    it 'creates a complete signal' do
      signal = Garmin::Signals::DataSignal.new(
        id: 'activity_123',
        change_type: Garmin::Signals::ChangeType::NewActivity,
        priority: Garmin::Signals::SignalPriority::High,
        title: 'New Run',
        summary: 'Morning 10K run completed.',
        data_path: '/activities/123',
        timestamp: Time.new(2025, 12, 31, 8, 0, 0),
        metadata: { 'distance' => 10_000, 'duration' => 3600 }
      )

      expect(signal.id).to eq('activity_123')
      expect(signal.change_type).to eq(Garmin::Signals::ChangeType::NewActivity)
      expect(signal.priority).to eq(Garmin::Signals::SignalPriority::High)
      expect(signal.title).to eq('New Run')
      expect(signal.summary).to eq('Morning 10K run completed.')
      expect(signal.data_path).to eq('/activities/123')
      expect(signal.metadata['distance']).to eq(10_000)
    end

    it 'has default empty metadata' do
      signal = Garmin::Signals::DataSignal.new(
        id: 'test',
        change_type: Garmin::Signals::ChangeType::DailyMetrics,
        priority: Garmin::Signals::SignalPriority::Low,
        title: 'Test',
        summary: 'Test signal',
        data_path: '/test',
        timestamp: Time.now
      )

      expect(signal.metadata).to eq({})
    end
  end

  describe Garmin::Signals::SignificanceEvaluator do
    let(:connection) { instance_double(Garmin::Connection) }
    let(:health_query) { instance_double(Garmin::Queries::DailyHealth) }
    let(:activities_query) { instance_double(Garmin::Queries::Activities) }
    let(:performance_query) { instance_double(Garmin::Queries::Performance) }

    before do
      allow(Garmin::Queries::DailyHealth).to receive(:new).and_return(health_query)
      allow(Garmin::Queries::Activities).to receive(:new).and_return(activities_query)
      allow(Garmin::Queries::Performance).to receive(:new).and_return(performance_query)
    end

    let(:evaluator) { Garmin::Signals::SignificanceEvaluator.new(connection) }

    describe '#detect_new_activities' do
      it 'returns signals for activities since the given time' do
        recent_activity = {
          activity_id: 123,
          activity_type: 'Running',
          start_time: Time.now - 1.hour,
          distance: 15_000,
          duration: 4500
        }

        allow(activities_query).to receive(:recent).with(limit: 10).and_return([recent_activity])

        signals = evaluator.detect_new_activities(since: Time.now - 2.hours)

        expect(signals.length).to eq(1)
        expect(signals.first.title).to eq('New Running')
        expect(signals.first.priority).to eq(Garmin::Signals::SignalPriority::Medium)
      end

      it 'assigns high priority to long activities' do
        long_activity = {
          activity_id: 456,
          activity_type: 'Cycling',
          start_time: Time.now - 30.minutes,
          distance: 25_000,
          duration: 5400
        }

        allow(activities_query).to receive(:recent).with(limit: 10).and_return([long_activity])

        signals = evaluator.detect_new_activities(since: Time.now - 1.hour)

        expect(signals.first.priority).to eq(Garmin::Signals::SignalPriority::High)
      end

      it 'filters out old activities' do
        old_activity = {
          activity_id: 789,
          activity_type: 'Running',
          start_time: Time.now - 3.hours,
          distance: 5000,
          duration: 1800
        }

        allow(activities_query).to receive(:recent).with(limit: 10).and_return([old_activity])

        signals = evaluator.detect_new_activities(since: Time.now - 1.hour)

        expect(signals).to be_empty
      end

      it 'returns empty array when no activities' do
        allow(activities_query).to receive(:recent).with(limit: 10).and_return(nil)

        signals = evaluator.detect_new_activities(since: Time.now)

        expect(signals).to eq([])
      end
    end

    describe '#detect_health_changes' do
      it 'detects significant HRV drops' do
        daily_health = { hrv_value: 38 }
        sleep_trend = { average_hrv: 52 }

        allow(health_query).to receive(:for_date).and_return(daily_health)
        allow(health_query).to receive(:sleep_trend).with(days: 7).and_return(sleep_trend)
        allow(health_query).to receive(:recovery_status).and_return(nil)

        signals = evaluator.detect_health_changes(date: Date.today)

        hrv_signal = signals.find { |s| s.id.include?('hrv') }
        expect(hrv_signal).to be_present
        expect(hrv_signal.priority).to eq(Garmin::Signals::SignalPriority::High)
        expect(hrv_signal.title).to include('down')
      end

      it 'detects low sleep' do
        daily_health = { sleep_duration_hours: 4.5 }

        allow(health_query).to receive(:for_date).and_return(daily_health)
        allow(health_query).to receive(:sleep_trend).and_return(nil)
        allow(health_query).to receive(:recovery_status).and_return(nil)

        signals = evaluator.detect_health_changes(date: Date.today)

        sleep_signal = signals.find { |s| s.id.include?('sleep') }
        expect(sleep_signal).to be_present
        expect(sleep_signal.priority).to eq(Garmin::Signals::SignalPriority::High)
        expect(sleep_signal.title).to include('4.5h')
      end

      it 'returns empty when health data is normal' do
        daily_health = { hrv_value: 50, sleep_duration_hours: 7.5 }
        sleep_trend = { average_hrv: 52 }

        allow(health_query).to receive(:for_date).and_return(daily_health)
        allow(health_query).to receive(:sleep_trend).with(days: 7).and_return(sleep_trend)
        allow(health_query).to receive(:recovery_status).and_return(nil)

        signals = evaluator.detect_health_changes(date: Date.today)

        expect(signals).to be_empty
      end
    end

    describe '#detect_performance_changes' do
      it 'detects training status concerns' do
        allow(performance_query).to receive(:latest).and_return({ vo2max: 50 })
        allow(performance_query).to receive(:vo2max_trend).and_return(nil)
        allow(performance_query).to receive(:training_status_summary).and_return({ status: 'overreaching' })

        signals = evaluator.detect_performance_changes

        training_signal = signals.find { |s| s.id.include?('training') }
        expect(training_signal).to be_present
        expect(training_signal.priority).to eq(Garmin::Signals::SignalPriority::High)
      end

      it 'returns empty when performance is normal' do
        allow(performance_query).to receive(:latest).and_return({ vo2max: 50 })
        allow(performance_query).to receive(:vo2max_trend).and_return({ current: 50, previous: 50 })
        allow(performance_query).to receive(:training_status_summary).and_return({ status: 'productive' })

        signals = evaluator.detect_performance_changes

        expect(signals).to be_empty
      end
    end
  end
end
