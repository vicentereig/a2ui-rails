# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Garmin::Queries::Performance do
  let(:connection) { Garmin::Connection.new(':memory:') }
  let(:queries) { described_class.new(connection) }

  before do
    # Set up test schema matching garmin-cli
    connection.execute(<<~SQL)
      CREATE TABLE performance_metrics (
        id BIGINT PRIMARY KEY,
        profile_id INTEGER,
        date DATE NOT NULL,
        vo2max DOUBLE,
        fitness_age INTEGER,
        training_readiness INTEGER,
        training_readiness_level TEXT,
        training_status TEXT,
        acute_load DOUBLE,
        chronic_load DOUBLE,
        load_ratio DOUBLE,
        load_ratio_status TEXT,
        load_focus TEXT,
        lactate_threshold_hr INTEGER,
        race_5k_sec INTEGER,
        race_10k_sec INTEGER,
        race_half_sec INTEGER,
        race_marathon_sec INTEGER,
        raw_json JSON
      )
    SQL

    # Insert test data
    connection.execute(<<~SQL)
      INSERT INTO performance_metrics VALUES
        (1, 1, '2024-12-30', 48.5, 32, 67, 'MODERATE', 'PRODUCTIVE', 487, 412, 1.18, 'OPTIMAL', 'AEROBIC_BASE', 162, 1380, 2880, 6300, 13200, '{}'),
        (2, 1, '2024-12-29', 48.3, 32, 72, 'HIGH', 'PRODUCTIVE', 465, 408, 1.14, 'OPTIMAL', 'AEROBIC_BASE', 162, 1385, 2890, 6320, 13250, '{}'),
        (3, 1, '2024-12-28', 48.2, 33, 58, 'LOW', 'STRAINED', 520, 405, 1.28, 'HIGH', 'ANAEROBIC_SHORTAGE', 161, 1390, 2900, 6350, 13300, '{}'),
        (4, 1, '2024-12-20', 47.8, 33, 75, 'HIGH', 'PRODUCTIVE', 380, 395, 0.96, 'OPTIMAL', 'BALANCED', 160, 1410, 2940, 6420, 13450, '{}')
    SQL
  end

  describe '#for_date' do
    it 'returns performance metrics for a specific date' do
      metrics = queries.for_date(Date.parse('2024-12-30'))

      expect(metrics.vo2max).to eq(48.5)
      expect(metrics.training_status).to eq('PRODUCTIVE')
      expect(metrics.acute_load).to eq(487)
      expect(metrics.chronic_load).to eq(412)
    end

    it 'returns nil for date with no data' do
      metrics = queries.for_date(Date.parse('2024-01-01'))
      expect(metrics).to be_nil
    end
  end

  describe '#training_load_status' do
    it 'returns current training load analysis' do
      status = queries.training_load_status

      expect(status.acute_load).to eq(487)
      expect(status.chronic_load).to eq(412)
      expect(status.ratio).to be_within(0.01).of(1.18)
      expect(status.status).to eq('OPTIMAL')
      expect(status.focus).to eq('AEROBIC_BASE')
      expect(status.training_status).to eq('PRODUCTIVE')
    end
  end

  describe '#vo2max_trend' do
    it 'calculates VO2 max trend over time' do
      trend = queries.vo2max_trend(days: 30)

      expect(trend.current).to eq(48.5)
      expect(trend.change_30d).to be_within(0.1).of(0.7) # 48.5 - 47.8
      expect(trend.direction).to eq(:improving)
    end
  end

  describe '#race_predictions' do
    it 'returns current race time predictions' do
      predictions = queries.race_predictions

      expect(predictions.five_k).to eq('23:00') # 1380 seconds formatted
      expect(predictions.ten_k).to eq('48:00')
      expect(predictions.half_marathon).to eq('1:45:00')
      expect(predictions.marathon).to eq('3:40:00')
    end
  end

  describe '#training_readiness' do
    it 'returns training readiness assessment' do
      readiness = queries.training_readiness(Date.parse('2024-12-30'))

      expect(readiness.score).to eq(67)
      expect(readiness.level).to eq('MODERATE')
      expect(readiness.recommendation).to be_a(String)
    end
  end
end
