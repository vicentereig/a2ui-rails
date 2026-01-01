# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Garmin::Queries::DailyHealth do
  let(:connection) { Garmin::Connection.new(':memory:') }
  let(:queries) { described_class.new(connection) }

  before do
    # Set up test schema matching garmin-cli
    connection.execute(<<~SQL)
      CREATE TABLE daily_health (
        id BIGINT PRIMARY KEY,
        profile_id INTEGER,
        date DATE NOT NULL,
        steps INTEGER,
        step_goal INTEGER,
        total_calories INTEGER,
        active_calories INTEGER,
        resting_hr INTEGER,
        sleep_seconds INTEGER,
        deep_sleep_seconds INTEGER,
        light_sleep_seconds INTEGER,
        rem_sleep_seconds INTEGER,
        sleep_score INTEGER,
        avg_stress INTEGER,
        max_stress INTEGER,
        body_battery_start INTEGER,
        body_battery_end INTEGER,
        hrv_weekly_avg INTEGER,
        hrv_last_night INTEGER,
        hrv_status TEXT,
        raw_json JSON
      )
    SQL

    # Insert test data - last 7 days
    connection.execute(<<~SQL)
      INSERT INTO daily_health VALUES
        (1, 1, '2024-12-30', 10500, 10000, 2200, 800, 52, 27000, 7200, 14400, 5400, 82, 32, 65, 45, 91, 52, 54, 'BALANCED', '{}'),
        (2, 1, '2024-12-29', 8200, 10000, 2000, 600, 54, 25200, 6000, 13200, 6000, 78, 38, 72, 38, 85, 50, 48, 'BALANCED', '{}'),
        (3, 1, '2024-12-28', 12000, 10000, 2400, 950, 51, 28800, 7800, 15000, 6000, 85, 28, 55, 52, 95, 53, 56, 'BALANCED', '{}'),
        (4, 1, '2024-12-27', 6500, 10000, 1800, 400, 55, 21600, 5400, 12000, 4200, 68, 45, 78, 32, 72, 48, 42, 'LOW', '{}'),
        (5, 1, '2024-12-26', 9800, 10000, 2100, 750, 53, 26400, 6600, 14400, 5400, 79, 35, 68, 40, 88, 51, 52, 'BALANCED', '{}')
    SQL
  end

  describe '#for_date' do
    it 'returns health data for a specific date' do
      health = queries.for_date(Date.parse('2024-12-30'))

      expect(health.steps).to eq(10500)
      expect(health.sleep_score).to eq(82)
      expect(health.body_battery_end).to eq(91)
      expect(health.hrv_status).to eq('BALANCED')
    end

    it 'returns nil for date with no data' do
      health = queries.for_date(Date.parse('2024-01-01'))
      expect(health).to be_nil
    end
  end

  describe '#recent' do
    it 'returns recent health data ordered by date descending' do
      health_data = queries.recent(days: 3)

      expect(health_data.length).to eq(3)
      expect(health_data.first.date).to eq(Date.parse('2024-12-30'))
      expect(health_data.last.date).to eq(Date.parse('2024-12-28'))
    end
  end

  describe '#sleep_trend' do
    it 'calculates sleep trends over a period' do
      trend = queries.sleep_trend(days: 5)

      expect(trend.avg_sleep_score).to be_within(1).of(78.4)
      expect(trend.avg_sleep_hours).to be_within(0.1).of(7.2)
      expect(trend.trend_direction).to be_in([:improving, :stable, :declining])
      expect(trend.consecutive_good_nights).to be >= 0
    end
  end

  describe '#recovery_status' do
    it 'returns current recovery indicators' do
      status = queries.recovery_status(Date.parse('2024-12-30'))

      expect(status.body_battery).to eq(91)
      expect(status.hrv_status).to eq('BALANCED')
      expect(status.resting_hr).to eq(52)
      expect(status.stress_level).to eq(32)
      expect(status.readiness).to be_in([:ready, :moderate, :low])
    end
  end

  describe '#compare_to_baseline' do
    it 'compares current metrics to rolling baseline' do
      comparison = queries.compare_to_baseline(
        date: Date.parse('2024-12-30'),
        baseline_days: 7
      )

      expect(comparison.sleep_vs_baseline).to be_a(Float) # percentage diff
      expect(comparison.steps_vs_baseline).to be_a(Float)
      expect(comparison.stress_vs_baseline).to be_a(Float)
    end
  end
end
