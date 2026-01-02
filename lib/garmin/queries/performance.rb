# typed: strict
# frozen_string_literal: true

module Garmin
  module Queries
    class Performance
      extend T::Sig

      sig { params(connection: Connection).void }
      def initialize(connection)
        @connection = connection
      end

      sig { params(as_of: T.nilable(Date)).returns(T.nilable(PerformanceMetrics)) }
      def latest(as_of: nil)
        table = @connection.table_sql('performance_metrics')
        date_filter = as_of ? "WHERE date <= '#{as_of}'" : ''
        rows = @connection.query(<<~SQL)
          SELECT * FROM #{table}
          #{date_filter}
          ORDER BY date DESC
          LIMIT 1
        SQL

        return nil if rows.empty?

        row_to_metrics(rows.first)
      end

      sig { params(date: Date).returns(T.nilable(PerformanceMetrics)) }
      def for_date(date)
        table = @connection.table_sql('performance_metrics')
        rows = @connection.query(<<~SQL)
          SELECT * FROM #{table}
          WHERE date = '#{date}'
          LIMIT 1
        SQL

        return nil if rows.empty?

        row_to_metrics(rows.first)
      end

      sig { params(as_of: T.nilable(Date)).returns(T.nilable(TrainingStatusSummary)) }
      def training_status_summary(as_of: nil)
        metrics = latest(as_of: as_of)
        return nil unless metrics

        TrainingStatusSummary.new(
          training_status: metrics.training_status || 'UNKNOWN',
          training_readiness: metrics.training_readiness || 0,
          endurance_score: metrics.endurance_score,
          hill_score: metrics.hill_score
        )
      end

      sig { params(days: Integer, as_of: T.nilable(Date)).returns(VO2MaxTrend) }
      def vo2max_trend(days: 30, as_of: nil)
        days = days.to_i
        table = @connection.table_sql('performance_metrics')
        date_filter = as_of ? "AND date <= '#{as_of}'" : ''
        rows = @connection.query(<<~SQL)
          SELECT vo2max, date FROM #{table}
          WHERE vo2max IS NOT NULL
          #{date_filter}
          ORDER BY date DESC
          LIMIT #{days}
        SQL

        return VO2MaxTrend.new(current: 0.0, change_30d: 0.0, direction: :stable) if rows.empty?

        current = rows.first['vo2max'].to_f
        oldest = rows.last['vo2max'].to_f
        change = current - oldest

        direction = if change > 0.5
                      :improving
                    elsif change < -0.5
                      :declining
                    else
                      :stable
                    end

        VO2MaxTrend.new(
          current: current,
          change_30d: change,
          direction: direction
        )
      end

      sig { params(as_of: T.nilable(Date)).returns(T.nilable(RacePredictions)) }
      def race_predictions(as_of: nil)
        metrics = latest(as_of: as_of)
        return nil unless metrics

        RacePredictions.new(
          five_k: format_time(metrics.race_5k_sec),
          ten_k: format_time(metrics.race_10k_sec),
          half_marathon: format_time(metrics.race_half_sec),
          marathon: format_time(metrics.race_marathon_sec)
        )
      end

      sig { params(date: Date).returns(TrainingReadiness) }
      def training_readiness(date)
        metrics = for_date(date)
        raise "No performance data for #{date}" unless metrics

        score = metrics.training_readiness || 0

        # Derive level from score (Garmin uses 0-100 scale)
        level = if score >= 70
                  'HIGH'
                elsif score >= 40
                  'MODERATE'
                elsif score > 0
                  'LOW'
                else
                  'UNKNOWN'
                end

        recommendation = case level
                         when 'HIGH' then 'Great day for a hard workout or race.'
                         when 'MODERATE' then 'Consider a moderate effort today.'
                         when 'LOW' then 'Focus on recovery or easy activity.'
                         else 'Listen to your body.'
                         end

        TrainingReadiness.new(
          score: score,
          level: level,
          recommendation: recommendation
        )
      end

      private

      sig { params(row: T::Hash[String, T.untyped]).returns(PerformanceMetrics) }
      def row_to_metrics(row)
        date_value = row['date']
        parsed_date = case date_value
                      when Date then date_value
                      when String then Date.parse(date_value)
                      else Date.today
                      end

        PerformanceMetrics.new(
          date: parsed_date,
          vo2max: row['vo2max']&.to_f,
          fitness_age: row['fitness_age']&.to_i,
          training_readiness: row['training_readiness']&.to_i,
          training_status: row['training_status'],
          lactate_threshold_hr: row['lactate_threshold_hr']&.to_i,
          lactate_threshold_pace: row['lactate_threshold_pace']&.to_f,
          race_5k_sec: row['race_5k_sec']&.to_i,
          race_10k_sec: row['race_10k_sec']&.to_i,
          race_half_sec: row['race_half_sec']&.to_i,
          race_marathon_sec: row['race_marathon_sec']&.to_i,
          endurance_score: row['endurance_score']&.to_i,
          hill_score: row['hill_score']&.to_i
        )
      end

      sig { params(seconds: T.nilable(Integer)).returns(String) }
      def format_time(seconds)
        return '0:00' unless seconds

        hours = seconds / 3600
        mins = (seconds % 3600) / 60
        secs = seconds % 60

        if hours > 0
          format('%d:%02d:%02d', hours, mins, secs)
        else
          format('%d:%02d', mins, secs)
        end
      end
    end
  end
end
