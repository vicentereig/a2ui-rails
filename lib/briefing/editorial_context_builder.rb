# typed: strict
# frozen_string_literal: true

module Briefing
  # Builds narrative context from 7-day Garmin data for editorial briefings
  # Produces pre-interpreted prose, not raw numbers
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

    sig { returns(HealthNarrative) }
    def build_health_narrative
      HealthNarrative.new(
        pattern: determine_health_pattern,
        sleep_quality: interpret_sleep,
        recovery_state: interpret_recovery,
        stress_context: interpret_stress,
        notable_observation: find_notable_health_observation
      )
    end

    sig { returns(ActivityNarrative) }
    def build_activity_narrative
      ActivityNarrative.new(
        pattern: determine_training_pattern,
        volume_description: interpret_volume,
        intensity_description: interpret_intensity,
        consistency_description: interpret_consistency
      )
    end

    sig { returns(PerformanceNarrative) }
    def build_performance_narrative
      PerformanceNarrative.new(
        trajectory: determine_fitness_trajectory,
        aerobic_state: interpret_aerobic_fitness,
        training_readiness: interpret_readiness,
        outlook: interpret_outlook
      )
    end

    sig { returns(T::Array[DetectedPattern]) }
    def build_detected_patterns
      @anomalies.map do |anomaly|
        DetectedPattern.new(
          pattern_type: anomaly.anomaly_type,
          severity: anomaly.severity,
          narrative: anomaly.headline,
          implication: anomaly.implication
        )
      end
    end

    # Returns all narratives for the signature input
    sig { returns(T::Hash[Symbol, T.untyped]) }
    def build_all
      {
        health: build_health_narrative,
        activity: build_activity_narrative,
        performance: build_performance_narrative,
        detected_patterns: build_detected_patterns
      }
    end

    private

    # =============================================================================
    # Health Pattern Interpretation
    # =============================================================================

    sig { returns(HealthPattern) }
    def determine_health_pattern
      return HealthPattern::Inconsistent if @daily_health_7d.empty?

      avg_sleep = average_sleep_score
      hrv_trend = hrv_trend_direction
      recovery_ratio = positive_recovery_ratio

      if avg_sleep >= 80 && recovery_ratio >= 0.7
        HealthPattern::Excellent
      elsif avg_sleep >= 70 && hrv_trend == :improving
        HealthPattern::Recovering
      elsif avg_sleep < 60 || recovery_ratio < 0.4
        HealthPattern::Strained
      elsif hrv_variance_high?
        HealthPattern::Inconsistent
      elsif hrv_trend == :declining || sleep_trend_declining?
        HealthPattern::Declining
      else
        HealthPattern::Recovering
      end
    end

    sig { returns(String) }
    def interpret_sleep
      return 'No sleep data available this week.' unless @sleep_trend

      avg_score = @sleep_trend.avg_sleep_score || 0
      trend = @sleep_trend.trend_direction
      good_nights = @sleep_trend.consecutive_good_nights || 0

      quality = case avg_score
                when 85.. then 'consistently restorative'
                when 70..84 then 'generally adequate'
                when 50..69 then 'somewhat fragmented'
                else 'challenging and insufficient'
                end

      trend_phrase = case trend.to_s
                     when 'improving' then 'with nights getting progressively better'
                     when 'declining' then 'though showing signs of deterioration'
                     else 'holding steady'
                     end

      streak_phrase = if good_nights >= 5
                        'You have built up a solid streak of quality rest.'
                      elsif good_nights >= 3
                        'A few good nights in a row is helping your recovery.'
                      else
                        ''
                      end

      "Sleep has been #{quality} this week, #{trend_phrase}. #{streak_phrase}".strip
    end

    sig { returns(String) }
    def interpret_recovery
      hrv_values = @daily_health_7d.filter_map { |d| d[:hrv_last_night] }
      recovery_data = extract_recovery_data

      return 'No recovery data available.' if hrv_values.empty? && recovery_data.empty?

      parts = []

      if hrv_values.any?
        avg_hrv = hrv_values.sum.to_f / hrv_values.size
        variance = hrv_variance_high?

        # Handle variance first as it's important regardless of avg level
        hrv_state = if variance
                      if avg_hrv >= 50
                        'Your HRV is elevated but fluctuating day to day'
                      elsif avg_hrv >= 40
                        'Heart rate variability has been inconsistent this week'
                      else
                        'Your HRV has been fluctuating and running low'
                      end
                    elsif avg_hrv >= 50
                      'Your nervous system appears well-regulated'
                    elsif avg_hrv >= 40
                      'Heart rate variability is in a normal range'
                    else
                      'Recovery signals suggest your system is under strain'
                    end
        parts << hrv_state
      end

      if recovery_data.any?
        positive_days = recovery_data.count { |r| r[:end] >= r[:start] }
        ratio = positive_days.to_f / recovery_data.size

        battery_state = if ratio >= 0.8
                          'ending most days with energy reserves'
                        elsif ratio >= 0.5
                          'managing energy reasonably well'
                        else
                          'depleting energy faster than you are recovering it'
                        end
        parts << battery_state
      end

      parts.join(', ') + '.'
    end

    sig { returns(String) }
    def interpret_stress
      stress_values = @daily_health_7d.filter_map { |d| d[:avg_stress] }
      return 'No stress data available.' if stress_values.empty?

      avg_stress = stress_values.sum.to_f / stress_values.size

      case avg_stress
      when 0..25
        'Stress levels have been remarkably low, indicating excellent balance.'
      when 26..40
        'Daily stress has been manageable and within healthy bounds.'
      when 41..55
        'Stress is elevated but not overwhelming—worth monitoring.'
      when 56..70
        'You are carrying a noticeable stress load that may be affecting recovery.'
      else
        'Stress levels are high and likely impacting your overall wellbeing.'
      end
    end

    sig { returns(T.nilable(String)) }
    def find_notable_health_observation
      observations = []

      # Check for HRV spikes or drops - need at least 5 days to compare non-overlapping periods
      hrv_values = @daily_health_7d.filter_map { |d| d[:hrv_last_night] }
      if hrv_values.size >= 5
        # Split into first half and second half to avoid overlap
        midpoint = hrv_values.size / 2
        older = hrv_values.first(midpoint)
        recent = hrv_values.last(midpoint)

        older_avg = older.sum.to_f / older.size
        recent_avg = recent.sum.to_f / recent.size

        if recent_avg > older_avg * 1.2
          observations << 'HRV has notably improved in recent days'
        elsif recent_avg < older_avg * 0.8
          observations << 'HRV has dropped compared to earlier in the week'
        end
      end

      # Check for sleep pattern changes
      if @sleep_trend&.consecutive_good_nights && @sleep_trend.consecutive_good_nights >= 4
        observations << 'An extended streak of quality sleep is building momentum'
      end

      observations.first
    end

    # =============================================================================
    # Activity Pattern Interpretation
    # =============================================================================

    sig { returns(TrainingPattern) }
    def determine_training_pattern
      return TrainingPattern::Undertraining if @activities_7d.empty?

      activity_count = @activities_7d.size
      total_duration = @activities_7d.sum { |a| a.duration_sec || 0 }
      avg_hr_values = @activities_7d.filter_map(&:avg_hr)
      avg_intensity = avg_hr_values.any? ? avg_hr_values.sum.to_f / avg_hr_values.size : 0

      # Simple heuristics based on volume and intensity
      if activity_count >= 5 && avg_intensity > 150
        TrainingPattern::Building
      elsif activity_count >= 4 && avg_intensity > 140
        TrainingPattern::Maintaining
      elsif activity_count <= 2 && total_duration < 3600
        TrainingPattern::Undertraining
      elsif activity_count >= 6 || total_duration > 10 * 3600
        TrainingPattern::Overreaching
      elsif activity_count <= 3 && avg_intensity < 130
        TrainingPattern::Tapering
      else
        TrainingPattern::Maintaining
      end
    end

    sig { returns(String) }
    def interpret_volume
      return 'No training activity recorded this week.' if @activities_7d.empty?

      total_duration = @activities_7d.sum { |a| a.duration_sec || 0 }
      activity_count = @activities_7d.size

      volume_level = if total_duration > 8 * 3600
                       'high'
                     elsif total_duration > 4 * 3600
                       'moderate'
                     elsif total_duration > 2 * 3600
                       'light'
                     else
                       'minimal'
                     end

      frequency = case activity_count
                  when 0..1 then 'a single session'
                  when 2..3 then 'a few sessions'
                  when 4..5 then 'regular sessions'
                  else 'frequent sessions'
                  end

      "Training volume was #{volume_level} with #{frequency} throughout the week."
    end

    sig { returns(String) }
    def interpret_intensity
      avg_hr_values = @activities_7d.filter_map(&:avg_hr)
      return 'Intensity data not available.' if avg_hr_values.empty?

      avg_hr = avg_hr_values.sum.to_f / avg_hr_values.size

      intensity_desc = if avg_hr > 155
                         'predominantly at higher intensities, pushing cardiovascular limits'
                       elsif avg_hr > 140
                         'at moderate to vigorous intensities, building fitness effectively'
                       elsif avg_hr > 125
                         'mostly in an easy to moderate zone, good for aerobic base'
                       else
                         'at easy intensities, prioritizing recovery or base building'
                       end

      "Workouts were #{intensity_desc}."
    end

    sig { returns(String) }
    def interpret_consistency
      return 'No activities to assess consistency.' if @activities_7d.empty?

      # Check day distribution
      activity_days = @activities_7d.map { |a| a.start_time&.to_date }.compact.uniq
      days_with_activity = activity_days.size
      activity_count = @activities_7d.size

      if days_with_activity >= 5
        'Training has been well-distributed across the week with good rhythm.'
      elsif days_with_activity >= 3 && activity_count >= 4
        'You maintained a reasonable training cadence with some rest days.'
      elsif activity_count > days_with_activity * 1.5
        'Activities were clustered on fewer days, which may affect recovery.'
      elsif days_with_activity <= 2
        'Training was sporadic, limited to just a couple of days.'
      else
        'Training frequency was moderate.'
      end
    end

    # =============================================================================
    # Performance Pattern Interpretation
    # =============================================================================

    sig { returns(FitnessTrajectory) }
    def determine_fitness_trajectory
      return FitnessTrajectory::Stable unless @vo2max_trend

      case @vo2max_trend.direction
      when :improving then FitnessTrajectory::Improving
      when :declining then FitnessTrajectory::Declining
      when :stable then FitnessTrajectory::Stable
      else FitnessTrajectory::Plateauing
      end
    end

    sig { returns(String) }
    def interpret_aerobic_fitness
      if @vo2max_trend
        direction = @vo2max_trend.direction

        case direction
        when :improving
          'Aerobic fitness is on an upward trajectory, showing the benefits of recent training.'
        when :declining
          'Aerobic capacity has dipped recently, possibly due to reduced training or fatigue.'
        else
          'Aerobic fitness is holding steady at its current level.'
        end
      elsif @performance_metrics&.vo2max
        'Aerobic fitness data is available but trend information is limited.'
      else
        'No aerobic fitness data available.'
      end
    end

    sig { returns(String) }
    def interpret_readiness
      return 'Training readiness data not available.' unless @training_status&.training_readiness

      readiness = @training_status.training_readiness

      case readiness
      when 0..30
        'Your body is signaling a strong need for recovery before intense training.'
      when 31..50
        'Training readiness is below optimal—consider easier sessions.'
      when 51..70
        'You are reasonably prepared for moderate training loads.'
      when 71..85
        'Training readiness is good—your body can handle quality work.'
      else
        'You are primed for high-intensity or demanding training sessions.'
      end
    end

    sig { returns(String) }
    def interpret_outlook
      trajectory = determine_fitness_trajectory
      pattern = determine_training_pattern

      # Handle plateauing first (any training pattern)
      if trajectory == FitnessTrajectory::Plateauing
        return 'A plateau suggests your body has adapted—time to introduce new stimuli.'
      end

      case [trajectory, pattern]
      when [FitnessTrajectory::Improving, TrainingPattern::Building]
        'The current approach is working well—fitness is responding positively to training.'
      when [FitnessTrajectory::Improving, TrainingPattern::Maintaining]
        'Fitness continues to improve even at maintenance levels.'
      when [FitnessTrajectory::Declining, TrainingPattern::Overreaching]
        'Signs suggest backing off may help fitness recover and resume progress.'
      when [FitnessTrajectory::Declining, TrainingPattern::Undertraining]
        'More consistent training may help reverse the fitness decline.'
      when [FitnessTrajectory::Stable, TrainingPattern::Maintaining]
        'Fitness is stable—consider adding variety or progressive overload to advance.'
      else
        'Continue monitoring trends to inform training decisions.'
      end
    end

    # =============================================================================
    # Helper Methods
    # =============================================================================

    sig { returns(Float) }
    def average_sleep_score
      scores = @daily_health_7d.filter_map { |d| d[:sleep_score] }
      return 0.0 if scores.empty?

      scores.sum.to_f / scores.size
    end

    sig { returns(Symbol) }
    def hrv_trend_direction
      hrv_values = @daily_health_7d.filter_map { |d| d[:hrv_last_night] }
      return :stable if hrv_values.size < 4

      first_half = hrv_values.first(hrv_values.size / 2)
      second_half = hrv_values.last(hrv_values.size / 2)

      first_avg = first_half.sum.to_f / first_half.size
      second_avg = second_half.sum.to_f / second_half.size

      if second_avg > first_avg * 1.1
        :improving
      elsif second_avg < first_avg * 0.9
        :declining
      else
        :stable
      end
    end

    sig { returns(Float) }
    def positive_recovery_ratio
      recovery_data = extract_recovery_data
      return 0.5 if recovery_data.empty?

      positive = recovery_data.count { |r| r[:end] >= r[:start] }
      positive.to_f / recovery_data.size
    end

    sig { returns(T::Boolean) }
    def hrv_variance_high?
      hrv_values = @daily_health_7d.filter_map { |d| d[:hrv_last_night] }
      return false if hrv_values.size < 3

      avg = hrv_values.sum.to_f / hrv_values.size
      variance = hrv_values.map { |v| (v - avg).abs }.sum / hrv_values.size

      variance > 10 # More than 10ms average deviation
    end

    sig { returns(T::Boolean) }
    def sleep_trend_declining?
      @sleep_trend&.trend_direction.to_s == 'declining'
    end

    sig { returns(T::Array[T::Hash[Symbol, Integer]]) }
    def extract_recovery_data
      @daily_health_7d.filter_map do |d|
        next unless d[:body_battery_start] && d[:body_battery_end]

        { start: d[:body_battery_start], end: d[:body_battery_end] }
      end
    end
  end
end
