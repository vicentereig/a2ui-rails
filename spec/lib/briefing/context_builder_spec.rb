# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Briefing::ContextBuilder do
  let(:date) { Date.new(2024, 12, 31) }

  describe '#build_health_context' do
    let(:daily_health) do
      Garmin::DailyHealth.new(
        date: date,
        steps: 8234,
        step_goal: 10_000,
        total_calories: 2450,
        resting_hr: 48,
        sleep_seconds: 27_000, # 7.5 hours
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

    let(:sleep_trend) do
      Garmin::SleepTrend.new(
        avg_sleep_score: 82.0,
        avg_sleep_hours: 7.2,
        trend_direction: :stable,
        consecutive_good_nights: 3
      )
    end

    let(:recovery_status) do
      Garmin::RecoveryStatus.new(
        body_battery: 45,
        hrv_status: 'BALANCED',
        resting_hr: 48,
        stress_level: 28,
        readiness: :ready
      )
    end

    it 'builds context from daily health data' do
      builder = described_class.new(
        daily_health: daily_health,
        sleep_trend: sleep_trend,
        recovery_status: recovery_status
      )

      context = builder.build_health_context

      expect(context).to include('7.5 hours')
      expect(context).to include('85')
      expect(context).to include('52')
      expect(context).to include('48')
      expect(context).to include('8,234')
    end

    it 'includes sleep trend information' do
      builder = described_class.new(
        daily_health: daily_health,
        sleep_trend: sleep_trend,
        recovery_status: recovery_status
      )

      context = builder.build_health_context

      expect(context).to include('stable')
      expect(context).to include('3 good nights')
    end

    it 'includes recovery readiness' do
      builder = described_class.new(
        daily_health: daily_health,
        sleep_trend: sleep_trend,
        recovery_status: recovery_status
      )

      context = builder.build_health_context

      expect(context).to include('ready')
    end

    it 'handles nil values gracefully' do
      minimal_health = Garmin::DailyHealth.new(
        date: date,
        steps: nil,
        step_goal: nil,
        total_calories: nil,
        resting_hr: nil,
        sleep_seconds: nil,
        deep_sleep_seconds: nil,
        light_sleep_seconds: nil,
        rem_sleep_seconds: nil,
        sleep_score: nil,
        avg_stress: nil,
        max_stress: nil,
        body_battery_start: nil,
        body_battery_end: nil,
        hrv_weekly_avg: nil,
        hrv_last_night: nil,
        hrv_status: nil
      )

      builder = described_class.new(daily_health: minimal_health)
      context = builder.build_health_context

      expect(context).to be_a(String)
      expect(context).to include('No data')
    end
  end

  describe '#build_activity_context' do
    let(:recent_activities) do
      [
        Garmin::Activity.new(
          activity_id: 1,
          activity_name: 'Morning Run',
          activity_type: 'running',
          start_time_local: Time.new(2024, 12, 29, 7, 0),
          duration_sec: 3600.0,
          distance_m: 10_000.0,
          calories: 650,
          avg_hr: 145,
          max_hr: 165,
          avg_speed: 2.78,
          elevation_gain: 120.0,
          avg_cadence: 175.0,
          location_name: 'Central Park'
        ),
        Garmin::Activity.new(
          activity_id: 2,
          activity_name: 'Easy Run',
          activity_type: 'running',
          start_time_local: Time.new(2024, 12, 27, 8, 0),
          duration_sec: 2700.0,
          distance_m: 6000.0,
          calories: 400,
          avg_hr: 130,
          max_hr: 145,
          avg_speed: 2.22,
          elevation_gain: 50.0,
          avg_cadence: 170.0,
          location_name: nil
        )
      ]
    end

    let(:week_stats) do
      Garmin::ActivityStats.new(
        total_distance_m: 28_000.0,
        total_duration_sec: 11_700.0, # 3:15
        activity_count: 3,
        avg_pace_per_km: 4.75
      )
    end

    it 'builds context from recent activities' do
      builder = described_class.new(
        recent_activities: recent_activities,
        week_stats: week_stats
      )

      context = builder.build_activity_context

      expect(context).to include('Morning Run')
      expect(context).to include('10')
      expect(context).to include('running')
    end

    it 'includes weekly stats' do
      builder = described_class.new(
        recent_activities: recent_activities,
        week_stats: week_stats
      )

      context = builder.build_activity_context

      expect(context).to include('28')
      expect(context).to include('3 activities')
    end

    it 'handles empty activities' do
      builder = described_class.new(recent_activities: [])
      context = builder.build_activity_context

      expect(context).to include('No recent activities')
    end
  end

  describe '#build_performance_context' do
    let(:performance_metrics) do
      Garmin::PerformanceMetrics.new(
        date: date,
        vo2max: 52.0,
        fitness_age: 25,
        training_readiness: 78,
        training_readiness_level: 'OPTIMAL',
        training_status: 'PRODUCTIVE',
        acute_load: 450.0,
        chronic_load: 410.0,
        load_ratio: 1.1,
        load_ratio_status: 'OPTIMAL',
        load_focus: 'HIGH_AEROBIC',
        lactate_threshold_hr: 165,
        race_5k_sec: 1185,
        race_10k_sec: 2490,
        race_half_sec: 5580,
        race_marathon_sec: 11_700
      )
    end

    let(:training_load) do
      Garmin::TrainingLoadStatus.new(
        acute_load: 450.0,
        chronic_load: 410.0,
        ratio: 1.1,
        status: 'OPTIMAL',
        focus: 'HIGH_AEROBIC',
        training_status: 'PRODUCTIVE'
      )
    end

    let(:vo2max_trend) do
      Garmin::VO2MaxTrend.new(
        current: 52.0,
        change_30d: 0.5,
        direction: :improving
      )
    end

    let(:race_predictions) do
      Garmin::RacePredictions.new(
        five_k: '19:45',
        ten_k: '41:30',
        half_marathon: '1:33:00',
        marathon: '3:15:00'
      )
    end

    it 'builds context from performance metrics' do
      builder = described_class.new(
        performance_metrics: performance_metrics,
        training_load: training_load,
        vo2max_trend: vo2max_trend,
        race_predictions: race_predictions
      )

      context = builder.build_performance_context

      expect(context).to include('52')
      expect(context).to include('VO2')
    end

    it 'includes training status' do
      builder = described_class.new(
        performance_metrics: performance_metrics,
        training_load: training_load
      )

      context = builder.build_performance_context

      expect(context).to include('PRODUCTIVE')
      expect(context).to include('OPTIMAL')
    end

    it 'includes race predictions when available' do
      builder = described_class.new(
        performance_metrics: performance_metrics,
        race_predictions: race_predictions
      )

      context = builder.build_performance_context

      expect(context).to include('19:45')
      expect(context).to include('5K')
    end

    it 'includes VO2 max trend' do
      builder = described_class.new(
        performance_metrics: performance_metrics,
        vo2max_trend: vo2max_trend
      )

      context = builder.build_performance_context

      expect(context).to include('improving')
    end

    it 'handles nil metrics gracefully' do
      builder = described_class.new(performance_metrics: nil)
      context = builder.build_performance_context

      expect(context).to include('No performance data')
    end
  end

  describe '#build_all' do
    let(:daily_health) do
      Garmin::DailyHealth.new(
        date: date,
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

    it 'returns all three contexts' do
      builder = described_class.new(daily_health: daily_health)
      result = builder.build_all

      expect(result).to have_key(:health_context)
      expect(result).to have_key(:activity_context)
      expect(result).to have_key(:performance_context)
    end
  end
end
