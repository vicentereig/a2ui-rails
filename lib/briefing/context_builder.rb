# typed: strict
# frozen_string_literal: true

module Briefing
  # Builds context strings from Garmin data for the LLM
  class ContextBuilder
    extend T::Sig

    sig do
      params(
        daily_health: T.nilable(Garmin::DailyHealth),
        sleep_trend: T.nilable(Garmin::SleepTrend),
        recovery_status: T.nilable(Garmin::RecoveryStatus),
        recent_activities: T.nilable(T::Array[Garmin::Activity]),
        week_stats: T.nilable(Garmin::ActivityStats),
        performance_metrics: T.nilable(Garmin::PerformanceMetrics),
        training_load: T.nilable(Garmin::TrainingLoadStatus),
        vo2max_trend: T.nilable(Garmin::VO2MaxTrend),
        race_predictions: T.nilable(Garmin::RacePredictions)
      ).void
    end
    def initialize(
      daily_health: nil,
      sleep_trend: nil,
      recovery_status: nil,
      recent_activities: nil,
      week_stats: nil,
      performance_metrics: nil,
      training_load: nil,
      vo2max_trend: nil,
      race_predictions: nil
    )
      @daily_health = daily_health
      @sleep_trend = sleep_trend
      @recovery_status = recovery_status
      @recent_activities = recent_activities || []
      @week_stats = week_stats
      @performance_metrics = performance_metrics
      @training_load = training_load
      @vo2max_trend = vo2max_trend
      @race_predictions = race_predictions
    end

    sig { returns(String) }
    def build_health_context
      return 'No data available.' unless @daily_health

      parts = []
      parts << build_sleep_section
      parts << build_hrv_section
      parts << build_recovery_section
      parts << build_steps_section

      parts.compact.join("\n")
    end

    sig { returns(String) }
    def build_activity_context
      return 'No recent activities recorded.' if @recent_activities.empty?

      parts = []
      parts << build_recent_activities_section
      parts << build_week_stats_section if @week_stats

      parts.compact.join("\n")
    end

    sig { returns(String) }
    def build_performance_context
      return 'No performance data available.' unless @performance_metrics

      parts = []
      parts << build_vo2max_section
      parts << build_training_status_section
      parts << build_race_predictions_section if @race_predictions

      parts.compact.join("\n")
    end

    sig { returns(T::Hash[Symbol, String]) }
    def build_all
      {
        health_context: build_health_context,
        activity_context: build_activity_context,
        performance_context: build_performance_context
      }
    end

    private

    sig { returns(T.nilable(String)) }
    def build_sleep_section
      return nil unless @daily_health

      sleep_hours = @daily_health.sleep_seconds ? (@daily_health.sleep_seconds / 3600.0).round(1) : nil
      sleep_score = @daily_health.sleep_score

      if sleep_hours
        score_str = sleep_score ? ", score #{sleep_score}/100" : ''
        trend_info = if @sleep_trend
                       " Trend: #{@sleep_trend.trend_direction}, #{@sleep_trend.consecutive_good_nights} good nights in a row."
                     else
                       ''
                     end
        "Sleep: #{sleep_hours} hours#{score_str}.#{trend_info}"
      else
        'Sleep: No data'
      end
    end

    sig { returns(T.nilable(String)) }
    def build_hrv_section
      return nil unless @daily_health

      hrv = @daily_health.hrv_last_night
      status = @daily_health.hrv_status

      if hrv
        "HRV: #{hrv}ms (#{status || 'unknown status'})"
      else
        nil
      end
    end

    sig { returns(T.nilable(String)) }
    def build_recovery_section
      return nil unless @daily_health

      resting_hr = @daily_health.resting_hr
      body_battery = @daily_health.body_battery_end
      stress = @daily_health.avg_stress
      readiness = @recovery_status&.readiness

      parts = []
      parts << "Resting HR: #{resting_hr} bpm" if resting_hr
      parts << "Body Battery: #{body_battery}" if body_battery
      parts << "Stress: #{stress}" if stress
      parts << "Readiness: #{readiness}" if readiness

      parts.empty? ? nil : "Recovery: #{parts.join(', ')}"
    end

    sig { returns(T.nilable(String)) }
    def build_steps_section
      return nil unless @daily_health

      steps = @daily_health.steps
      goal = @daily_health.step_goal

      if steps && goal
        formatted_steps = number_with_delimiter(steps)
        "Steps: #{formatted_steps} / #{number_with_delimiter(goal)} goal"
      elsif steps
        "Steps: #{number_with_delimiter(steps)}"
      else
        nil
      end
    end

    sig { returns(T.nilable(String)) }
    def build_recent_activities_section
      return nil if @recent_activities.empty?

      activities = @recent_activities.first(3).map do |activity|
        name = activity.activity_name || activity.activity_type || 'Activity'
        distance_km = activity.distance_m ? (activity.distance_m / 1000.0).round(1) : nil
        distance_str = distance_km ? "#{distance_km}km" : ''
        "#{name} (#{activity.activity_type}): #{distance_str}"
      end

      "Recent activities:\n" + activities.map { |a| "  - #{a}" }.join("\n")
    end

    sig { returns(T.nilable(String)) }
    def build_week_stats_section
      return nil unless @week_stats

      distance_km = (@week_stats.total_distance_m / 1000.0).round
      duration_min = (@week_stats.total_duration_sec / 60.0).round
      hours = duration_min / 60
      mins = duration_min % 60

      "Week total: #{distance_km}km, #{@week_stats.activity_count} activities, #{hours}:#{mins.to_s.rjust(2, '0')} hours"
    end

    sig { returns(T.nilable(String)) }
    def build_vo2max_section
      return nil unless @performance_metrics

      vo2max = @performance_metrics.vo2max
      return nil unless vo2max

      trend_info = if @vo2max_trend
                     "(#{@vo2max_trend.direction})"
                   else
                     ''
                   end

      "VO2 Max: #{vo2max.round} ml/kg/min #{trend_info}"
    end

    sig { returns(T.nilable(String)) }
    def build_training_status_section
      return nil unless @performance_metrics

      status = @performance_metrics.training_status
      readiness = @performance_metrics.training_readiness
      load_status = @training_load&.status || @performance_metrics.load_ratio_status

      parts = []
      parts << "Training Status: #{status}" if status
      parts << "Training Readiness: #{readiness}" if readiness
      parts << "Load: #{load_status}" if load_status

      parts.empty? ? nil : parts.join("\n")
    end

    sig { returns(T.nilable(String)) }
    def build_race_predictions_section
      return nil unless @race_predictions

      "Race Predictions: 5K: #{@race_predictions.five_k}, 10K: #{@race_predictions.ten_k}"
    end

    sig { params(number: Integer).returns(String) }
    def number_with_delimiter(number)
      number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    end
  end
end
