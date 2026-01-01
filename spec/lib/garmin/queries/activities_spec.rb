# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Garmin::Queries::Activities do
  let(:connection) { Garmin::Connection.new(':memory:') }
  let(:queries) { described_class.new(connection) }

  before do
    # Set up test schema matching garmin-cli
    connection.execute(<<~SQL)
      CREATE TABLE activities (
        activity_id BIGINT PRIMARY KEY,
        profile_id INTEGER,
        activity_name TEXT,
        activity_type TEXT,
        start_time_local TIMESTAMP,
        start_time_gmt TIMESTAMP,
        duration_sec DOUBLE,
        distance_m DOUBLE,
        calories INTEGER,
        avg_hr INTEGER,
        max_hr INTEGER,
        avg_speed DOUBLE,
        max_speed DOUBLE,
        elevation_gain DOUBLE,
        elevation_loss DOUBLE,
        avg_cadence DOUBLE,
        location_name TEXT,
        raw_json JSON
      )
    SQL

    # Insert test data
    connection.execute(<<~SQL)
      INSERT INTO activities VALUES
        (1, 1, 'Morning Run', 'running', '2024-12-30 07:00:00', '2024-12-30 15:00:00', 2700, 8000, 450, 148, 172, 2.96, 3.5, 120, 115, 170, 'Central Park', '{}'),
        (2, 1, 'Easy Jog', 'running', '2024-12-28 06:30:00', '2024-12-28 14:30:00', 1800, 5000, 280, 135, 155, 2.78, 3.2, 50, 45, 165, 'Riverside', '{}'),
        (3, 1, 'Bike Commute', 'cycling', '2024-12-29 08:00:00', '2024-12-29 16:00:00', 1200, 10000, 200, 120, 140, 8.33, 12.0, 80, 75, NULL, 'Downtown', '{}')
    SQL
  end

  describe '#recent' do
    it 'returns recent activities ordered by date descending' do
      activities = queries.recent(limit: 2)

      expect(activities.length).to eq(2)
      expect(activities.first.activity_name).to eq('Morning Run')
      expect(activities.last.activity_name).to eq('Bike Commute')
    end

    it 'returns all activities when limit exceeds count' do
      activities = queries.recent(limit: 10)
      expect(activities.length).to eq(3)
    end
  end

  describe '#by_type' do
    it 'filters activities by type' do
      runs = queries.by_type('running')
      expect(runs.length).to eq(2)
      expect(runs.map(&:activity_type).uniq).to eq(['running'])
    end

    it 'returns empty array for unknown type' do
      activities = queries.by_type('swimming')
      expect(activities).to eq([])
    end
  end

  describe '#in_date_range' do
    it 'filters activities within date range' do
      activities = queries.in_date_range(
        from: Date.parse('2024-12-29'),
        to: Date.parse('2024-12-30')
      )

      expect(activities.length).to eq(2)
      expect(activities.map(&:activity_name)).to include('Morning Run', 'Bike Commute')
    end
  end

  describe '#find' do
    it 'returns a single activity by ID' do
      activity = queries.find(1)

      expect(activity.activity_id).to eq(1)
      expect(activity.activity_name).to eq('Morning Run')
      expect(activity.distance_m).to eq(8000)
      expect(activity.duration_sec).to eq(2700)
    end

    it 'returns nil for non-existent ID' do
      activity = queries.find(999)
      expect(activity).to be_nil
    end
  end

  describe '#stats_for_period' do
    it 'calculates aggregate stats for a date range' do
      stats = queries.stats_for_period(
        from: Date.parse('2024-12-01'),
        to: Date.parse('2024-12-31'),
        activity_type: 'running'
      )

      expect(stats.total_distance_m).to eq(13000) # 8000 + 5000
      expect(stats.total_duration_sec).to eq(4500) # 2700 + 1800
      expect(stats.activity_count).to eq(2)
      expect(stats.avg_pace_per_km).to be_within(0.1).of(5.77) # min/km
    end
  end
end
