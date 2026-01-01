# typed: strict
# frozen_string_literal: true

module Garmin
  module Queries
    class DailyHealth
      extend T::Sig

      sig { params(connection: Connection).void }
      def initialize(connection)
        @connection = connection
      end

      sig { params(date: Date).returns(T.nilable(Garmin::DailyHealth)) }
      def for_date(date)
        table = @connection.table_sql('daily_health')
        rows = @connection.query(<<~SQL)
          SELECT * FROM #{table}
          WHERE date = '#{date}'
          LIMIT 1
        SQL

        return nil if rows.empty?

        row_to_health(rows.first)
      end

      sig { params(days: Integer).returns(T::Array[Garmin::DailyHealth]) }
      def recent(days: 7)
        days = days.to_i
        table = @connection.table_sql('daily_health')
        rows = @connection.query(<<~SQL)
          SELECT * FROM #{table}
          ORDER BY date DESC
          LIMIT #{days}
        SQL

        rows.map { |row| row_to_health(row) }
      end

      sig { params(days: Integer).returns(SleepTrend) }
      def sleep_trend(days: 7)
        days = days.to_i
        table = @connection.table_sql('daily_health')
        rows = @connection.query(<<~SQL)
          SELECT
            AVG(sleep_score) as avg_score,
            AVG(sleep_seconds) as avg_seconds
          FROM (
            SELECT sleep_score, sleep_seconds FROM #{table}
            ORDER BY date DESC
            LIMIT #{days}
          )
        SQL

        row = rows.first
        avg_score = row['avg_score']&.to_f || 0.0
        avg_hours = (row['avg_seconds']&.to_f || 0.0) / 3600.0

        # Calculate consecutive good nights (score >= 75)
        consecutive = calculate_consecutive_good_nights(days)

        # Determine trend direction
        direction = calculate_trend_direction(days)

        SleepTrend.new(
          avg_sleep_score: avg_score,
          avg_sleep_hours: avg_hours,
          trend_direction: direction,
          consecutive_good_nights: consecutive
        )
      end

      sig { params(date: Date).returns(T.nilable(RecoveryStatus)) }
      def recovery_status(date)
        health = for_date(date)
        return nil unless health

        readiness = determine_readiness(health)

        RecoveryStatus.new(
          body_battery: health.body_battery_end || 0,
          hrv_status: health.hrv_status || 'UNKNOWN',
          resting_hr: health.resting_hr || 0,
          stress_level: health.avg_stress || 0,
          readiness: readiness
        )
      end

      sig { params(date: Date, baseline_days: Integer).returns(BaselineComparison) }
      def compare_to_baseline(date:, baseline_days: 7)
        current = for_date(date)
        raise "No health data for #{date}" unless current

        baseline_days = baseline_days.to_i
        table = @connection.table_sql('daily_health')
        # Get baseline averages
        baseline = @connection.query(<<~SQL)
          SELECT
            AVG(sleep_score) as avg_sleep,
            AVG(steps) as avg_steps,
            AVG(avg_stress) as avg_stress
          FROM (
            SELECT sleep_score, steps, avg_stress FROM #{table}
            WHERE date < '#{date}'
            ORDER BY date DESC
            LIMIT #{baseline_days}
          )
        SQL

        row = baseline.first
        avg_sleep = row['avg_sleep']&.to_f || 0.0
        avg_steps = row['avg_steps']&.to_f || 0.0
        avg_stress = row['avg_stress']&.to_f || 0.0

        sleep_diff = avg_sleep > 0 ? ((current.sleep_score || 0) - avg_sleep) / avg_sleep * 100 : 0.0
        steps_diff = avg_steps > 0 ? ((current.steps || 0) - avg_steps) / avg_steps * 100 : 0.0
        stress_diff = avg_stress > 0 ? ((current.avg_stress || 0) - avg_stress) / avg_stress * 100 : 0.0

        BaselineComparison.new(
          sleep_vs_baseline: sleep_diff,
          steps_vs_baseline: steps_diff,
          stress_vs_baseline: stress_diff
        )
      end

      private

      sig { params(row: T::Hash[String, T.untyped]).returns(Garmin::DailyHealth) }
      def row_to_health(row)
        date_value = row['date']
        parsed_date = case date_value
                      when Date then date_value
                      when String then Date.parse(date_value)
                      else Date.today
                      end

        Garmin::DailyHealth.new(
          date: parsed_date,
          steps: row['steps']&.to_i,
          step_goal: row['step_goal']&.to_i,
          total_calories: row['total_calories']&.to_i,
          active_calories: row['active_calories']&.to_i,
          bmr_calories: row['bmr_calories']&.to_i,
          resting_hr: row['resting_hr']&.to_i,
          sleep_seconds: row['sleep_seconds']&.to_i,
          deep_sleep_seconds: row['deep_sleep_seconds']&.to_i,
          light_sleep_seconds: row['light_sleep_seconds']&.to_i,
          rem_sleep_seconds: row['rem_sleep_seconds']&.to_i,
          sleep_score: row['sleep_score']&.to_i,
          avg_stress: row['avg_stress']&.to_i,
          max_stress: row['max_stress']&.to_i,
          body_battery_start: row['body_battery_start']&.to_i,
          body_battery_end: row['body_battery_end']&.to_i,
          hrv_weekly_avg: row['hrv_weekly_avg']&.to_i,
          hrv_last_night: row['hrv_last_night']&.to_i,
          hrv_status: row['hrv_status'],
          avg_respiration: row['avg_respiration']&.to_f,
          avg_spo2: row['avg_spo2']&.to_i,
          lowest_spo2: row['lowest_spo2']&.to_i,
          hydration_ml: row['hydration_ml']&.to_i,
          moderate_intensity_min: row['moderate_intensity_min']&.to_i,
          vigorous_intensity_min: row['vigorous_intensity_min']&.to_i
        )
      end

      sig { params(days: Integer).returns(Integer) }
      def calculate_consecutive_good_nights(days)
        days = days.to_i
        table = @connection.table_sql('daily_health')
        rows = @connection.query(<<~SQL)
          SELECT sleep_score FROM #{table}
          ORDER BY date DESC
          LIMIT #{days}
        SQL

        consecutive = 0
        rows.each do |row|
          score = row['sleep_score']&.to_i || 0
          if score >= 75
            consecutive += 1
          else
            break
          end
        end
        consecutive
      end

      sig { params(days: Integer).returns(Symbol) }
      def calculate_trend_direction(days)
        days = days.to_i
        table = @connection.table_sql('daily_health')
        rows = @connection.query(<<~SQL)
          SELECT sleep_score, date FROM #{table}
          ORDER BY date DESC
          LIMIT #{days}
        SQL

        return :stable if rows.length < 3

        recent_avg = rows.take(3).map { |r| r['sleep_score']&.to_i || 0 }.sum / 3.0
        older_avg = rows.drop(3).map { |r| r['sleep_score']&.to_i || 0 }.sum / [rows.length - 3, 1].max.to_f

        diff = recent_avg - older_avg
        if diff > 3
          :improving
        elsif diff < -3
          :declining
        else
          :stable
        end
      end

      sig { params(health: Garmin::DailyHealth).returns(Symbol) }
      def determine_readiness(health)
        score = 0
        score += 2 if (health.body_battery_end || 0) >= 80
        score += 2 if health.hrv_status == 'BALANCED'
        score += 1 if (health.sleep_score || 0) >= 75
        score += 1 if (health.avg_stress || 100) <= 35

        if score >= 5
          :ready
        elsif score >= 3
          :moderate
        else
          :low
        end
      end
    end
  end
end
