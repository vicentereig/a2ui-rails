# typed: strict
# frozen_string_literal: true

module Garmin
  # Signal types for Garmin data changes
  module Signals
    extend T::Sig

    # Priority level for signals
    class SignalPriority < T::Enum
      enums do
        Low = new('low')           # Background info, can be batched
        Medium = new('medium')     # Worth showing but not urgent
        High = new('high')         # Should be surfaced soon
        Urgent = new('urgent')     # Requires immediate attention
      end
    end

    # Type of data change detected
    class ChangeType < T::Enum
      enums do
        NewActivity = new('new_activity')
        DailyMetrics = new('daily_metrics')
        SleepData = new('sleep_data')
        PerformanceUpdate = new('performance_update')
        ThresholdCrossed = new('threshold_crossed')
      end
    end

    # A signal representing a meaningful change in Garmin data
    class DataSignal < T::Struct
      const :id, String, description: 'Unique signal identifier'
      const :change_type, ChangeType, description: 'Type of data change'
      const :priority, SignalPriority, description: 'How urgent is this signal'
      const :title, String, description: 'Short title for the signal'
      const :summary, String, description: 'Brief description of what changed'
      const :data_path, String, description: 'Path to the affected data (e.g., /activities/123)'
      const :timestamp, Time, description: 'When the change was detected'
      const :metadata, T::Hash[String, T.untyped], default: {}, description: 'Additional context'
    end

    # Evaluates whether a data point is significant enough to surface
    class SignificanceEvaluator
      extend T::Sig

      # Use T.untyped for connection to allow mocking in tests
      sig { params(connection: T.untyped).void }
      def initialize(connection)
        @connection = connection
        # Use T.untyped to allow mocking in tests
        @health_query = T.let(Garmin::Queries::DailyHealth.new(connection), T.untyped)
        @activities_query = T.let(Garmin::Queries::Activities.new(connection), T.untyped)
        @performance_query = T.let(Garmin::Queries::Performance.new(connection), T.untyped)
      end

      # Check for new activities since last check
      sig { params(since: Time).returns(T::Array[DataSignal]) }
      def detect_new_activities(since:)
        recent = @activities_query.recent(limit: 10)
        return [] unless recent

        signals = []
        recent.each do |activity|
          activity_time = activity[:start_time]
          next unless activity_time && activity_time > since

          priority = evaluate_activity_priority(activity)
          signals << DataSignal.new(
            id: "activity_#{activity[:activity_id]}",
            change_type: ChangeType::NewActivity,
            priority: priority,
            title: "New #{activity[:activity_type] || 'Activity'}",
            summary: format_activity_summary(activity),
            data_path: "/activities/#{activity[:activity_id]}",
            timestamp: activity_time,
            metadata: { 'activity_type' => activity[:activity_type], 'distance' => activity[:distance] }
          )
        end
        signals
      end

      # Check for significant health metric changes
      sig { params(date: Date).returns(T::Array[DataSignal]) }
      def detect_health_changes(date:)
        signals = []

        daily = @health_query.for_date(date)
        return signals unless daily

        # Check HRV against baseline
        hrv_signal = evaluate_hrv_change(daily, date)
        signals << hrv_signal if hrv_signal

        # Check sleep quality
        sleep_signal = evaluate_sleep_change(daily)
        signals << sleep_signal if sleep_signal

        # Check recovery status
        recovery = @health_query.recovery_status(date)
        recovery_signal = evaluate_recovery_signal(recovery, date)
        signals << recovery_signal if recovery_signal

        signals
      end

      # Check for performance metric changes
      sig { returns(T::Array[DataSignal]) }
      def detect_performance_changes
        signals = []

        latest = @performance_query.latest
        return signals unless latest

        # Check VO2max changes
        vo2max_trend = @performance_query.vo2max_trend
        vo2max_signal = evaluate_vo2max_change(vo2max_trend)
        signals << vo2max_signal if vo2max_signal

        # Check training load status
        training_status = @performance_query.training_status_summary
        training_signal = evaluate_training_status(training_status)
        signals << training_signal if training_signal

        signals
      end

      private

      sig { params(activity: T::Hash[Symbol, T.untyped]).returns(SignalPriority) }
      def evaluate_activity_priority(activity)
        # Personal bests or long activities are high priority
        distance = activity[:distance] || 0
        duration = activity[:duration] || 0

        if distance > 20_000 # > 20km
          SignalPriority::High
        elsif duration > 7200 # > 2 hours
          SignalPriority::High
        elsif distance > 10_000 # > 10km
          SignalPriority::Medium
        else
          SignalPriority::Low
        end
      end

      sig { params(activity: T::Hash[Symbol, T.untyped]).returns(String) }
      def format_activity_summary(activity)
        type = activity[:activity_type] || 'Activity'
        distance = activity[:distance]
        duration = activity[:duration]

        parts = [type]
        parts << "#{(distance / 1000.0).round(1)}km" if distance && distance > 0
        parts << format_duration(duration) if duration && duration > 0

        parts.join(' · ')
      end

      sig { params(seconds: T.nilable(Numeric)).returns(String) }
      def format_duration(seconds)
        return '' unless seconds

        hours = (seconds / 3600).to_i
        minutes = ((seconds % 3600) / 60).to_i

        if hours > 0
          "#{hours}h #{minutes}m"
        else
          "#{minutes}m"
        end
      end

      sig { params(daily: T::Hash[Symbol, T.untyped], date: Date).returns(T.nilable(DataSignal)) }
      def evaluate_hrv_change(daily, date)
        hrv = daily[:hrv_value]
        return nil unless hrv

        # Compare to 7-day average
        sleep_trend = @health_query.sleep_trend(days: 7)
        avg_hrv = sleep_trend&.dig(:average_hrv) || hrv

        change_pct = ((hrv - avg_hrv) / avg_hrv.to_f * 100).round(1)

        # Only signal if change is significant (> 15%)
        return nil if change_pct.abs < 15

        priority = change_pct < -20 ? SignalPriority::High : SignalPriority::Medium
        direction = change_pct > 0 ? 'up' : 'down'

        DataSignal.new(
          id: "hrv_#{date.iso8601}",
          change_type: ChangeType::DailyMetrics,
          priority: priority,
          title: "HRV #{direction} #{change_pct.abs}%",
          summary: "Your HRV is #{hrv}ms, #{direction} from #{avg_hrv.round}ms average.",
          data_path: "/health/#{date.iso8601}/hrv",
          timestamp: Time.now,
          metadata: { 'hrv' => hrv, 'avg_hrv' => avg_hrv, 'change_pct' => change_pct }
        )
      end

      sig { params(daily: T::Hash[Symbol, T.untyped]).returns(T.nilable(DataSignal)) }
      def evaluate_sleep_change(daily)
        sleep_hours = daily[:sleep_duration_hours]
        return nil unless sleep_hours

        # Alert if sleep is very low
        return nil if sleep_hours >= 6

        priority = sleep_hours < 5 ? SignalPriority::High : SignalPriority::Medium

        DataSignal.new(
          id: "sleep_#{Date.today.iso8601}",
          change_type: ChangeType::SleepData,
          priority: priority,
          title: "Low sleep: #{sleep_hours.round(1)}h",
          summary: "You only got #{sleep_hours.round(1)} hours of sleep. Consider recovery focus today.",
          data_path: "/health/#{Date.today.iso8601}/sleep",
          timestamp: Time.now,
          metadata: { 'sleep_hours' => sleep_hours }
        )
      end

      sig { params(recovery: T.nilable(T::Hash[Symbol, T.untyped]), date: Date).returns(T.nilable(DataSignal)) }
      def evaluate_recovery_signal(recovery, date)
        return nil unless recovery

        status = recovery[:status]
        return nil unless status

        # Only signal if recovery is poor
        return nil unless %w[poor very_poor].include?(status.to_s.downcase)

        DataSignal.new(
          id: "recovery_#{date.iso8601}",
          change_type: ChangeType::DailyMetrics,
          priority: SignalPriority::High,
          title: "Recovery: #{status}",
          summary: "Your body needs rest. Consider taking it easy today.",
          data_path: "/health/#{date.iso8601}/recovery",
          timestamp: Time.now,
          metadata: { 'status' => status }
        )
      end

      sig { params(trend: T.nilable(T::Hash[Symbol, T.untyped])).returns(T.nilable(DataSignal)) }
      def evaluate_vo2max_change(trend)
        return nil unless trend

        current = trend[:current]
        previous = trend[:previous]
        return nil unless current && previous

        change = current - previous
        return nil if change.abs < 1 # Only signal if change > 1 ml/kg/min

        direction = change > 0 ? 'improved' : 'declined'
        priority = change > 0 ? SignalPriority::Medium : SignalPriority::High

        DataSignal.new(
          id: "vo2max_#{Date.today.iso8601}",
          change_type: ChangeType::PerformanceUpdate,
          priority: priority,
          title: "VO2max #{direction}",
          summary: "Your VO2max #{direction} to #{current} ml/kg/min.",
          data_path: '/performance/vo2max',
          timestamp: Time.now,
          metadata: { 'current' => current, 'previous' => previous, 'change' => change }
        )
      end

      sig { params(status: T.nilable(T::Hash[Symbol, T.untyped])).returns(T.nilable(DataSignal)) }
      def evaluate_training_status(status)
        return nil unless status

        training_status = status[:status]
        return nil unless training_status

        # Alert on detraining or overreaching
        concerning = %w[detraining overreaching strained]
        return nil unless concerning.include?(training_status.to_s.downcase)

        DataSignal.new(
          id: "training_#{Date.today.iso8601}",
          change_type: ChangeType::PerformanceUpdate,
          priority: SignalPriority::High,
          title: "Training: #{training_status}",
          summary: "Your training status is #{training_status}. Adjust your training plan.",
          data_path: '/performance/training_status',
          timestamp: Time.now,
          metadata: { 'status' => training_status }
        )
      end
    end
  end
end
