# typed: false
# frozen_string_literal: true

require 'rails_helper'
require 'tmpdir'

RSpec.describe 'Garmin parquet queries' do
  def write_parquet(path, select_sql)
    FileUtils.mkdir_p(File.dirname(path))
    conn = DuckDB::Database.open.connect
    conn.query("COPY (#{select_sql}) TO '#{path}' (FORMAT PARQUET)")
    conn.close
  end

  it 'queries activities from parquet' do
    Dir.mktmpdir do |base|
      write_parquet(
        File.join(base, 'activities', '2024-W01.parquet'),
        <<~SQL
          SELECT
            1::BIGINT AS activity_id,
            'Morning Run' AS activity_name,
            'running' AS activity_type,
            TIMESTAMP '2024-12-30 07:00:00' AS start_time_local,
            2700::DOUBLE AS duration_sec,
            8000::DOUBLE AS distance_m,
            148::INTEGER AS avg_hr,
            172::INTEGER AS max_hr,
            2.96::DOUBLE AS avg_speed,
            120::DOUBLE AS elevation_gain,
            170::DOUBLE AS avg_cadence,
            'Central Park' AS location_name
        SQL
      )

      connection = Garmin::Connection.new(base)
      activities = Garmin::Queries::Activities.new(connection).recent(limit: 1)

      expect(activities.length).to eq(1)
      expect(activities.first.activity_name).to eq('Morning Run')
    end
  end

  it 'queries daily health from parquet' do
    Dir.mktmpdir do |base|
      write_parquet(
        File.join(base, 'daily_health', '2024-12.parquet'),
        <<~SQL
          SELECT
            DATE '2024-12-31' AS date,
            8423::INTEGER AS steps,
            18000::INTEGER AS sleep_seconds,
            79::INTEGER AS sleep_score,
            35::INTEGER AS avg_stress,
            91::INTEGER AS body_battery_end,
            52::INTEGER AS hrv_last_night,
            'BALANCED' AS hrv_status
        SQL
      )

      connection = Garmin::Connection.new(base)
      health = Garmin::Queries::DailyHealth.new(connection).for_date(Date.parse('2024-12-31'))

      expect(health).not_to be_nil
      expect(health.steps).to eq(8423)
      expect(health.sleep_score).to eq(79)
    end
  end

  it 'queries performance metrics from parquet' do
    Dir.mktmpdir do |base|
      write_parquet(
        File.join(base, 'performance_metrics', '2024-12.parquet'),
        <<~SQL
          SELECT
            DATE '2024-12-31' AS date,
            52.3::DOUBLE AS vo2max,
            87::INTEGER AS training_readiness,
            'HIGH' AS training_readiness_level,
            'PRODUCTIVE' AS training_status,
            420::DOUBLE AS acute_load,
            380::DOUBLE AS chronic_load,
            1.11::DOUBLE AS load_ratio,
            'BALANCED' AS load_ratio_status,
            'ENDURANCE' AS load_focus
        SQL
      )

      connection = Garmin::Connection.new(base)
      metrics = Garmin::Queries::Performance.new(connection).latest

      expect(metrics).not_to be_nil
      expect(metrics.vo2max).to be_within(0.1).of(52.3)
      expect(metrics.training_status).to eq('PRODUCTIVE')
    end
  end
end
