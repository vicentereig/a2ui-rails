# typed: strict
# frozen_string_literal: true

module Garmin
  module Queries
    class Activities
      extend T::Sig

      sig { params(connection: Connection).void }
      def initialize(connection)
        @connection = connection
      end

      sig { params(limit: Integer, as_of: T.nilable(Date)).returns(T::Array[Activity]) }
      def recent(limit: 10, as_of: nil)
        limit = limit.to_i
        table = @connection.table_sql('activities')
        date_filter = as_of ? "WHERE DATE(start_time_local) <= '#{as_of}'" : ''
        rows = @connection.query(<<~SQL)
          SELECT * FROM #{table}
          #{date_filter}
          ORDER BY start_time_local DESC
          LIMIT #{limit}
        SQL

        rows.map { |row| row_to_activity(row) }
      end

      sig { params(type: String).returns(T::Array[Activity]) }
      def by_type(type)
        table = @connection.table_sql('activities')
        type = @connection.quote_string(type)
        rows = @connection.query(<<~SQL)
          SELECT * FROM #{table}
          WHERE activity_type = '#{type}'
          ORDER BY start_time_local DESC
        SQL

        rows.map { |row| row_to_activity(row) }
      end

      sig { params(from: Date, to: Date).returns(T::Array[Activity]) }
      def in_date_range(from:, to:)
        table = @connection.table_sql('activities')
        rows = @connection.query(<<~SQL)
          SELECT * FROM #{table}
          WHERE DATE(start_time_local) >= '#{from}'
            AND DATE(start_time_local) <= '#{to}'
          ORDER BY start_time_local DESC
        SQL

        rows.map { |row| row_to_activity(row) }
      end

      sig { params(id: Integer).returns(T.nilable(Activity)) }
      def find(id)
        table = @connection.table_sql('activities')
        rows = @connection.query(<<~SQL)
          SELECT * FROM #{table}
          WHERE activity_id = #{id}
          LIMIT 1
        SQL

        return nil if rows.empty?

        row_to_activity(rows.first)
      end

      sig { params(date: Date).returns(T.nilable(ActivityStats)) }
      def week_stats(date)
        from = date - 6
        to = date
        table = @connection.table_sql('activities')

        rows = @connection.query(<<~SQL)
          SELECT
            COALESCE(SUM(distance_m), 0) as total_distance_m,
            COALESCE(SUM(duration_sec), 0) as total_duration_sec,
            COUNT(*) as activity_count
          FROM #{table}
          WHERE DATE(start_time_local) >= '#{from}'
            AND DATE(start_time_local) <= '#{to}'
        SQL

        row = rows.first
        return nil if row['activity_count'].to_i == 0

        total_distance = row['total_distance_m'].to_f
        total_duration = row['total_duration_sec'].to_f

        avg_pace = if total_distance > 0
                     (total_duration / 60.0) / (total_distance / 1000.0)
                   else
                     0.0
                   end

        ActivityStats.new(
          total_distance_m: total_distance,
          total_duration_sec: total_duration,
          activity_count: row['activity_count'].to_i,
          avg_pace_per_km: avg_pace
        )
      end

      sig { params(from: Date, to: Date, activity_type: String).returns(ActivityStats) }
      def stats_for_period(from:, to:, activity_type:)
        table = @connection.table_sql('activities')
        activity_type = @connection.quote_string(activity_type)
        rows = @connection.query(<<~SQL)
          SELECT
            COALESCE(SUM(distance_m), 0) as total_distance_m,
            COALESCE(SUM(duration_sec), 0) as total_duration_sec,
            COUNT(*) as activity_count
          FROM #{table}
          WHERE DATE(start_time_local) >= '#{from}'
            AND DATE(start_time_local) <= '#{to}'
            AND activity_type = '#{activity_type}'
        SQL

        row = rows.first
        total_distance = row['total_distance_m'].to_f
        total_duration = row['total_duration_sec'].to_f
        count = row['activity_count'].to_i

        # Calculate average pace (min/km)
        avg_pace = if total_distance > 0
                     (total_duration / 60.0) / (total_distance / 1000.0)
                   else
                     0.0
                   end

        ActivityStats.new(
          total_distance_m: total_distance,
          total_duration_sec: total_duration,
          activity_count: count,
          avg_pace_per_km: avg_pace
        )
      end

      private

      sig { params(row: T::Hash[String, T.untyped]).returns(Activity) }
      def row_to_activity(row)
        start_time = row['start_time_local']
        parsed_time = case start_time
                      when Time then start_time
                      when String then Time.parse(start_time)
                      else nil
                      end

        Activity.new(
          activity_id: row['activity_id'].to_i,
          activity_name: row['activity_name'],
          activity_type: row['activity_type'],
          start_time_local: parsed_time,
          duration_sec: row['duration_sec']&.to_f,
          distance_m: row['distance_m']&.to_f,
          calories: row['calories']&.to_i,
          avg_hr: row['avg_hr']&.to_i,
          max_hr: row['max_hr']&.to_i,
          avg_speed: row['avg_speed']&.to_f,
          elevation_gain: row['elevation_gain']&.to_f,
          avg_cadence: row['avg_cadence']&.to_f,
          location_name: row['location_name']
        )
      end
    end
  end
end
