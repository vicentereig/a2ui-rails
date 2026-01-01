# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Garmin::Queries::Performance do
  let(:connection) { Garmin::Connection.new(':memory:') }
  let(:queries) { described_class.new(connection) }

  before do
    # Set up test schema matching garmin-cli Parquet format
    connection.execute(<<~SQL)
      CREATE TABLE performance_metrics (
        id BIGINT PRIMARY KEY,
        profile_id INTEGER,
        date DATE NOT NULL,
        vo2max DOUBLE,
        fitness_age INTEGER,
        training_readiness INTEGER,
        training_status TEXT,
        lactate_threshold_hr INTEGER,
        lactate_threshold_pace DOUBLE,
        race_5k_sec INTEGER,
        race_10k_sec INTEGER,
        race_half_sec INTEGER,
        race_marathon_sec INTEGER,
        endurance_score INTEGER,
        hill_score INTEGER,
        raw_json JSON
      )
    SQL

    # Insert test data
    connection.execute(<<~SQL)
      INSERT INTO performance_metrics VALUES
        (1, 1, '2024-12-30', 48.5, 32, 67, 'PRODUCTIVE', 162, 4.5, 1380, 2880, 6300, 13200, 78, 65, '{}'),
        (2, 1, '2024-12-29', 48.3, 32, 72, 'PRODUCTIVE', 162, 4.5, 1385, 2890, 6320, 13250, 77, 64, '{}'),
        (3, 1, '2024-12-28', 48.2, 33, 38, 'STRAINED', 161, 4.6, 1390, 2900, 6350, 13300, 75, 62, '{}'),
        (4, 1, '2024-12-20', 47.8, 33, 75, 'PRODUCTIVE', 160, 4.7, 1410, 2940, 6420, 13450, 74, 60, '{}')
    SQL
  end

  describe '#for_date' do
    it 'returns performance metrics for a specific date' do
      metrics = queries.for_date(Date.parse('2024-12-30'))

      expect(metrics.vo2max).to eq(48.5)
      expect(metrics.training_status).to eq('PRODUCTIVE')
      expect(metrics.endurance_score).to eq(78)
      expect(metrics.hill_score).to eq(65)
      expect(metrics.lactate_threshold_pace).to eq(4.5)
    end

    it 'returns nil for date with no data' do
      metrics = queries.for_date(Date.parse('2024-01-01'))
      expect(metrics).to be_nil
    end
  end

  describe '#training_status_summary' do
    it 'returns current training status' do
      status = queries.training_status_summary

      expect(status.training_status).to eq('PRODUCTIVE')
      expect(status.training_readiness).to eq(67)
      expect(status.endurance_score).to eq(78)
      expect(status.hill_score).to eq(65)
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
    it 'returns training readiness assessment with HIGH level' do
      readiness = queries.training_readiness(Date.parse('2024-12-29'))

      expect(readiness.score).to eq(72)
      expect(readiness.level).to eq('HIGH')
      expect(readiness.recommendation).to include('hard workout')
    end

    it 'returns training readiness assessment with MODERATE level' do
      readiness = queries.training_readiness(Date.parse('2024-12-30'))

      expect(readiness.score).to eq(67)
      expect(readiness.level).to eq('MODERATE')
      expect(readiness.recommendation).to include('moderate effort')
    end

    it 'returns training readiness assessment with LOW level' do
      readiness = queries.training_readiness(Date.parse('2024-12-28'))

      expect(readiness.score).to eq(38)
      expect(readiness.level).to eq('LOW')
      expect(readiness.recommendation).to include('recovery')
    end
  end
end
