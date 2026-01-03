# typed: strict
# frozen_string_literal: true

module Briefing
  # Builds context strings from 7-day Garmin data for editorial briefings
  # Focuses on patterns and trends rather than single-day snapshots
  class EditorialContextBuilder
    extend T::Sig

    sig do
      params(
        daily_health_7d: T::Array[T::Hash[Symbol, T.untyped]],
        sleep_trend: T.nilable(Garmin::SleepTrend),
        activities_7d: T::Array[Garmin::Activity],
        week_stats: T.nilable(Garmin::ActivityStats),
        performance_metrics: T.nilable(Garmin::PerformanceMetrics),
        vo2max_trend: T.nilable(Garmin::VO2MaxTrend),
        training_status: T.nilable(Garmin::TrainingStatusSummary),
        anomalies: T::Array[Anomaly]
      ).void
    end
    def initialize(
      daily_health_7d:,
      sleep_trend: nil,
      activities_7d: [],
      week_stats: nil,
      performance_metrics: nil,
      vo2max_trend: nil,
      training_status: nil,
      anomalies: []
    )
      @daily_health_7d = daily_health_7d
      @sleep_trend = sleep_trend
      @activities_7d = activities_7d
      @week_stats = week_stats
      @performance_metrics = performance_metrics
      @vo2max_trend = vo2max_trend
      @training_status = training_status
      @anomalies = anomalies
    end

    sig { returns(String) }
    def build_health_summary
      return 'No health data available.' if @daily_health_7d.empty?

      lines = []

      # Sleep pattern summary
      if @sleep_trend
        trend_str = @sleep_trend.trend_direction.to_s
        good_nights = @sleep_trend.consecutive_good_nights || 0
        avg_score = @sleep_trend.avg_sleep_score&.round || 'N/A'
        avg_hours = @sleep_trend.avg_sleep_hours&.round(1) || 'N/A'

        lines << "SLEEP (7-day): avg #{avg_score}/100, #{avg_hours}h/night, " \
                 "trend #{trend_str}, #{good_nights} consecutive good nights"
      end

      # HRV summary
      hrv_values = @daily_health_7d.filter_map { |d| d[:hrv_last_night] }
      if hrv_values.any?
        avg_hrv = (hrv_values.sum.to_f / hrv_values.size).round
        min_hrv = hrv_values.min
        max_hrv = hrv_values.max
        lines << "HRV (7-day): avg #{avg_hrv}ms, range #{min_hrv}-#{max_hrv}ms"
      end

      # Recovery pattern
      recovery_data = @daily_health_7d.filter_map do |d|
        next unless d[:body_battery_start] && d[:body_battery_end]

        { start: d[:body_battery_start], end: d[:body_battery_end] }
      end

      if recovery_data.any?
        positive_days = recovery_data.count { |r| r[:end] >= r[:start] }
        avg_end = (recovery_data.sum { |r| r[:end] }.to_f / recovery_data.size).round
        lines << "BODY BATTERY: #{positive_days}/#{recovery_data.size} days positive, avg end-of-day #{avg_end}"
      end

      # Stress pattern
      stress_values = @daily_health_7d.filter_map { |d| d[:avg_stress] }
      if stress_values.any?
        avg_stress = (stress_values.sum.to_f / stress_values.size).round
        lines << "STRESS (7-day avg): #{avg_stress}"
      end

      # Daily breakdown (last 3 days for recent context)
      lines << ''
      lines << 'Recent days:'
      @daily_health_7d.last(3).each do |day|
        parts = []
        parts << day[:date].to_s if day[:date]
        parts << "sleep #{day[:sleep_score]}/100" if day[:sleep_score]
        parts << "HRV #{day[:hrv_last_night]}ms" if day[:hrv_last_night]

        if day[:body_battery_start] && day[:body_battery_end]
          parts << "BB #{day[:body_battery_start]}→#{day[:body_battery_end]}"
        end

        parts << "stress #{day[:avg_stress]}" if day[:avg_stress]
        lines << "  #{parts.join(' | ')}" if parts.size > 1
      end

      lines.join("\n")
    end

    sig { returns(String) }
    def build_activity_summary
      return 'No activities recorded this week.' if @activities_7d.empty?

      lines = []

      # Week totals
      if @week_stats
        distance_km = (@week_stats.total_distance_m / 1000.0).round(1)
        duration = format_duration(@week_stats.total_duration_sec)
        count = @week_stats.activity_count

        lines << "WEEK TOTAL: #{distance_km}km, #{count} activities, #{duration}"

        if @week_stats.avg_pace_per_km
          pace = format_pace(@week_stats.avg_pace_per_km)
          lines << "Average pace: #{pace}/km"
        end
      end

      # Activity breakdown by type
      by_type = @activities_7d.group_by(&:activity_type)
      if by_type.size > 1
        lines << ''
        lines << 'By type:'
        by_type.each do |type, activities|
          total_dist = activities.sum { |a| a.distance_m || 0 } / 1000.0
          lines << "  #{type || 'Other'}: #{activities.size} sessions, #{total_dist.round(1)}km"
        end
      end

      # Recent activities with detail
      lines << ''
      lines << 'Recent activities:'
      @activities_7d.first(5).each do |activity|
        name = activity.activity_name || activity.activity_type || 'Activity'
        dist = activity.distance_m ? "#{(activity.distance_m / 1000.0).round(1)}km" : ''
        duration = activity.duration_sec ? format_duration(activity.duration_sec) : ''
        hr = activity.avg_hr ? "HR #{activity.avg_hr}" : ''

        parts = [name, dist, duration, hr].reject(&:empty?)
        lines << "  - #{parts.join(' | ')}"
      end

      lines.join("\n")
    end

    sig { returns(String) }
    def build_performance_summary
      return 'No performance data available.' unless @performance_metrics

      lines = []

      # VO2 Max with trend
      if @vo2max_trend
        current = @vo2max_trend.current
        direction = @vo2max_trend.direction
        change = @vo2max_trend.change_30d

        trend_str = case direction
                    when :improving then "↑#{change.abs.round(1)}"
                    when :declining then "↓#{change.abs.round(1)}"
                    else '→'
                    end

        lines << "VO2 MAX: #{current} ml/kg/min (#{trend_str} over 30 days)"
      elsif @performance_metrics.vo2max
        lines << "VO2 MAX: #{@performance_metrics.vo2max.round} ml/kg/min"
      end

      # Training status
      if @training_status
        lines << "TRAINING STATUS: #{@training_status.training_status}"

        if @training_status.training_readiness
          readiness_level = case @training_status.training_readiness
                            when 0..33 then 'LOW'
                            when 34..66 then 'MODERATE'
                            else 'HIGH'
                            end
          lines << "TRAINING READINESS: #{@training_status.training_readiness}/100 (#{readiness_level})"
        end
      end

      # Scores
      scores = []
      scores << "Endurance: #{@performance_metrics.endurance_score}" if @performance_metrics.endurance_score
      scores << "Hill: #{@performance_metrics.hill_score}" if @performance_metrics.hill_score
      lines << "SCORES: #{scores.join(', ')}" if scores.any?

      lines.join("\n")
    end

    sig { returns(String) }
    def build_anomalies_summary
      return 'No anomalies detected—data patterns are consistent.' if @anomalies.empty?

      lines = ['DETECTED PATTERNS:']

      @anomalies.each do |anomaly|
        severity_marker = case anomaly.severity
                          when AnomalySeverity::High then '[!]'
                          when AnomalySeverity::Medium then '[~]'
                          else '[.]'
                          end

        lines << "#{severity_marker} #{anomaly.headline}"
        lines << "    What: #{anomaly.detail}"
        lines << "    Implication: #{anomaly.implication}"
      end

      lines.join("\n")
    end

    sig { returns(T::Hash[Symbol, String]) }
    def build_all
      {
        health_summary: build_health_summary,
        activity_summary: build_activity_summary,
        performance_summary: build_performance_summary,
        detected_anomalies: build_anomalies_summary
      }
    end

    private

    sig { params(seconds: Integer).returns(String) }
    def format_duration(seconds)
      hours = seconds / 3600
      mins = (seconds % 3600) / 60

      if hours > 0
        "#{hours}h#{mins}m"
      else
        "#{mins}m"
      end
    end

    sig { params(seconds_per_km: Float).returns(String) }
    def format_pace(seconds_per_km)
      mins = (seconds_per_km / 60).to_i
      secs = (seconds_per_km % 60).to_i
      "#{mins}:#{secs.to_s.rjust(2, '0')}"
    end
  end
end
